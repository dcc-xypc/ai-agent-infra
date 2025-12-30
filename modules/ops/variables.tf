variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "env_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "ops_subnet_id" {
  type = string
}
variable "nat_id" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "common_labels" {
  type = map(string)
}