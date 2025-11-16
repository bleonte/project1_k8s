variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "starter-eks"
}

variable "cluster_version" {
  description = "EKS Kubernetes version (e.g. 1.31)"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {
    Project = "eks-starter"
    Owner   = "platform"
  }
}
