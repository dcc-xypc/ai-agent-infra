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
  type = string
}
variable "ilb_subnet_id" {
  type = string
}
variable "internal_lb_ip_address" {
  type = string
}
variable "auth_domain" {
  type = string
}
variable "tenant_domain" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "common_labels" {
  type = map(string)
}
variable "allowed_source_ip_ranges" {
  type        = list(string)
}