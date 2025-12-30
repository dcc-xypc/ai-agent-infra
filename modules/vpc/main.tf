# -----------------------------------------------------------
# VPC モジュール: VPC、ILB用サブネット、Ops用サブネット、コネクタ、ピアリング
# -----------------------------------------------------------

# 1. VPC ネットワーク (※GCPの仕様により、VPC自体はlabels非対応)
resource "google_compute_network" "vpc_network" {
  name                    = "${var.resource_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_route" "default_internet_route" {
  name             = "${var.resource_prefix}-route-igw"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  project          = var.project_id

  labels         = var.common_labels 
}

# 2. Internal LB 専用サブネット
resource "google_compute_subnetwork" "ilb_subnet" {
  name          = "${var.resource_prefix}-sb-ilb"
  project       = var.project_id
  region        = var.region
  ip_cidr_range = var.subnet_cidr_app
  network       = google_compute_network.vpc_network.self_link
  
  labels        = var.common_labels
}

# 3. devops vm 専用サブネット
resource "google_compute_subnetwork" "ops_subnet" {
  name          = "${var.resource_prefix}-sb-ops"
  project       = var.project_id
  ip_cidr_range = var.subnet_cidr_ops
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
  private_ip_google_access = true

  labels        = var.common_labels
}

# 4. VPC アクセス コネクタ専用サブネット
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "${var.resource_prefix}-sb-con"
  project       = var.project_id
  ip_cidr_range = var.connector_subnet_cidr
  region        = var.region 
  network       = google_compute_network.vpc_network.self_link
  private_ip_google_access = true

  labels        = var.common_labels
}

# 5. VPC アクセス コネクタ
resource "google_vpc_access_connector" "main_connector" {
  name          = "${var.resource_prefix}-con"
  project       = var.project_id
  region        = var.region 
  
  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }
  labels        = var.common_labels

  depends_on = [google_compute_subnetwork.connector_subnet]
}

# 6. IP範囲を予約 (Cloud SQLピアリング用)
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.resource_prefix}-pip-sql-reserved"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 
  network       = google_compute_network.vpc_network.self_link
  
  labels        = var.common_labels
}

# 7. サービスネットワーク接続 (VPC ピアリング)
resource "google_service_networking_connection" "vpc_peering_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# 8. Proxy-Only サブネット (Internal ALB 用)
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "${var.resource_prefix}-sb-proxy"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.129.0.0/26"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"

  labels        = var.common_labels
}

# 9. Internal ALB 用の静的内部 IP アドレス
resource "google_compute_address" "internal_lb_static_ip" {
  name         = "${var.resource_prefix}-pip-lb-int"
  project      = var.project_id
  region       = var.region
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.ilb_subnet.id
  
  labels       = var.common_labels
}

# 10. Router
resource "google_compute_router" "router" {
  count   = var.enable_ops_nat ? 1 : 0
  name    = "${var.resource_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
  project = var.project_id

  labels  = var.common_labels
}

# 11. NAT
resource "google_compute_router_nat" "nat" {
  count                              = var.enable_ops_nat ? 1 : 0
  name                               = "${var.resource_prefix}-nat"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.ops_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  subnetwork {
    name                    = google_compute_subnetwork.connector_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}