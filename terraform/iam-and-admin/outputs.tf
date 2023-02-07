output "private-vm-sa-email" {
  value = google_service_account.define_service_account["sa-private-vm"].email
}

output "gke-sa-email" {
  value = google_service_account.define_service_account["sa-private-gke"].email
}