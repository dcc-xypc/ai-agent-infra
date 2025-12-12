# -----------------------------------------------------------
# VPC モジュール: VPC、アプリケーションサブネット、コネクタ専用サブネット、ピアリングを作成
# -----------------------------------------------------------

# 1. VPC ネットワークを作成 (グローバルリソース)
resource "google_compute_network" "vpc_network" {
  name                    = "${var.vpc_network_name}-${var.env_name}"
  project                 = var.project_id
  auto_create_subnetworks = false 
}

# 2. アプリケーションサブネット
resource "google_compute_subnetwork" "app_subnet" {
  name          = "${var.vpc_network_name}-subnet-${var.env_name}"
  project       = var.project_id
  ip_cidr_range = var.subnet_cidr
  region        = var.region 
  network       = google_compute_network.vpc_network.self_link
}

# 3. VPC アクセス コネクタ専用サブネット
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "${var.vpc_network_name}-connector-${var.env_name}"
  project       = var.project_id
  ip_cidr_range = var.connector_subnet_cidr 
  region        = var.region 
  network       = google_compute_network.vpc_network.self_link
}


# 4. VPC アクセス コネクタ
resource "google_vpc_access_connector" "main_connector" {
  name          = "cloudrun-connector-${var.env_name}"
  project       = var.project_id
  region        = var.region 
  
  subnetwork    = google_compute_subnetwork.connector_subnet.self_link
  
  depends_on = [google_compute_subnetwork.connector_subnet]
}

# 5. IP範囲を予約 (Cloud SQLピアリング用)
resource "google_compute_global_address" "private_ip_range" {
  name          = var.reserved_ip_range_name
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 
  network       = google_compute_network.vpc_network.self_link
}

# 6. サービスネットワーク接続を作成 (VPC ピアリング)
resource "google_service_networking_connection" "vpc_peering_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_ip_range       = google_compute_global_address.private_ip_range.self_link
}
