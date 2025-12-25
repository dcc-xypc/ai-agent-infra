variable "project_id" {
  type = string
}
variable "project_number" {
  type = string
}
variable "region" {
  type = string
}
variable "env_name" {
  type = string
}
variable "connector_id" {
  type = string
}
variable "external_cloudrun_sa_email" {
  type = string
}
variable "default_placeholder_image" {
  type = string
}
variable "oauth2_proxy_image_gcr" {
  type = string
}
variable "oauth2_proxy_upstream" {
  type = string
}
variable "ai_agent_db_connection_name" {
  type = string
}
variable "ai_agent_db_name" {
  type = string
}
variable "ai_agent_db_user" {
  type = string
}
variable "ai_agent_db_password" {
  type = string
  sensitive = true
}
variable "keycloak_db_connection_name" {
  type = string
}
variable "keycloak_db_name" {
  type = string
}
variable "keycloak_db_user" {
  type = string
}
variable "keycloak_db_password" {
  type = string
  sensitive = true
}
variable "keycloak_admin_name" {
  type = string
}
variable "keycloak_admin_password" {
  type = string
  sensitive = true
}
variable "keycloak_external_url" {
  type = string
}
variable "auth_domain" {
  type = string
}
variable "tenant_domain" {
  type = string
}
variable "oauth2_proxy_client_id" {
  type = string
}
variable "oauth2_proxy_client_secret" {
  type = string
  sensitive = true
}
variable "oauth2_proxy_cookie_secret" {
  type = string
  sensitive = true
}
