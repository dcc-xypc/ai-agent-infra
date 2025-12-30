variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "env_name" {
  type = string
}
variable "vpc_network_name" {
  type = string
}
variable "subnet_cidr_app" {
  type = string
}
variable "subnet_cidr_ops" {
  type = string
}
variable "connector_subnet_cidr" {
  type = string
}
variable "enable_ops_nat" {
  type = bool
}
variable "reserved_ip_range_name" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "common_labels" {
  type = map(string)
}