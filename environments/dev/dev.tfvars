# 1. 基本設定
project_id     = "q14020-d-toyota-imap-dev"
project_number = "807696689691"
region         = "asia-northeast1"
env_name       = "dev"

# 2. データベースと認証
db_tier_config       = "db-g1-small"
pg_admin_password    = "pg_admin_password"
mysql_admin_password = "mysql_admin_password"
ai_agent_db_name     = "ai_agent"
ai_agent_db_user     = "ai_agent_user"
ai_agent_db_password = "ai_agent_db_password"
keycloak_db_name     = "keycloak"
keycloak_db_user     = "keycloak_user"
keycloak_db_password = "keycloak_db_password"

# 3. Cloud Run
default_placeholder_image  = "gcr.io/cloudrun/hello"
oauth2_proxy_image_gcr     = ""
keycloak_admin_name        = "kcadmin"
keycloak_admin_password    = "keycloak_admin_password"
oauth2_proxy_realm_name    = "ai-agent"
oauth2_proxy_client_id     = "ai-agent-client"
oauth2_proxy_client_secret = "2pky4BCjUqyZSJisDdDJhY5QyAhyPJKC"
oauth2_proxy_cookie_secret = "5IW9m4YHDWHf8AkuCzU_3b1c1Q9NoLlCJW0lKxgvgXE="

# 4. GitHub / CI/CD
github_repo_owner = "dcc-xypc"
github_repo_name  = "cloudrun-demo-keycloak"
trigger_branch    = "^main$"

# 5. ネットワーク
vpc_network_name         = "iac-custom-vpc"
subnet_cidr_psc          = "10.0.0.0/24"
subnet_cidr_con          = "10.0.1.0/24"
subnet_cidr_ops          = "10.0.2.0/24"
subnet_cidr_lb_int       = "10.0.3.0/24"
subnet_cidr_lb_int_proxy = "10.0.4.0/24"
subnet_cidr_sql          = "10.1.0.0/20"
allowed_source_ip_ranges = ["13.228.59.248/32", "13.230.154.173/32", "13.231.149.250/32", "218.69.11.110/32"]
enable_ops_nat           = true
tenant_domain            = "tenant1.ai-agent.tcic-cloud.com"
auth_domain              = "kc.ai-agent.tcic-cloud.com"

# 6. スペック (开发环境配置)
cloud_run_specs = {
  "web-frontend" = { cpu = "1", memory = "512Mi" }
  "web-backend"  = { cpu = "1", memory = "1Gi" }
  "auth-kc"      = { cpu = "1", memory = "2Gi" }
  "proxy"        = { cpu = "1", memory = "1Gi" }
}
