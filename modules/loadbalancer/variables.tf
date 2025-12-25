variable "project_id" {
  type = string
}
variable "env_name" {
  type = string
}
variable "region" {
  type = string
}
variable "web_frontend_app_name" {
  type = string
}
variable "web_backend_app_name" {
  type = string
}
variable "oauth2_proxy_app_name" {
  type = string
}
variable "auth_keycloak_app_name" {
  type = string
}
variable "auth_domain" {
  description = "Keycloak 认证服务的域名"
  type        = string
}
variable "tenant_domain" {
  description = "前端应用和 API 的域名"
  type        = string
}
variable "oauth2_proxy_client_id" {
  description = "Google OAuth2 Client ID for IAP"
  type        = string
}
variable "oauth2_proxy_client_secret" {
  description = "Google OAuth2 Client Secret for IAP"
  type        = string
}

