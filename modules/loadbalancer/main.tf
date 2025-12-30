# -----------------------------------------------------------
# Load Balancer モジュール: デュアルドメイン、HTTPS 及び自動リダイレクトをサポート
# -----------------------------------------------------------

# 1. グローバル静的外部 IP アドレスを予約
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.resource_prefix}-pip-lb-ext"
  project = var.project_id
  
  #lifecycle {
  #  prevent_destroy = true
  #}
}

# 2. Serverless NEG (ネットワークエンドポイントグループ)
resource "google_compute_region_network_endpoint_group" "frontend_neg" {
  name                  = "${var.resource_prefix}-neg-front"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.web_frontend_app_name
  }
}

resource "google_compute_region_network_endpoint_group" "proxy_neg" {
  name                  = "${var.resource_prefix}-neg-proxy"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.oauth2_proxy_app_name
  }
}

resource "google_compute_region_network_endpoint_group" "keycloak_neg" {
  name                  = "${var.resource_prefix}-neg-auth"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.auth_keycloak_app_name
  }
}

resource "google_compute_region_network_endpoint_group" "backend_neg" {
  name                  = "${var.resource_prefix}-neg-back"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.web_backend_app_name
  }
}

# 3. バックエンドサービス (Backend Services) 設定
resource "google_compute_backend_service" "frontend_backend" {
  name                  = "${var.resource_prefix}-bes-front"
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity      = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 300
  backend {
    group = google_compute_region_network_endpoint_group.frontend_neg.id
  }
  # 后端服务支持 labels
  # labels                = var.common_labels 
}

resource "google_compute_backend_service" "proxy_backend" {
  name                  = "${var.resource_prefix}-bes-proxy"
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
  name                  = "${var.resource_prefix}-bes-auth"
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity      = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 300
  backend {
    group = google_compute_region_network_endpoint_group.keycloak_neg.id
  }
}

# 4. Google マネージド SSL 証明書
resource "google_compute_managed_ssl_certificate" "default" {
  name    = "${var.resource_prefix}-cert"
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
  name            = "${var.resource_prefix}-um-main"
  project         = var.project_id
  default_service = google_compute_backend_service.frontend_backend.id

  host_rule {
    hosts        = [var.auth_domain]
    path_matcher = "keycloak-matcher"
  }

  host_rule {
    hosts        = [var.tenant_domain]
    path_matcher = "tenant-matcher"
  }

  path_matcher {
    name            = "keycloak-matcher"
    default_service = google_compute_backend_service.keycloak_backend.id
  }

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
  name    = "${var.resource_prefix}-um-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# 7. ターゲットプロキシ (Target Proxies)
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "${var.resource_prefix}-tp-https"
  project          = var.project_id
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_target_http_proxy" "http_redirect_proxy" {
  name    = "${var.resource_prefix}-tp-http"
  project = var.project_id
  url_map = google_compute_url_map.https_redirect.id
}

# 8. グローバルフォワーディングルール (Global Forwarding Rules)
resource "google_compute_global_forwarding_rule" "https_rule" {
  name                  = "${var.resource_prefix}-fr-https"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
  labels                = var.common_labels
}

resource "google_compute_global_forwarding_rule" "http_rule" {
  name                  = "${var.resource_prefix}-fr-http"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
  labels                = var.common_labels
}

# -----------------------------------------------------------
# 9. Internal Application Load Balancer (IALB) 設定
# -----------------------------------------------------------

resource "google_compute_region_backend_service" "internal_backend" {
  name                  = "${var.resource_prefix}-bes-int-back"
  project               = var.project_id
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.backend_neg.id
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_url_map" "internal_url_map" {
  name            = "${var.resource_prefix}-um-int"
  project         = var.project_id
  region          = var.region
  default_service = google_compute_region_backend_service.internal_backend.id
}

resource "google_compute_region_target_http_proxy" "internal_target_proxy" {
  name    = "${var.resource_prefix}-tp-int-http"
  project = var.project_id
  region  = var.region
  url_map = google_compute_region_url_map.internal_url_map.id
}

resource "google_compute_forwarding_rule" "internal_forwarding_rule" {
  name                  = "${var.resource_prefix}-fr-int"
  project               = var.project_id
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.internal_target_proxy.id
  
  network               = var.vpc_id
  subnetwork            = var.ilb_subnet_id
  ip_address            = var.internal_lb_ip_address
  
  labels                = var.common_labels
}