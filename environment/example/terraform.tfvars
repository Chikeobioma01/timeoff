#lables
region = "ca-central-1"
label_order = ["environment", "name"]
environment = "test"

availability_zones = ["ca-central-1a" , "ca-central-1b", "ca-central-1d"]

#networking
cidr_block = "10.30.0.0/16"
vpc_enabled = true
enable_flow_log = false


#ALB
enable = true
internal = false
load_balancer_type = "application"
enable_deletion_protection = false
idle_timeout = 600
https_enabled = true
http_enabled  = true
https_port    = 443
listener_type = "forward"
listener_certificate_arn = "arn:aws:acm:ap-south-1:341946156909:certificate/b24de325-d4ee-4f59-8d1e-c3d5c4deb5f0"
target_group_port = 80
