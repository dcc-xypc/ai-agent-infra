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
variable "subnet_cidr_con" {
  type = string
}
variable "subnet_cidr_sql" {
  type = string
}
variable "subnet_cidr_psc" {
  type = string
}
variable "subnet_cidr_ops" {
  type = string
}
variable "subnet_cidr_lb_int" {
  type = string
}
variable "subnet_cidr_lb_int_proxy" {
  type = string
}
variable "enable_ops_nat" {
  type = bool
}
variable "resource_prefix" {
  type = string
}
variable "common_labels" {
  type = map(string)
}