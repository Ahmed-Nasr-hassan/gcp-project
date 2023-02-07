resource "google_service_account" "define_service_account" {
  for_each = var.service_accounts
  account_id   = each.key #"default-vm-sa"
  display_name = each.key #"sa-private-vm"
}
resource "google_project_iam_member" "role-binding" {
  for_each = var.service_accounts
  project = var.project_name #"ahmed-nasr-iti-demo"
  role    = each.value #"roles/container.admin"
  member  = "serviceAccount:${google_service_account.define_service_account[each.key].email}"
}

# resource "google_service_account" "vm-sa" {
#   account_id   = "default-vm-sa"
#   display_name = "sa-private-vm"
# }

# resource "google_project_iam_member" "cluster-admin" {
#   project = "ahmed-nasr-iti-demo"
#   role    = "roles/container.admin"
#   member  = "serviceAccount:${google_service_account.vm-sa.email}"
# }

# resource "google_service_account" "gke-sa" {
#   account_id   = "default-gke-sa"
#   display_name = "sa-gke"
# }

# resource "google_project_iam_member" "gke_sa_storage_object_viewer" {
#   project = "ahmed-nasr-iti-demo"
#   role = "roles/storage.objectViewer"
#   member = "serviceAccount:${google_service_account.gke-sa.email}"
# }