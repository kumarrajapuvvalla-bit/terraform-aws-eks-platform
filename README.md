# terraform-aws-eks-platform

> **Production-grade AWS EKS platform** built with Terraform — VPC, IAM/IRSA, ALB Ingress, Cluster Autoscaler, Prometheus & Grafana, and GitHub Actions CI.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws)](https://aws.amazon.com/eks/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/kumarrajapuvvalla-bit/terraform-aws-eks-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/kumarrajapuvvalla-bit/terraform-aws-eks-platform/actions/workflows/ci.yml)

---

## Architecture

```
+---------------------------------------------------------------------------+
|                         AWS Account / Region                              |
|                                                                           |
|  +---------------------------------------------------------------------+ |
|  |                       VPC  10.0.0.0/16                              | |
|  |                                                                     | |
|  |  +---------------+    +---------------+    +---------------+       | |
|  |  |   AZ  us-*a   |    |   AZ  us-*b   |    |   AZ  us-*c   |       | |
|  |  |               |    |               |    |               |       | |
|  |  | +-----------+ |    | +-----------+ |    | +-----------+ |       | |
|  |  | |  Public   | |    | |  Public   | |    | |  Public   | |       | |
|  |  | | 10.0.1/24 | |    | | 10.0.2/24 | |    | | 10.0.3/24 | |       | |
|  |  | | ALB + NAT | |    | | ALB + NAT | |    | | ALB + NAT | |       | |
|  |  | +-----+-----+ |    | +-----+-----+ |    | +-----+-----+ |       | |
|  |  |       | IGW   |    |       | IGW   |    |       | IGW   |       | |
|  |  | +-----v-----+ |    | +-----v-----+ |    | +-----v-----+ |       | |
|  |  | |  Private  | |    | |  Private  | |    | |  Private  | |       | |
|  |  | |10.0.11/24 | |    | |10.0.12/24 | |    | |10.0.13/24 | |       | |
|  |  | |   Nodes   | |    | |   Nodes   | |    | |   Nodes   | |       | |
|  |  | +-----------+ |    | +-----------+ |    | +-----------+ |       | |
|  |  +---------------+    +---------------+    +---------------+       | |
|  |                                                                     | |
|  |           +-------------------------------+                        | |
|  |           |      EKS Control Plane        |                        | |
|  |           |        (AWS Managed)          |                        | |
|  |           +---------------+---------------+                        | |
|  |                           |                                        | |
|  |   +-----------------------------------------------+               | |
|  |   |            EKS Managed Node Groups            |               | |
|  |   |  +-----------------+   +------------------+   |               | |
|  |   |  |   system-ng     |   |    worker-ng     |   |               | |
|  |   |  |   t3.medium     |   |    m5.xlarge     |   |               | |
|  |   |  |  min:1 max:3    |   |   min:2 max:10   |   |               | |
|  |   |  +-----------------+   +------------------+   |               | |
|  |   |                                               |               | |
|  |   |  Helm: ALB-Controller  Cluster-Autoscaler    |               | |
|  |   |         Prometheus     Grafana    EBS-CSI    |               | |
|  |   +-----------------------------------------------+               | |
|  +---------------------------------------------------------------------+ |
|                                                                           |
|  +-------------+  +--------------+  +-----------------------------------+|
|  |  S3 Bucket  |  |  DynamoDB    |  |       IAM / IRSA Roles            ||
|  |  (tfstate)  |  |  (tf-lock)   |  |  alb-ctrl | autoscaler | ebs-csi  ||
|  +-------------+  +--------------+  +-----------------------------------+|
+---------------------------------------------------------------------------+

Internet --> Route53 --> ALB (public) --> Ingress Controller --> Services
```

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Networking | AWS VPC + Subnets + NAT GW | Isolated network, public/private, 3 AZs |
| Compute | EKS Managed Node Groups | Self-healing workers with auto-scaling |
| Ingress | AWS ALB Ingress Controller | L7 load balancing, SSL termination |
| Autoscaling | Cluster Autoscaler | Node provisioning / de-provisioning |
| Identity | IRSA | Fine-grained pod-level AWS permissions |
| Observability | Prometheus + Grafana | Metrics, alerting, dashboards |
| State | S3 + DynamoDB | Remote state with distributed locking |
| CI/CD | GitHub Actions | fmt, validate, tfsec on every PR |

---

## Repository Structure

```
terraform-aws-eks-platform/
├── README.md
├── .gitignore
├── .terraform-version
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── helm/
│   ├── alb-ingress-controller.tf
│   ├── cluster-autoscaler.tf
│   └── monitoring.tf
└── .github/
    └── workflows/
        └── ci.yml
```

---

## Prerequisites

| Tool | Min Version |
|------|-------------|
| Terraform | >= 1.5.0 |
| AWS CLI | >= 2.x |
| kubectl | >= 1.27 |
| Helm | >= 3.12 |

---

## Quick Start

### 1. Bootstrap Remote State

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
BUCKET="tfstate-eks-platform-${ACCOUNT_ID}"

aws s3api create-bucket --bucket $BUCKET --region $REGION
aws s3api put-bucket-versioning --bucket $BUCKET \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $BUCKET \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region)
kubectl get nodes
```

### 5. Access Grafana

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Visit http://localhost:3000  (user: admin)
```

