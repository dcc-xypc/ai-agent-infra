# -----------------------------------------------------------
# VPC モジュール: VPC、アプリケーションサブネット、コネクタ専用サブネット、ピアリングを作成
# -----------------------------------------------------------

# 1. VPC ネットワークを作成 (グローバルリソース)
resource "google_compute_network" "vpc_network" {
  name                    = "${var.vpc_network_name}-${var.env_name}"
  project                 = var.project_id
  auto_create_subnetworks = false 
}

resource "google_compute_route" "default_internet_route" {
  name             = "default-internet-gateway-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  project          = var.project_id
}

# 2. アプリケーションサブネット
resource "google_compute_subnetwork" "app_subnet" {
  name          = "${var.vpc_network_name}-subnet-${var.env_name}"
  project       = var.project_id
  ip_cidr_range = var.subnet_cidr_app
  region        = var.region 
  network       = google_compute_network.vpc_network.self_link
}

# 3. devops vm 専用サブネット
resource "google_compute_subnetwork" "ops_subnet" {
  name          = "sb-ops-${var.env_name}"
  project       = var.project_id
  ip_cidr_range = var.subnet_cidr_ops
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
  private_ip_google_access = true 
}

# 4. VPC アクセス コネクタ専用サブネット
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "${var.vpc_network_name}-connector-${var.env_name}"
  project       = var.project_id
  ip_cidr_range = var.connector_subnet_cidr 
  region        = var.region 
  network       = google_compute_network.vpc_network.self_link
}


# 5. VPC アクセス コネクタ
resource "google_vpc_access_connector" "main_connector" {
  name          = "cloudrun-connector-${var.env_name}"
  project       = var.project_id
  region        = var.region 
  
  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }
  depends_on = [google_compute_subnetwork.connector_subnet]
}

# 6. IP範囲を予約 (Cloud SQLピアリング用)
resource "google_compute_global_address" "private_ip_range" {
  name          = var.reserved_ip_range_name
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 
  network       = google_compute_network.vpc_network.self_link
}

# 7. サービスネットワーク接続を作成 (VPC ピアリング)
resource "google_service_networking_connection" "vpc_peering_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# -----------------------------------------------------------
# 8. Proxy-Only サブネット (Internal ALB 用)
# -----------------------------------------------------------
# Internal HTTP(S) Load Balancing には、リージョンごとに 1 つのプロキシ専用サブネットが必要です。
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "proxy-only-subnet-${var.env_name}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc_network.id
  
  # プロキシ専用サブネットの推奨設定
  ip_cidr_range = "10.129.0.0/26" # 既存の CIDR 範囲と重複しない値を指定してください
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_router" "router" {
  count = var.enable_ops_nat ? 1 : 0
  name    = "router-${var.env_name}"
  region  = var.region
  network = google_compute_network.vpc_network.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  count = var.enable_ops_nat ? 1 : 0
  name                               = "nat-${var.env_name}"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"

  # 关键修改：仅针对特定子网
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    # 这里引用你的 ops 子网 ID
    name                    = google_compute_subnetwork.ops_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
