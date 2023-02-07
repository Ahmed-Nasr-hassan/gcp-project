module "iam-section" {
  source = "./iam-and-admin"
  project_name = "ahmed-nasr-iti-demo"
  service_accounts = {
      "sa-private-vm" = "roles/container.clusterAdmin",
      "sa-private-gke" = "roles/storage.objectViewer"
  }
}

module "vpc-network" {
  source = "./vpc-network"
  vpc_name = "vpc-network"
  subnets_data = {
    "management-subnet" = "10.0.0.0/24",
    "restricted-subnet" = "10.0.1.0/24"
  }
  subnets_region = "us-central1"
  is_private_ip_accessible = {
    "management-subnet" = false,
    "restricted-subnet" = true
  }
  nat_router_name = "nat-router"
  nat_gateway_name = "nat-gateway"
  nat_ip_allocation = "AUTO_ONLY"
  nat_subnet_ip_range = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  firewall_rule_name = "allow-incoming-ssh-from-iap"
  firewall_traffic_direction = "INGRESS"
  service_account_email_list = [module.iam-section.private-vm-sa-email]
  firewall_source_ranges_list = ["35.235.240.0/20"]
  firewall_protocol = "tcp"
  firewall_target_port_list = ["22"]
}

module "private-vm" {
  source = "./compute-engine"
  name = "my-private-vm"
  vm_type = "f1-micro"
  vm_zone = "us-central1-a"
  vm_image = "ubuntu-os-cloud/ubuntu-2004-lts"
  vm_subnet_self_link = module.vpc-network.management_subnet_self_link
  vm_service_account = module.iam-section.private-vm-sa-email
  vm_scopes = [ 
     "https://www.googleapis.com/auth/cloud-platform"
  ]

}

module "gke-cluster" {
  source = "./kubernates-engine"
  name = "private-gke-cluster"
  zone_name = "us-central1-a" 
  network_self_link = module.vpc-network.network_self_link
  subnet_self_link = module.vpc-network.restricted_subnet_self_link
  remove_default_node_pool = true
  authorized_network_cidr_range = "10.0.0.0/24"
  authorized_network_name = "management_subnet"
  enable_private_nodes = true
  enable_private_endpoint = true
  master_cidr_range = "172.16.0.0/28"
  enable_network_policy = true
  node_pool_name = "my-node-pool"
  node_count = 2
  is_preemptible = true
  node_vm_type = "g1-small"
  gke_service_account_email = module.iam-section.gke-sa-email
  oauth_scopes_list = [ 
     "https://www.googleapis.com/auth/cloud-platform"
  ]
}
