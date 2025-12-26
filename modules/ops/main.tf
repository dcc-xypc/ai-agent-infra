# 2. 获取当前项目默认的 Compute Engine 服务账号
data "google_compute_default_service_account" "default" {
  project = var.project_id
}
# 1. 运维维护专用 VM (Ops VM)
resource "google_compute_instance" "ops_vm" {
  name         = "ops-vm-${var.env_name}"
  machine_type = "e2-micro" # 维护用，最低配置即可
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = ["ops-admin"] # 用于防火墙规则匹配

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
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"] 
  }
  metadata = {
    enable-oslogin = "true"
    block-project-ssh-keys = "true"
  }
}

# 2. IAP 专用防火墙规则
# 仅允许 Google IAP 网段通过 22 端口访问带有 ops-admin 标签的机器
resource "google_compute_firewall" "allow_iap_ssh_ops" {
  name    = "fw-allow-iap-ssh-ops-${var.env_name}"
  network = var.vpc_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ops-admin"]
}
