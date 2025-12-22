terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# 0. 调用 API 模块
module "project_apis" {
  source = "../../modules/api"
  project_id = var.project_id
}

# ---------------------------------------------
# 1. VPC モジュール
# ---------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project_id               = var.project_id
  region                   = var.region
  env_name                 = var.env_name
  vpc_network_name         = var.vpc_network_name
  subnet_cidr_app          = var.subnet_cidr_app
  subnet_cidr_ops          = var.subnet_cidr_ops
  connector_subnet_cidr    = var.connector_subnet_cidr
  enable_ops_nat           = var.enable_ops_nat
  reserved_ip_range_name   = var.reserved_ip_range_name
  depends_on = [
    module.project_apis 
  ]
}

# ---------------------------------------------
# 2. Cloud SQL モジュール
# ---------------------------------------------
module "cloudsql" {
  source = "../../modules/cloudsql"

  project_id           = var.project_id
  region               = var.region
  env_name             = var.env_name
  db_tier_config       = var.db_tier_config
  pg_admin_password    = var.pg_admin_password
  ai_agent_db_name     = var.ai_agent_db_name
  keycloak_db_name     = var.keycloak_db_name
  ai_agent_db_user     = var.ai_agent_db_user
  keycloak_db_user     = var.keycloak_db_user
  ai_agent_db_password = var.ai_agent_db_password
  keycloak_db_password = var.keycloak_db_password
  private_network_link = module.vpc.network_self_link 
  depends_on = [
    module.vpc
  ]
}

# ---------------------------------------------
# 2. Compute Engine モジュール(ops)
# ---------------------------------------------
module "ops" {
  source        = "../../modules/ops"
  project_id    = var.project_id
  region        = var.region
  env_name      = var.env_name
  vpc_id        = module.vpc.vpc_id
  ops_subnet_id = module.vpc.ops_subnet_id
  depends_on = [
    module.cloudsql 
  ]
}

# ---------------------------------------------
# 3. Cloud Run モジュール
# ---------------------------------------------
module "cloudrun" {
  source = "../../modules/cloudrun"

  project_id               = var.project_id
  region                   = var.region
  env_name                 = var.env_name
  external_cloudrun_sa_email = var.external_cloudrun_sa_email
  default_placeholder_image = var.default_placeholder_image
  connector_id             = module.vpc.connector_id
  ai_agent_db_connection_name       = module.cloudsql.instance_connection_name
  auth_domain           = var.auth_domain
  keycloak_db_connection_name       = module.cloudsql.instance_connection_name 
  ai_agent_db_name         = var.ai_agent_db_name
  ai_agent_db_user         = var.ai_agent_db_user
  ai_agent_db_password     = var.ai_agent_db_password
  keycloak_db_name         = var.keycloak_db_name
  keycloak_db_user         = var.keycloak_db_user
  keycloak_db_password     = var.keycloak_db_password
  keycloak_admin_name      = var.keycloak_admin_name
  keycloak_admin_password  = var.keycloak_admin_password
  keycloak_external_url    = var.keycloak_external_url
  oauth2_proxy_image_gcr   = var.oauth2_proxy_image_gcr
  oauth2_proxy_client_id   = var.oauth2_proxy_client_id
  oauth2_proxy_client_secret = var.oauth2_proxy_client_secret
  oauth2_proxy_cookie_secret = var.oauth2_proxy_cookie_secret
  depends_on = [
    module.cloudsql 
  ]
}

# ---------------------------------------------
# 4. Load Balancer モジュール
# ---------------------------------------------
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  project_id            = var.project_id
  env_name              = var.env_name
  region                = var.region
  auth_domain           = var.auth_domain
  tenant_domain         = var.tenant_domain
  
  web_frontend_app_name = module.cloudrun.web_frontend_app_name
  oauth2_proxy_app_name = module.cloudrun.oauth2_proxy_app_name 
  auth_keycloak_app_name = module.cloudrun.auth_keycloak_app_name 

  depends_on = [
    module.vpc,
    module.cloudrun
  ]
}

# ---------------------------------------------
# 5. Cloud Build Trigger モジュール
# ---------------------------------------------
# module "ci_cd_trigger" {
#   source = "../../modules/cloudbuild_trigger"
#   
#   project_id        = var.project_id
#   env_name          = var.env_name
#   region                = var.region
  
#   github_repo_owner = var.github_repo_owner
#   github_repo_name  = var.github_repo_name
#   trigger_branch    = var.trigger_branch
#   depends_on = [
#     module.project_apis 
#   ]
# }