---

## Module Documentation

### VPC Module (`modules/vpc`)

Creates a production-ready VPC with 3 public and 3 private subnets across AZs, Internet Gateway, one NAT Gateway per AZ (HA), and Kubernetes-specific subnet tags for ALB and EKS node auto-discovery.

| Input | Type | Description |
|-------|------|-------------|
| `vpc_cidr` | string | VPC CIDR block |
| `availability_zones` | list(string) | Exactly 3 AZs |
| `public_subnet_cidrs` | list(string) | 3 public CIDRs |
| `private_subnet_cidrs` | list(string) | 3 private CIDRs |
| `cluster_name` | string | Used for subnet tagging |
| `single_nat_gateway` | bool | One NAT GW to reduce cost |

### IAM Module (`modules/iam`)

Provisions EKS cluster role, node group role, OIDC identity provider, and IRSA roles for ALB Controller, Cluster Autoscaler, and EBS CSI Driver with least-privilege policies.

```
Pod SA (k8s) --> OIDC Token --> AWS STS AssumeRoleWithWebIdentity --> IAM Role
```

### EKS Module (`modules/eks`)

Provisions the EKS cluster, managed node groups (system + worker), EKS add-ons (vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver), KMS secret encryption, and enforces IMDSv2 on all nodes.

| Node Group | Instance | Min | Max | Taint |
|-----------|---------|-----|-----|-------|
| system-ng | t3.medium | 1 | 3 | CriticalAddonsOnly=true:NoSchedule |
| worker-ng | m5.xlarge | 2 | 10 | — |

---

## Remote State

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "tfstate-eks-platform-<ACCOUNT_ID>"
    key            = "eks-platform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

State is AES-256 encrypted at rest, versioned, and protected against concurrent modifications via DynamoDB conditional writes.

---

## CI/CD Pipeline

```
PR Opened / Updated
        |
        v
+------------------------------------+
|  GitHub Actions: ci.yml            |
|                                    |
|  1. terraform fmt  -check          |
|  2. terraform init                 |
|  3. terraform validate             |
|  4. tfsec --no-colour              |
|  5. Post results comment on PR     |
+------------------------------------+
```

tfsec catches: public S3 buckets, open 0.0.0.0/0 SGs, missing EKS logging, unencrypted EBS, missing IMDSv2.

---

## Inputs & Outputs

### Root Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region |
| `environment` | string | — | dev / staging / prod |
| `cluster_name` | string | — | EKS cluster name (3–63 chars) |
| `cluster_version` | string | `1.29` | Kubernetes version |
| `vpc_cidr` | string | `10.0.0.0/16` | VPC CIDR |
| `node_instance_types` | list(string) | `["m5.xlarge"]` | Worker instance types |
| `node_min_size` | number | `1` | Minimum node count |
| `node_max_size` | number | `10` | Maximum node count |
| `node_desired_size` | number | `2` | Initial node count |
| `enable_monitoring` | bool | `true` | Deploy Prometheus/Grafana |
| `grafana_admin_password` | string | — | Min 12 chars |

### Root Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS API endpoint |
| `cluster_oidc_issuer_url` | OIDC URL for IRSA |
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs |
| `public_subnet_ids` | Public subnet IDs |
| `alb_controller_role_arn` | ALB controller IRSA role ARN |
| `cluster_autoscaler_role_arn` | Autoscaler IRSA role ARN |

---

## Security Considerations

- **Private API endpoint** — EKS API inaccessible from the internet by default
- **IRSA over node IAM** — pods get scoped credentials, not the node instance profile
- **KMS envelope encryption** — Kubernetes Secrets encrypted at rest
- **IMDSv2 enforced** — prevents SSRF-based metadata credential theft on all nodes
- **Private worker nodes** — no direct inbound internet access to compute
- **tfsec in CI** — every PR scanned for security misconfigurations before merge

---

## Contributing

1. Fork the repo and create a feature branch
2. Follow [Conventional Commits](https://www.conventionalcommits.org/)
3. Open a PR — CI runs automatically
4. Green CI + approval = merge

---

## License

MIT — see [LICENSE](LICENSE).
