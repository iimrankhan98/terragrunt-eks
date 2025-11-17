terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/eks/aws?version=21.8.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  cluster_name    = "prospera-stg-cluster"
  cluster_version = "1.33"
  region          = "ap-south-1"
  
  common_tags = {
    Environment = "stg"
    Project     = "prospera"
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }

  autoscale_tags = {
    "k8s.io/cluster-autoscaler/enabled"                  = "true"
    "k8s.io/cluster-autoscaler/${local.cluster_name}"    = "owned"
    "k8s.io/cluster-autoscaler/node-template/label/type" = "autoscale"
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-123456"
    private_subnet_ids = ["subnet-111111", "subnet-222222", "subnet-333333"]
    public_subnet_ids  = ["subnet-444444", "subnet-555555", "subnet-666666"]
  }
}

inputs = {
  name               = local.cluster_name
  kubernetes_version = local.cluster_version

  # VPC
  vpc_id                   = dependency.vpc.outputs.vpc_id
  subnet_ids               = dependency.vpc.outputs.private_subnet_ids
  control_plane_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # Cluster endpoint
  endpoint_public_access  = true
  endpoint_private_access = true

  # Authentication
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  manage_aws_auth_configmap               = true

  # IAM role additional policies
  iam_role_additional_policies = {
    AmazonEKSVPCResourceController = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  # Cluster SG rules
  security_group_additional_rules = {
    admin_access = {
      description = "Access to Kubernetes API from VPC"
      cidr_blocks = ["10.0.0.0/16"]
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
    }

    internet = {
      description = "Allow cluster egress access to the Internet"
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
    }
  }

  # Service CIDR
  service_ipv4_cidr = "172.20.0.0/16"

  # Logging
  enabled_cluster_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30

  # Timeouts
  timeouts = {
    create = "30m"
    delete = "15m"
    update = "60m"
  }

  # IRSA
  enable_irsa = true

  # Tags
  tags = local.common_tags

  # Add-ons
  addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }

    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"

      # IAM role for VPC CNI ADD-ON
      addon_role_arn = "arn:aws:iam::074643188723:role/eks-addon-manager-role"
    }

    eks-pod-identity-agent = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Node Security Group Tags
  node_security_group_tags = {
    Name = "${local.cluster_name}-node-sg"
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    system_base = {
      name           = "system-base"

      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.medium"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      capacity_type = "ON_DEMAND"

      subnet_ids = dependency.vpc.outputs.private_subnet_ids

      ebs_optimized = true
      key_name      = "prospera-eks-key"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        Name        = "system-base"
        Role        = "system-base"
        Environment = "stg"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                flags:
                - --node-labels=node.kubernetes.io/role=system-base
          EOT
        }
      ]

      instance_refresh = {}

      tags = merge(
        local.common_tags,
        local.autoscale_tags,
        {
          NodeGroup = "system-base"
        }
      )
    }
  }
}
