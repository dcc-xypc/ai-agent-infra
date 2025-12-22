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

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    apt-get update
    apt-get install -y postgresql-client redis-tools dnsutils telnet
  EOT
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

resource "null_resource" "install_psql" {
  # 确保在 VM 和防火墙规则都创建好之后再执行
  depends_on = [
    google_compute_instance.ops_vm,
    # 假设你的防火墙资源名是这个，请根据实际修改
    google_compute_firewall.allow_iap_ssh 
  ]

  triggers = {
    # 只有当 VM 的 ID 改变时才重新执行，或者你可以手动更改此值强制触发
    instance_id = google_compute_instance.ops_vm.id
  }

  # 1. 下载安装包（在运行 Terraform 的本地环境执行，如 Cloud Shell）
  provisioner "local-exec" {
    command = "apt-get download postgresql-client-15 postgresql-client-common libpq5"
  }

  # 2. 使用 SCP 将包传上去
  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute scp postgresql-client*.deb libpq5*.deb ${google_compute_instance.ops_vm.name}:/tmp/ \
        --tunnel-through-iap \
        --project=${var.project_id} \
        --zone=${google_compute_instance.ops_vm.zone} \
        --quiet
    EOT
  }

  # 3. 使用 SSH 执行安装命令
  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute ssh ${google_compute_instance.ops_vm.name} \
        --tunnel-through-iap \
        --project=${var.project_id} \
        --zone=${google_compute_instance.ops_vm.zone} \
        --quiet \
        --command="sudo dpkg -i /tmp/*.deb || sudo apt-get install -f -y"
    EOT
  }
}
