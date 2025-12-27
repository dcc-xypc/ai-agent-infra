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
variable "vpc_id" {
  description = "VPC 网络的 ID"
  type        = string
}
variable "app_subnet_id" {
  description = "应用子网的 ID (用于 Internal ALB 分配 IP)"
  type        = string
}
variable "internal_lb_ip_address" {
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
variable "setup_keycloak_resources" {
  type = bool
}
