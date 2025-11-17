output "vpc_id" {
  description = "The ID of the created or existing VPC"
  value       = var.create_vpc ? module.vpc[0].vpc_id : null
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = var.create_vpc ? module.vpc[0].vpc_cidr_block : var.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.create_vpc ? module.vpc[0].public_subnets : []
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = var.create_vpc ? module.vpc[0].private_subnets : []
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (if created)"
  value       = var.create_vpc && var.enable_nat_gateway ? module.vpc[0].natgw_ids : []
}

output "availability_zones" {
  description = "List of availability zones used in the VPC"
  value       = var.azs
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = var.vpc_name
}
