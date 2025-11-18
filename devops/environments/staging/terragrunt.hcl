# environments/staging/terragrunt.hcl

remote_state {
  backend = "s3"
  config = {
    bucket         = "prospera-stg-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "prospera-stg-terraform-locks"
  }
}

inputs = {
  aws_profile = "staging"
  region      = "ap-south-1"
}

# 🔧 Generate backend.tf automatically for Terraform to recognize backend
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
}
EOF
}
