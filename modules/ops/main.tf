# 1. 运维维护专用 VM (Ops VM)
resource "google_compute_instance" "ops_vm" {
  name         = "ops-vm-${var.env_name}"
  machine_type = "e2-micro" # 维护用，最低配置即可
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = ["ops-admin"] # 用于防火墙规则匹配

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = var.ops_subnet_id
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

resource "null_resource" "remote_install" {

  triggers = {
    # 如果 VM 重建了，或者 NAT 重新开启了，就触发安装
    instance_id = google_compute_instance.ops_vm.id
    nat_id      = var.nat_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ -z "${var.nat_id}" ] || [ "${var.nat_id}" = "null" ]; then
        echo "NAT 未开启，跳过安装步骤。"
        exit 0
      fi
      echo "检测到 NAT 已开启，准备安装工具..."

      for i in {1..10}; do
        gcloud compute ssh ${google_compute_instance.ops_vm.name} \
          --tunnel-through-iap \
          --project=${var.project_id} \
          --zone=${google_compute_instance.ops_vm.zone} \
          --quiet \
          --command="sudo apt-get update && sudo apt-get install -y postgresql-client" && break || \
          (echo "等待 VM 或网络就绪... ($i/10)" && sleep 10)
      done
    EOT
  }
}
