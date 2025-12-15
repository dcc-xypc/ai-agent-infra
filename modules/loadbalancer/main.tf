# -----------------------------------------------------------
# Load Balancer モジュール: 外部アプリケーションロードバランサー (ALB) と NEG を設定
# -----------------------------------------------------------

# 1. 外部静的 IP アドレスの予約 (グローバル)
resource "google_compute_global_address" "lb_ip" {
  name    = "lb-ip-${var.env_name}"
  project = var.project_id
}

# 2. Serverless ネットワークエンドポイントグループ (NEG)
# Cloud Run サービスをロードバランサーのバックエンドとして登録
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "serverless-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  
  cloud_run {
    service = var.cloudrun_service_name
  }
}

# 3. バックエンドサービス
resource "google_compute_backend_service" "backend_service" {
  name          = "backend-service-${var.env_name}"
  project       = var.project_id
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 30
  enable_cdn    = false

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

# 4. URL マップ
resource "google_compute_url_map" "url_map" {
  name            = "url-map-${var.env_name}"
  project         = var.project_id
  default_service = google_compute_backend_service.backend_service.self_link
}

# 5. ターゲット HTTP プロキシ
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy-${var.env_name}"
  project = var.project_id
  url_map = google_compute_url_map.url_map.self_link
}

# 6. グローバル転送ルール (トラフィックの受付)
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "forwarding-rule-${var.env_name}"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  ip_address            = google_compute_global_address.lb_ip.self_link
}

# プロジェクト番号を取得するためのデータソース
data "google_project" "project" {
  project_id = var.project_id 
}
