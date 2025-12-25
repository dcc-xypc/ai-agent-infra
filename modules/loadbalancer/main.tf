# -----------------------------------------------------------
# Load Balancer 模块: 支持双域名、HTTPS 及 自动跳转
# -----------------------------------------------------------

# 1. 预约全局静态外部 IP 地址
resource "google_compute_global_address" "lb_ip" {
  name    = "lb-ip-${var.env_name}"
  project = var.project_id
  
  lifecycle {
    prevent_destroy = true
  }
}

# 2. Serverless NEG (网络端点组)
# 将 Cloud Run 服务映射到负载均衡器后端

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

# 3. 后端服务 (Backend Services) 设置

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

# 4. Google 托管的 SSL 证书 (自动申请与续期)
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

# 5. URL Map (核心路由逻辑)
resource "google_compute_url_map" "url_map" {
  name            = "url-map-${var.env_name}"
  project         = var.project_id
  default_service = google_compute_backend_service.frontend_backend.id

  # 域名 1: Keycloak 认证中心
  host_rule {
    hosts        = [var.auth_domain]
    path_matcher = "keycloak-matcher"
  }

  # 域名 2: 租户前端及安全代理 API
  host_rule {
    hosts        = [var.tenant_domain]
    path_matcher = "tenant-matcher"
  }

  # Keycloak 的路径分发
  path_matcher {
    name            = "keycloak-matcher"
    default_service = google_compute_backend_service.keycloak_backend.id
  }

  # Tenant 的路径分发 (Frontend vs OAuth2 Proxy)
  path_matcher {
    name            = "tenant-matcher"
    default_service = google_compute_backend_service.frontend_backend.id
    
    path_rule {
      paths   = ["/api/*", "/oauth2/*"]
      service = google_compute_backend_service.proxy_backend.id
    }
  }
}

# 6. HTTP 到 HTTPS 的自动跳转配置
resource "google_compute_url_map" "https_redirect" {
  name    = "https-redirect-${var.env_name}"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# 7. 目标代理 (Target Proxies)

# HTTPS 代理: 绑定 SSL 证书和 URL Map
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "https-proxy-${var.env_name}"
  project          = var.project_id
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# HTTP 代理: 仅用于执行重定向到 HTTPS
resource "google_compute_target_http_proxy" "http_redirect_proxy" {
  name    = "http-proxy-${var.env_name}"
  project = var.project_id
  url_map = google_compute_url_map.https_redirect.id
}

# 8. 全球转发规则 (Global Forwarding Rules)

# 监听 443 端口 (HTTPS)
resource "google_compute_global_forwarding_rule" "https_rule" {
  name                  = "forwarding-rule-https-${var.env_name}"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
}

# 监听 80 端口 (HTTP)
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
# 9. Internal Application Load Balancer (IALB) 配置
# -----------------------------------------------------------

# A. 内部后端服务 (指向业务 Cloud Run)
# 使用 INTERNAL_MANAGED 方案来确保流量在内网传输 [cite: 4, 5]
resource "google_compute_region_backend_service" "internal_backend" {
  name                  = "internal-backend-${var.env_name}"
  project               = var.project_id
  region                = var.region
  protocol              = "HTTP" [cite: 5, 6]
  load_balancing_scheme = "INTERNAL_MANAGED" # 必须是 INTERNAL_MANAGED [cite: 5]

  # 引用现有的 frontend_neg (业务 Cloud Run) 
  backend {
    group = google_compute_region_network_endpoint_group.frontend_neg.id
  }
}

# B. 内部 URL Map (定义内网路由规则)
resource "google_compute_region_url_map" "internal_url_map" {
  name            = "internal-url-map-${var.env_name}"
  project         = var.project_id
  region          = var.region
  default_service = google_compute_region_backend_service.internal_backend.id [cite: 8]
}

# C. 内部 HTTP 代理 (处理内网 HTTP 请求)
resource "google_compute_region_target_http_proxy" "internal_target_proxy" {
  name    = "internal-target-proxy-${var.env_name}"
  project = var.project_id
  region  = var.region
  url_map = google_compute_region_url_map.internal_url_map.id [cite: 10]
}

# D. 内部转发规则 (IALB 的私有入口)
# 这是 OAuth2-Proxy 将会访问的“内部终点”
resource "google_compute_forwarding_rule" "internal_forwarding_rule" {
  name                  = "internal-forwarding-rule-${var.env_name}"
  project               = var.project_id
  region                = var.region
  ip_protocol           = "TCP" [cite: 11]
  load_balancing_scheme = "INTERNAL_MANAGED" # 必须与后端服务一致 [cite: 11]
  port_range            = "80" [cite: 11]
  target                = google_compute_region_target_http_proxy.internal_target_proxy.id [cite: 11]
  
  # 关联已有的网络
  network               = var.vpc_id
  subnetwork            = var.app_subnet_id # 业务子网 ID
}

