variable "label_order" {}

variable "environment" {}

variable "cidr_block" {}


variable "vpc_enabled" {}

variable "enable_flow_log" {}

variable "availability_zones" {}


#alb
variable "enable" {}
variable "internal" {}
variable "load_balancer_type" {}
variable "enable_deletion_protection" {}
variable "idle_timeout" {}
variable "https_enabled" {}
variable "http_enabled" {}
variable "https_port" {}
variable "listener_type" {}
variable "listener_certificate_arn" {}
variable "target_group_port" {}