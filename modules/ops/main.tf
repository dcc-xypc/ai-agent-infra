# -----------------------------------------------------------
# Ops モジュール: 運用保守専用 VM と IAP ファイアウォール
# -----------------------------------------------------------

# 1. 現在のプロジェクトのデフォルト Compute Engine サービスアカウントを取得
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# 2. 運用保守専用 VM (Ops VM)
resource "google_compute_instance" "ops_vm" {
  name         = "${var.resource_prefix}-vm-ops"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = ["ops-admin"]

  labels = var.common_labels

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y postgresql-client default-mysql-client
  EOT

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = var.ops_subnet_id
  }

  allow_stopping_for_update = true
  
  service_account {
    email  = data.google_compute_default_service_account.default.email [cite: 4]
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin         = "true"
    block-project-ssh-keys = "true"
  }
}

# 3. IAP 専用ファイアウォールルール
resource "google_compute_firewall" "allow_iap_ssh_ops" {
  name    = "${var.resource_prefix}-fw-iap-ssh"
  network = var.vpc_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Google IAP 的固定 IP 段 [cite: 5]
  source_ranges = ["35.235.240.0/20"] 
  target_tags   = ["ops-admin"]
}
