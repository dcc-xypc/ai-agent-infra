variable "project_id" { type = string }
variable "region" { type = string }
variable "env_name" { type = string }
variable "connector_id" { type = string }
variable "external_cloudrun_sa_email" { type = string }

variable "default_placeholder_image" { default = "gcr.io/cloudrun/container/hello" }
variable "oauth2_proxy_image" { default = "quay.io/oauth2-proxy/oauth2-proxy:v7.13.0-amd64"} 

variable "db_connection_name" {} 
variable "ai_agent_db_name" {}
variable "ai_agent_user_name" {}

variable "keycloak_db_connection_name" {}
variable "keycloak_db_name" {}
variable "keycloak_user_name" {}

variable "ai_agent_db_password" { sensitive = true } 
variable "keycloak_db_password" { sensitive = true }

variable "keycloak_admin_password" { sensitive = true }
variable "keycloak_external_url" {}

variable "oauth2_proxy_client_id" {}
variable "oauth2_proxy_client_secret" { sensitive = true }
variable "oauth2_proxy_cookie_secret" { sensitive = true }
