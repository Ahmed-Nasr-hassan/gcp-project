output "network_self_link" {
  value = google_compute_network.vpc_network.self_link
}

output "restricted_subnet_self_link" {
  value = google_compute_subnetwork.subnetnetworks["restricted-subnet"].self_link
}

output "management_subnet_self_link" {
  value = google_compute_subnetwork.subnetnetworks["management-subnet"].self_link
}
