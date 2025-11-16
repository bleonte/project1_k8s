# Karpenter IAM + (optionally) Helm via the EKS module's submodule
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.31"

  cluster_name = module.eks.cluster_name
  cluster_arn  = module.eks.cluster_arn

  # Create all the bits for IRSA + node role + instance profile
  create_iam_role                      = true
  enable_v1                            = true
  create_service_account               = true
  service_account_namespace            = "karpenter"
  service_account_name                 = "karpenter"

  # Install Helm chart directly from this module for simplicity
  create_helm_release                  = true
  helm_chart_version                   = "1.0.5"

  tags = var.tags
}

# Karpenter CRDs: EC2NodeClass + NodePools for amd64 and arm64
resource "kubernetes_namespace_v1" "karpenter" {
  metadata { name = "karpenter" }
}

locals {
  discovery_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

# Shared NodeClass (AL2023 + discovery tags)
resource "kubernetes_manifest" "ec2_nodeclass_default" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2023"
      subnetSelectorTerms = [
        { tags = local.discovery_tags }
      ]
      securityGroupSelectorTerms = [
        { tags = local.discovery_tags }
      ]
      role = module.karpenter.node_iam_role_name
      tags = local.discovery_tags
    }
  }
  depends_on = [module.karpenter]
}

# x86 NodePool
resource "kubernetes_manifest" "nodepool_amd64" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = { name = "np-amd64" }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["c6i","c7i","m6i","m7i","c6a","c7a","m6a","m7a"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot","on-demand"]
            }
          ]
          nodeClassRef = {
            kind = "EC2NodeClass"
            name = kubernetes_manifest.ec2_nodeclass_default.manifest.metadata.name
          }
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        consolidateAfter    = "30s"
      }
      limits = {
        cpu = "2000"
      }
    }
  }
  depends_on = [kubernetes_manifest.ec2_nodeclass_default]
}

# arm64 (Graviton) NodePool
resource "kubernetes_manifest" "nodepool_arm64" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = { name = "np-arm64" }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["c6g","c7g","m6g","m7g"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot","on-demand"]
            }
          ]
          nodeClassRef = {
            kind = "EC2NodeClass"
            name = kubernetes_manifest.ec2_nodeclass_default.manifest.metadata.name
          }
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        consolidateAfter    = "30s"
      }
      limits = {
        cpu = "2000"
      }
    }
  }
  depends_on = [kubernetes_manifest.ec2_nodeclass_default]
}
