resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name #"vpc-network"
  auto_create_subnetworks = var.auto_create_subnets # false
}

resource "google_compute_subnetwork" "subnetnetworks" {
  for_each      = var.subnets_data
  name          = each.key
  ip_cidr_range = each.value
  region        = var.subnets_region
  network       = google_compute_network.vpc_network.id
  private_ip_google_access = var.is_private_ip_accessible[each.key]
}


# resource "google_compute_subnetwork" "management-subnet" {
#   name          = "management-subnet"
#   ip_cidr_range = "10.0.0.0/24"
#   region        = "us-central1"
#   network       = google_compute_network.vpc_network.id
# }

# resource "google_compute_subnetwork" "restricted-subnet" {
#   name          = "restricted-subnet"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = "us-central1"
#   network       = google_compute_network.vpc_network.id
#   private_ip_google_access = true
# }

resource "google_compute_router" "nat-router" {
  name    = var.nat_router_name #"nat-router"
  region  = var.subnets_region
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_gateway_name #"nat-gateway"
  router                             = google_compute_router.nat-router.name
  region                             = google_compute_router.nat-router.region
  nat_ip_allocate_option             = var.nat_ip_allocation # "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = var.nat_subnet_ip_range #"ALL_SUBNETWORKS_ALL_IP_RANGES"

#   log_config {
#     enable = true
#     filter = "ERRORS_ONLY"
#   }
}

resource "google_compute_firewall" "allow_firewall_rule" {
    name        = var.firewall_rule_name #"allow-incoming-ssh-from-iap"
    network     = google_compute_network.vpc_network.name
    direction = var.firewall_traffic_direction #"INGRESS"
    target_service_accounts = var.service_account_email_list  #[google_service_account.vm-sa.email]
    source_ranges = var.firewall_source_ranges_list # ["35.235.240.0/20"]
    allow {
        protocol = var.firewall_protocol #"tcp"
        ports    = var.firewall_target_port_list #["22"]  
    }
}

# resource "google_compute_firewall" "allow_internal_subnet_connection" {
#   name = "allow-internal-subnet-connection"
#   network = google_compute_network.vpc_network.name
#   direction = "INGRESS"
#   allow {
#     protocol = "all"
#   }
#   source_ranges = ["10.0.0.0/24"]
# }