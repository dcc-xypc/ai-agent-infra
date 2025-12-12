terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
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
  subnet_cidr              = var.subnet_cidr
  connector_subnet_cidr    = var.connector_subnet_cidr
  reserved_ip_range_name   = var.reserved_ip_range_name
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
  private_network_link = module.vpc.network_self_link 
}

# ---------------------------------------------
# 3. Cloud Run モジュール
# ---------------------------------------------
module "cloudrun" {
  source = "../../modules/cloudrun"

  project_id               = var.project_id
  region                   = var.region
  env_name                 = var.env_name
  connector_id             = module.vpc.connector_id
  db_connection_name       = module.cloudsql.instance_connection_name 
}

# ---------------------------------------------
# 4. Load Balancer モジュール
# ---------------------------------------------
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  project_id            = var.project_id
  env_name              = var.env_name
  region                = var.region
  
  cloudrun_service_name = module.cloudrun.service_name 
}

# ---------------------------------------------
# 5. Cloud Build Trigger モジュール
# ---------------------------------------------
module "ci_cd_trigger" {
  source = "../../modules/cloudbuild_trigger"
  
  project_id        = var.project_id
  env_name          = var.env_name
  region                = var.region
  
  github_repo_owner = var.github_repo_owner
  github_repo_name  = var.github_repo_name
  trigger_branch    = var.trigger_branch
}
