resource "google_container_cluster" "private-cluster" {
  name     = var.name #"private-gke-cluster"
  location = var.zone_name #"us-central1-a" 
  network = var.network_self_link # google_compute_network.vpc_network.self_link
  subnetwork = var.subnet_self_link #google_compute_subnetwork.restricted-subnet.self_link
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = var.remove_default_node_pool #true
  initial_node_count       = var.initial_node_count # 1
  master_authorized_networks_config {
    cidr_blocks {
        cidr_block = var.authorized_network_cidr_range # "10.0.0.0/24"
        display_name = var.authorized_network_name # "management_subnet"
    }
  }

  private_cluster_config {
    enable_private_nodes = var.enable_private_nodes # true
    enable_private_endpoint = var.enable_private_endpoint # true
    master_ipv4_cidr_block = var.master_cidr_range # "172.16.0.0/28"
  }

  network_policy {
    enabled = var.enable_network_policy # true
  }

  ip_allocation_policy {
  }


}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = var.node_pool_name #"my-node-pool"
  location   = var.zone_name #"us-central1-a"
  cluster    = google_container_cluster.private-cluster.name
  node_count = var.node_count # 2

  node_config {
    preemptible  = var.is_preemptible # true
    machine_type = var.node_vm_type # "g1-small"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.gke_service_account_email # google_service_account.gke-sa.email
    oauth_scopes = var.oauth_scopes_list # [  
    #     "https://www.googleapis.com/auth/logging.write",
    #     "https://www.googleapis.com/auth/monitoring.write",
    #     "https://www.googleapis.com/auth/devstorage.read_write",
    #     "https://www.googleapis.com/auth/compute"
    # ]

  }
}