# -----------------------------------------------------------
# Load Balancer モジュール: デュアルドメイン、HTTPS 及び自動リダイレクトをサポート
# -----------------------------------------------------------

# 1. グローバル静的外部 IP アドレスを予約
resource "google_compute_global_address" "lb_ip" {
  name    = "lb-ip-${var.env_name}"
  project = var.project_id
  
  #lifecycle {
  #  prevent_destroy = true
  #}
}

# 2. Serverless NEG (ネットワークエンドポイントグループ)
# Cloud Run サービスをロードバランサーバックエンドにマッピング

resource "google_compute_region_network_endpoint_group" "frontend_neg" {
  name                  = "frontend-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.web_frontend_app_name
  }
}

resource "google_compute_region_network_endpoint_group" "proxy_neg" {
  name                  = "proxy-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.oauth2_proxy_app_name
  }
}

resource "google_compute_region_network_endpoint_group" "keycloak_neg" {
  name                  = "keycloak-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.auth_keycloak_app_name
  }
}
resource "google_compute_region_network_endpoint_group" "backend_neg" {
  name                  = "backend-neg-${var.env_name}"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.web_backend_app_name
  }
}

# 3. バックエンドサービス (Backend Services) 設定

resource "google_compute_backend_service" "frontend_backend" {
  name                  = "frontend-backend-${var.env_name}"
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity      = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 300
  backend {
    group = google_compute_region_network_endpoint_group.frontend_neg.id
  }
}

resource "google_compute_backend_service" "proxy_backend" {
  name                  = "proxy-backend-${var.env_name}"
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity      = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 300
  backend {
    group = google_compute_region_network_endpoint_group.proxy_neg.id
  }
}

resource "google_compute_backend_service" "keycloak_backend" {
  name                  = "keycloak-backend-${var.env_name}"
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity      = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 300
  backend {
    group = google_compute_region_network_endpoint_group.keycloak_neg.id
  }
}

# 4. Google マネージド SSL 証明書 (自動申請と更新)
resource "google_compute_managed_ssl_certificate" "default" {
  name    = "managed-cert-${var.env_name}"
  project = var.project_id
  managed {
    domains = [
      var.auth_domain,
      var.tenant_domain
    ]
  }
}

# 5. URL Map (コアルーティングロジック)
resource "google_compute_url_map" "url_map" {
  name            = "url-map-${var.env_name}"
  project         = var.project_id
  default_service = google_compute_backend_service.frontend_backend.id

  # ドメイン 1: Keycloak 認証センター
  host_rule {
    hosts        = [var.auth_domain]
    path_matcher = "keycloak-matcher"
  }

  # ドメイン 2: テナントフロントエンドおよびセキュアプロキシ API
  host_rule {
    hosts        = [var.tenant_domain]
    path_matcher = "tenant-matcher"
  }

  # Keycloak のパス配布
  path_matcher {
    name            = "keycloak-matcher"
    default_service = google_compute_backend_service.keycloak_backend.id
  }

  # Tenant のパス配布 (Frontend vs OAuth2 Proxy)
  path_matcher {
    name            = "tenant-matcher"
    default_service = google_compute_backend_service.frontend_backend.id
    
    path_rule {
      paths   = ["/api/*", "/oauth2/*"]
      service = google_compute_backend_service.proxy_backend.id
    }
  }
}

# 6. HTTP から HTTPS への自動リダイレクト設定
resource "google_compute_url_map" "https_redirect" {
  name    = "https-redirect-${var.env_name}"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# 7. ターゲットプロキシ (Target Proxies)

# HTTPS プロキシ: SSL 証明書と URL Map をバインド
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "https-proxy-${var.env_name}"
  project          = var.project_id
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# HTTP プロキシ: HTTPS へのリダイレクト実行専用
resource "google_compute_target_http_proxy" "http_redirect_proxy" {
  name    = "http-proxy-${var.env_name}"
  project = var.project_id
  url_map = google_compute_url_map.https_redirect.id
}

# 8. グローバルフォワーディングルール (Global Forwarding Rules)

# 443 ポートをリッスン (HTTPS)
resource "google_compute_global_forwarding_rule" "https_rule" {
  name                  = "forwarding-rule-https-${var.env_name}"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
}

# 80 ポートをリッスン (HTTP)
resource "google_compute_global_forwarding_rule" "http_rule" {
  name                  = "forwarding-rule-http-${var.env_name}"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
}

# -----------------------------------------------------------
# 9. Internal Application Load Balancer (IALB) 設定
# -----------------------------------------------------------

# A. 内部バックエンドサービス (業務 Cloud Run を指す)
# INTERNAL_MANAGED スキームを使用してトラフィックがイントラネット内を流れるようにする
resource "google_compute_region_backend_service" "internal_backend" {
  name                  = "internal-backend-${var.env_name}"
  project               = var.project_id
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED" # 必须是 INTERNAL_MANAGED

  backend {
    group = google_compute_region_network_endpoint_group.backend_neg.id
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# B. 内部 URL Map (イントラネットルーティングルールを定義)
resource "google_compute_region_url_map" "internal_url_map" {
  name            = "internal-url-map-${var.env_name}"
  project         = var.project_id
  region          = var.region
  default_service = google_compute_region_backend_service.internal_backend.id
}

# C. 内部 HTTP プロキシ (イントラネット HTTP リクエストを処理)
resource "google_compute_region_target_http_proxy" "internal_target_proxy" {
  name    = "internal-target-proxy-${var.env_name}"
  project = var.project_id
  region  = var.region
  url_map = google_compute_region_url_map.internal_url_map.id
}

# D. 内部フォワーディングルール (IALB のプライベートエントリー)
# これは OAuth2-Proxy がアクセスする「内部エンドポイント」である
resource "google_compute_forwarding_rule" "internal_forwarding_rule" {
  name                  = "internal-forwarding-rule-${var.env_name}"
  project               = var.project_id
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED" # 必须与后端服务一致
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.internal_target_proxy.id
  
  # 关联已有的网络
  network               = var.vpc_id
  subnetwork            = var.app_subnet_id
  ip_address            = var.internal_lb_ip_address
}

