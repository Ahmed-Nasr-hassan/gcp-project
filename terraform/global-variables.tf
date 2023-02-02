provider "google" {
  project     = "ahmed-nasr-iti-demo"
}

resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "management-subnet" {
  name          = "management-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "restricted-subnet" {
  name          = "restricted-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-east1"
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "pods-cidr-range"
    ip_cidr_range = "192.168.1.0/24"
  }
}

# Create vpc peering

# to can reach gke from a vm its service account need 
# to have access to (Allow full access to all Cloud APIs)
# search for exact roles and apis required

resource "google_service_account" "vm-sa" {
  account_id   = "default-vm-sa"
  display_name = "sa-private-vm"
}

resource "google_compute_instance" "private-vm" {
  name         = "my-private-vm"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.management-subnet.name # google_compute_subnetwork.management-subnet.name
  }

  metadata_startup_script = "echo 'hi Nasr, How are you ?' > /test.txt"

  service_account {
    email  = google_service_account.vm-sa.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_router" "nat-router" {
  name    = "nat-router"
  region  = google_compute_subnetwork.management-subnet.region
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat-router.name
  region                             = google_compute_router.nat-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

## Allow incoming access to our instance via
## port 22, from the IAP servers
resource "google_compute_firewall" "inbound-ip-ssh" {
    name        = "allow-incoming-ssh-from-iap"
    network     = google_compute_network.vpc_network.name
    direction = "INGRESS"
    target_service_accounts = [google_service_account.vm-sa.email]
    allow {
        protocol = "tcp"
        ports    = ["22"]  
    }
    source_ranges = [
        "35.235.240.0/20"
    ]
}


# resource "google_service_account" "gke-sa" {
#   account_id   = "default-gke-sa"
#   display_name = "sa-gke"
# }

# resource "google_container_cluster" "private-cluster" {
#   name     = "private-gke-cluster"
#   location = "us-east1"

#   # We can't create a cluster with no node pool defined, but we want to only use
#   # separately managed node pools. So we create the smallest possible default
#   # node pool and immediately delete it.
#   remove_default_node_pool = true
#   initial_node_count       = 1
# }

# resource "google_container_node_pool" "primary_preemptible_nodes" {
#   name       = "my-node-pool"
#   location   = "us-east1"
#   cluster    = google_container_cluster.private-cluster.name
#   node_count = 2

#   node_config {
#     preemptible  = true
#     machine_type = "f1-micro"

#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     service_account = google_service_account.gke-sa.email
#     oauth_scopes    = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#   }
# }