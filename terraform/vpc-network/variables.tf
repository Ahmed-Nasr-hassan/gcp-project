variable "vpc_name" {
  
}

variable "auto_create_subnets" {
  default = false
}

variable "subnets_data" {
  type = map
}

variable "subnets_region" {
  
}

variable "is_private_ip_accessible" {
  type = map 
}

variable "nat_router_name" {
  
}

variable "nat_gateway_name" {
  
}

variable "nat_ip_allocation" {
  
}

variable "nat_subnet_ip_range" {
  
}

variable "firewall_rule_name" {
  
}

variable "firewall_traffic_direction" {
  
}

variable "service_account_email_list" {
  
}

variable "firewall_source_ranges_list" {
  type = list
}

variable "firewall_protocol" {
  
}

variable "firewall_target_port_list" {
  type = list
}