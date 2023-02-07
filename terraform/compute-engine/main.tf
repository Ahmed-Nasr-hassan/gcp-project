resource "google_compute_instance" "private-vm" {
  name         = var.name # "my-private-vm"
  machine_type = var.vm_type # "f1-micro"
  zone         = var.vm_zone #"us-central1-a"

  boot_disk {
    initialize_params {
      image = var.vm_image # "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = var.vm_subnet_self_link # google_compute_subnetwork.management-subnet.name 
  }

  service_account {
    email  = var.vm_service_account # google_service_account.vm-sa.email
    scopes = var.vm_scopes #["container.admin"]
  }
}