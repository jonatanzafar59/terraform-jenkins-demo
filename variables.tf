variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "live" {
  type    = number
  default = 1
}

variable "vnet_cidr_range" {
  type    = string
  default = "128.0.0.0/16"
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["128.0.0.0/24", "128.0.1.0/24"]
}

variable "subnet_names" {
  type    = list(string)
  default = ["web1", "database"]
}