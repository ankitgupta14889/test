variable "stack_name" {
  default = ""
}

variable "eks_cluster_name" {
  default = ""
}

variable "vpc_cidr" {
  type = string
  default = "192.168.0.0/20"
}

variable "private_subnets" {
  type = list
  default = ["192.168.4.0/22", "192.168.8.0/22", "192.168.12.0/22"]
}

variable "public_subnets" {
  type = list
  default = ["192.168.0.0/25", "192.168.0.128/25", "192.168.1.0/25"]
}
variable "database_subnets" {
  type = list
  default = ["192.168.2.128/25", "192.168.3.0/25", "192.168.3.128/25"]
}

variable "intra_subnets" {
  type = list
  default = ["192.168.1.128/26", "192.168.1.192/26", "192.168.2.0/26"]
}

variable "enable_single_nat" {
  type = bool
  default = false
}

variable "region" {
  type = string
}

variable "org" {
  type = string
}

variable "project" {
  type = string
}
variable "environment" {
  type = string
}