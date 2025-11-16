# EKS / Karpenter / Graviton 


## This repository deploys a new VPC, an EKS cluster, and Karpenter configured with two NodePools: one for x86 (amd64) and one for Graviton (arm64). It also includes examples showing how developers can schedule workloads on each architecture.

## 1 How to deploy cluster:

terraform init
terraform apply -auto-approve \
  -var="region=eu-central-1" \
  -var="cluster_name=starter-eks" \
  -var="cluster_version=1.31"

## 2 After creation:
Karpenter will scale nodes when pods require capacity.

aws eks update-kubeconfig --name starter-eks --region eu-central-1
kubectl get nodes -o wide

## 3 How a developer runs workloads on x86 or Graviton

See manifest files in examples dir. Developers only need to specify nodeSelector. 

### To create the workload run

kubectl apply -f examples/deploy-amd64.yaml
kubectl apply -f examples/deploy-arm64.yaml

