include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  create_vpc   = true
  vpc_name     = "prospera-stg-vpc"
  vpc_cidr     = "10.0.0.0/16"
  cluster_name = "prospera-stg-cluster"
  environment  = "stg"
  
  # Availability Zones
  azs = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  
  # Subnets
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # NAT Gateway - CRITICAL for EKS nodes in private subnets
  enable_nat_gateway      = true
  single_nat_gateway      = true  # Set to false for HA
  map_public_ip_on_launch = true
  
  # Optional: add extra tags
  tags = {
    Project = "prospera"
  }
}
