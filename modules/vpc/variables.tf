variable "project_id" {
  type        = string
  description = "GCPプロジェクトID"
}
variable "region" {
  type        = string
  description = "リージョン"
}
variable "env_name" {
  type        = string
  description = "環境名"
}
variable "vpc_network_name" {
  type        = string
  description = "VPCネットワーク名"
}
variable "subnet_cidr_app" {
  type        = string
  description = "アプリケーションサブネットのCIDR範囲"
}
variable "subnet_cidr_ops" {
  type        = string
  description = "OpsサブネットのCIDR範囲"
}
variable "connector_subnet_cidr" {
  type        = string
  description = "コネクタサブネットのCIDR範囲"
}
variable "enable_ops_nat" {
  type        = bool
  description = "Ops NATを有効にするかどうか"
}
variable "reserved_ip_range_name" {
  type        = string
  description = "予約IP範囲名"
}
