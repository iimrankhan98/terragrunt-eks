#modules/vpc/main.tf

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"
  
  count = var.create_vpc ? 1 : 0
  
  name = var.vpc_name
  cidr = var.vpc_cidr
  
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  
  # CRITICAL: Enable NAT Gateway for private subnets
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  map_public_ip_on_launch = var.map_public_ip_on_launch
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # ✅ Merge environment tags with custom tags
  tags = merge(
    {
      Environment = var.environment
      Name        = var.vpc_name
      Terraform   = "true"
      ManagedBy   = "Terragrunt"
    },
    var.tags
  )
  
  # ✅ Public subnet tags for EKS + ELB
  public_subnet_tags = merge(
    {
      Type = "public"
      "kubernetes.io/role/elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
  
  # ✅ Private subnet tags for EKS + internal ELB
  private_subnet_tags = merge(
    {
      Type = "private"
      "kubernetes.io/role/internal-elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}
