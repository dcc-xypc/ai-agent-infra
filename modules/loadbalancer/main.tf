# -----------------------------------------------------------
# Load Balancer モジュール: 3つの Cloud Run サービスへのルーティング設定
# -----------------------------------------------------------

# 1. 外部静的 IP アドレスの予約
resource "google_compute_global_address" "lb_ip" {
  name    = "lb-ip-${var.env_name}"
  project = var.project_id
}

# 2. Serverless NEG (ネットワークエンドポイントグループ)
# 各 Cloud Run サービスに対して NEG を作成します

# 2.1 Frontend 用
resource "google_compute_region_network_endpoint_group" "frontend_neg" {
  name                  = "frontend-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.frontend_service_name
  }
}

# 2.2 OAuth2 Proxy 用
resource "google_compute_region_network_endpoint_group" "proxy_neg" {
  name                  = "proxy-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.proxy_service_name
  }
}

# 2.3 Keycloak 用
resource "google_compute_region_network_endpoint_group" "keycloak_neg" {
  name                  = "keycloak-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.keycloak_service_name
  }
}

# 3. バックエンドサービスの設定
# NEG をバックエンドとして登録します

# 3.1 Frontend バックエンド
resource "google_compute_backend_service" "frontend_backend" {
  name        = "frontend-backend-${var.env_name}"
  project     = var.project_id
  protocol    = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  backend {
    group = google_compute_region_network_endpoint_group.frontend_neg.id
  }
}

# 3.2 OAuth2 Proxy バックエンド (API へのアクセスを保護)
resource "google_compute_backend_service" "proxy_backend" {
  name        = "proxy-backend-${var.env_name}"
  project     = var.project_id
  protocol    = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  backend {
    group = google_compute_region_network_endpoint_group.proxy_neg.id
  }
}

# 3.3 Keycloak バックエンド
resource "google_compute_backend_service" "keycloak_backend" {
  name        = "keycloak-backend-${var.env_name}"
  project     = var.project_id
  protocol    = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  backend {
    group = google_compute_region_network_endpoint_group.keycloak_neg.id
  }
}

# 4. URL マップ (パスベースルーティングの要)
resource "google_compute_url_map" "url_map" {
  name            = "url-map-${var.env_name}"
  project         = var.project_id
  
  # デフォルトは Frontend に送る
  default_service = google_compute_backend_service.frontend_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.frontend_backend.self_link

    # Keycloak へのパスルーティング
    path_rule {
      paths   = ["/auth/*"]
      service = google_compute_backend_service.keycloak_backend.self_link
    }

    # API および OAuth2 認証エンドポイントは Proxy 経由
    path_rule {
      paths   = ["/api/*", "/oauth2/*"]
      service = google_compute_backend_service.proxy_backend.self_link
    }
  }
}

# 5. ターゲット HTTP プロキシ
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy-${var.env_name}"
  project = var.project_id
  url_map = google_compute_url_map.url_map.self_link
}

# 6. グローバル転送ルール
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "forwarding-rule-${var.env_name}"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  ip_address            = google_compute_global_address.lb_ip.address
}