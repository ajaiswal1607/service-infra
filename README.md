# Complete AWS EKS Infrastructure

A production-ready, enterprise-grade Terraform configuration for deploying a complete AWS EKS (Elastic Kubernetes Service) infrastructure on AWS. This infrastructure is designed to be highly available, secure, and scalable.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Detailed Deployment Guide](#detailed-deployment-guide)
- [Configuration](#configuration)
- [Components](#components)
- [Network Architecture](#network-architecture)
- [Security Features](#security-features)
- [GitHub OIDC Integration](#github-oidc-integration)
- [ECR Setup](#ecr-setup)
- [EKS Addons](#eks-addons)
- [Accessing the Cluster](#accessing-the-cluster)
- [Managing Node Groups](#managing-node-groups)
- [Monitoring and Logging](#monitoring-and-logging)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Overview

This project provides a complete, modular Terraform configuration for deploying a secure, highly available AWS EKS cluster with all essential components. It follows AWS best practices and includes:

- **Networking**: Multi-AZ VPC with public and private subnets, NAT gateways for high availability
- **Kubernetes**: EKS cluster with managed node groups
- **Container Registry**: ECR repository with automatic image scanning and lifecycle policies
- **Security**: KMS encryption for secrets, IAM roles with least privilege, GitHub OIDC integration
- **Monitoring**: CloudWatch logs for EKS control plane, log group retention policies
- **Infrastructure as Code**: Terraform remote state management with S3 and DynamoDB

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                             │
│                    (ap-south-1 region)                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  VPC (10.20.0.0/16)                                     │   │
│  │                                                         │   │
│  │  ┌──────────────────────┐   ┌──────────────────────┐   │   │
│  │  │  Public Subnets      │   │ Public Subnets       │   │   │
│  │  │  (AZ-1, AZ-2)        │   │ (AZ-1, AZ-2)         │   │   │
│  │  │                      │   │                      │   │   │
│  │  │  ┌────────────────┐  │   │  ┌────────────────┐  │   │   │
│  │  │  │ NAT Gateway 1  │  │   │  │ NAT Gateway 2  │  │   │   │
│  │  │  └────────────────┘  │   │  └────────────────┘  │   │   │
│  │  │                      │   │                      │   │   │
│  │  │  ┌────────────────┐  │   │  ┌────────────────┐  │   │   │
│  │  │  │  IGW Route     │  │   │  │  IGW Route     │  │   │   │
│  │  │  └────────────────┘  │   │  └────────────────┘  │   │   │
│  │  └──────────────────────┘   └──────────────────────┘   │   │
│  │                                                         │   │
│  │  ┌──────────────────────┐   ┌──────────────────────┐   │   │
│  │  │ Private Subnets      │   │ Private Subnets      │   │   │
│  │  │ (AZ-1, AZ-2)         │   │ (AZ-1, AZ-2)         │   │   │
│  │  │                      │   │                      │   │   │
│  │  │  ┌────────────────┐  │   │  ┌────────────────┐  │   │   │
│  │  │  │ EKS Nodes 1    │  │   │  │ EKS Nodes 2    │  │   │   │
│  │  │  │ (t3.large)     │  │   │  │ (t3.large)     │  │   │   │
│  │  │  └────────────────┘  │   │  └────────────────┘  │   │   │
│  │  │                      │   │                      │   │   │
│  │  │  ┌────────────────┐  │   │  ┌────────────────┐  │   │   │
│  │  │  │ NAT Route      │  │   │  │ NAT Route      │  │   │   │
│  │  │  └────────────────┘  │   │  └────────────────┘  │   │   │
│  │  └──────────────────────┘   └──────────────────────┘   │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │         EKS Control Plane (Managed)             │   │   │
│  │  │  - API Server                                  │   │   │
│  │  │  - etcd (KMS Encrypted)                        │   │   │
│  │  │  - Control plane logging to CloudWatch         │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ECR Repository                                         │   │
│  │  (enterprise-eks-dev with image scanning)              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  IAM Roles & Policies                                   │   │
│  │  - EKS Cluster Role                                    │   │
│  │  - EKS Node Role                                       │   │
│  │  - GitHub Application Role (OIDC)                      │   │
│  │  - GitHub Terraform Role (OIDC)                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Security & Encryption                                 │   │
│  │  - KMS key for EKS secrets encryption                  │   │
│  │  - CloudWatch Log Group (/aws/eks/.../cluster)        │   │
│  │  - 30-day log retention                                │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### Networking
- **Multi-AZ Deployment**: Subnets in 2 availability zones for high availability
- **Public Subnets**: For NAT gateways and load balancers
- **Private Subnets**: For EKS worker nodes (secure, outbound-only internet access via NAT)
- **NAT Gateways**: One per AZ for redundancy and egress traffic
- **Kubernetes-aware Tags**: Proper tagging for ELB and internal ELB subnet discovery

### Kubernetes
- **EKS Cluster**: Managed Kubernetes service (version 1.33)
- **Auto-Scaling Node Group**: Scales from 2 to 4 nodes automatically based on demand
- **EC2 Instance Types**: t3.large instances (configurable for production workloads)
- **Rolling Updates**: Controlled node updates with max_unavailable = 1

### Security
- **KMS Encryption**: All EKS secrets encrypted with customer-managed KMS key
- **Key Rotation**: Automatic KMS key rotation enabled
- **OIDC Provider**: GitHub Actions integration for CI/CD workflows
- **IAM Roles with Least Privilege**: Separate roles for cluster, nodes, and GitHub
- **Private Endpoints**: EKS control plane accessible from within the VPC
- **Public Access**: EKS API publicly accessible (can be restricted)

### Container Registry
- **ECR Repository**: Single shared repository for all services
- **Image Scanning**: Automatic vulnerability scanning on image push
- **Immutable Tags**: Prevents accidental image overwrites
- **Lifecycle Policies**: Automatically expires images beyond retention limit (100 images)
- **Encryption**: AES256 encryption for stored images

### CI/CD Integration
- **GitHub OIDC**: Secure credential-less access for GitHub Actions
- **Application Role**: Permissions for ECR push and EKS describe operations
- **Terraform Role**: Full infrastructure management permissions
- **Main Branch Restriction**: Credentials only valid for main branch deployments

### Monitoring & Logging
- **Control Plane Logs**: API, audit, authenticator, controller manager, and scheduler logs
- **CloudWatch Integration**: Automatic log group creation and management
- **Log Retention**: 30-day retention policy for cost optimization
- **Future Integration**: Ready for Prometheus, Grafana, or other monitoring tools

## Prerequisites

Before you begin, ensure you have the following:

### AWS Account Requirements
- AWS account with appropriate permissions (Administrator for initial setup)
- AWS CLI configured with credentials (`aws configure`)
- Permissions to create VPCs, EKS clusters, ECR repositories, IAM roles, KMS keys, and S3 buckets

### Local Machine Requirements
- **Terraform**: Version 1.9.0 or later (`terraform version`)
- **AWS CLI**: Latest version for AWS interactions
- **kubectl**: Kubernetes CLI for cluster management
- **AWS IAM Authenticator**: For EKS authentication (`aws-iam-authenticator`)
- **Git**: For version control and GitHub integration

### GitHub Requirements
- GitHub organization and repository for OIDC integration
- Repository must have Actions enabled
- You'll need GitHub repository owner permissions to set up OIDC

### AWS Service Quotas
- Verify you have sufficient quota for:
  - VPCs (default: 5 per region)
  - NAT Gateways (default: 5 per region)
  - EKS clusters (default: 10 per region)
  - EC2 instances (varies by instance type)

### Installation Commands

```bash
# Install Terraform (macOS with Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify Terraform installation
terraform version

# Install AWS CLI (macOS with Homebrew)
brew install awscli

# Install kubectl
brew install kubectl

# Install AWS IAM Authenticator
brew install aws-iam-authenticator

# Configure AWS credentials
aws configure
# Enter: AWS Access Key ID, AWS Secret Access Key, Default region, Default output format
```

## Directory Structure

```
service-infra/
├── README.md                                  # This file
│
├── bootstrap-state/                           # Phase 1: Terraform state backend setup
│   ├── main.tf                               # S3 bucket, DynamoDB table, OIDC provider, GitHub Terraform role
│   ├── variables.tf                          # Input variables for bootstrap
│   ├── outputs.tf                            # Outputs from bootstrap (useful references)
│   ├── provider.tf                           # AWS provider configuration
│   └── versions.tf                           # Terraform and provider version constraints
│
├── common/
│   └── terraform/                            # Phase 2: EKS infrastructure
│       ├── main.tf                           # (Optional) Main configuration entry point
│       ├── variables.tf                      # 57 input variables for infrastructure
│       ├── outputs.tf                        # EKS cluster, ECR, IAM role ARNs
│       ├── provider.tf                       # AWS and TLS provider setup
│       ├── versions.tf                       # Terraform 1.9+, AWS 6.52+, TLS 4.0+
│       ├── backend.tf                        # S3 remote state configuration
│       ├── terraform.tfvars                  # Actual values for variables (git-ignored)
│       │
│       ├── vpc.tf (106 lines)                # Virtual Private Cloud setup
│       │   ├── Public subnets (2 AZs)
│       │   ├── Private subnets (2 AZs)
│       │   ├── Internet Gateway
│       │   ├── NAT Gateways (2 for HA)
│       │   ├── Elastic IPs for NAT
│       │   └── Route tables and associations
│       │
│       ├── eks.tf (67 lines)                 # EKS cluster configuration
│       │   ├── CloudWatch log group for cluster logs
│       │   ├── KMS key for secret encryption
│       │   ├── EKS cluster resource
│       │   ├── Node group auto-scaling config
│       │   └── Cluster logging (5 log types)
│       │
│       ├── ecr.tf (81 lines)                 # Elastic Container Registry
│       │   ├── ECR repository with immutable tags
│       │   ├── Image scanning on push
│       │   ├── Lifecycle policy (keep 100 images)
│       │   ├── IAM policies for GitHub Actions
│       │   └── GitHub application role attachments
│       │
│       ├── iam.tf (97 lines)                 # Identity & Access Management
│       │   ├── EKS cluster IAM role
│       │   ├── EKS node IAM role with policies
│       │   ├── GitHub OIDC provider setup
│       │   ├── GitHub application role (main branch restricted)
│       │   └── GitHub Terraform role (admin access)
│       │
│       ├── addons.tf (35 lines)              # EKS Add-ons
│       │   ├── VPC CNI (networking)
│       │   ├── CoreDNS (DNS)
│       │   ├── Kube Proxy (service networking)
│       │   ├── EBS CSI Driver (persistent volumes)
│       │   └── Pod Identity Agent (pod IAM roles)
│       │
│       └── README.md                         # Terraform directory specific notes
│
└── environments/                              # Environment-specific configurations
    ├── dev/
    │   ├── README.md
    │   └── terraform.tfvars                  # Dev environment values
    ├── prod/
    │   ├── README.md
    │   └── terraform.tfvars                  # Prod environment values
    └── qa/
        ├── README.md
        └── terraform.tfvars                  # QA environment values
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd service-infra
```

### 2. Set Up AWS Credentials

```bash
aws configure
# Follow the prompts to enter your AWS credentials
```

### 3. Bootstrap Terraform State Backend

```bash
cd bootstrap-state

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Note the outputs (you'll need these in the next step)
# Save the S3 bucket name and DynamoDB table name
```

### 4. Configure EKS Infrastructure

```bash
cd ../common/terraform

# Copy the backend configuration template
cp backend.tf.example backend.tf

# Edit backend.tf with your S3 bucket and DynamoDB table names
vim backend.tf

# Copy terraform.tfvars template
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your configuration
vim terraform.tfvars

# Initialize Terraform with remote state
terraform init

# Review the plan
terraform plan

# Apply the configuration (this takes ~15-20 minutes)
terraform apply
```

### 5. Verify the Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name enterprise-eks-dev

# Test cluster access
kubectl get nodes
kubectl get pods -A
```

## Detailed Deployment Guide

### Step 1: Bootstrap State Management (10 minutes)

This step creates the S3 bucket and DynamoDB table needed for remote Terraform state.

```bash
cd bootstrap-state

# Initialize Terraform (downloads providers)
terraform init

# Validate the configuration
terraform validate

# See what will be created
terraform plan -out=tfplan

# Create the infrastructure
terraform apply tfplan

# Save the outputs
terraform output
```

**What gets created:**
- S3 bucket: `{project-name}-terraform-state`
- DynamoDB table: `{project-name}-terraform-lock`
- CloudWatch Log Group: `/aws/eks/{project-name}-{environment}/cluster`
- GitHub OIDC Provider: `token.actions.githubusercontent.com`

### Step 2: Configure EKS Infrastructure (5 minutes setup)

```bash
cd ../common/terraform

# Initialize Terraform
terraform init -upgrade

# Backup and customize configuration
cp terraform.tfvars terraform.tfvars.backup
cp backend.tf.example backend.tf

# Edit these files:
# 1. backend.tf - Use the S3 bucket and DynamoDB table from Step 1
# 2. terraform.tfvars - Customize for your environment
```

**Key variables to customize in terraform.tfvars:**

```hcl
aws_region      = "ap-south-1"        # AWS region
project_name    = "enterprise-eks"    # Project name
environment     = "dev"               # Environment (dev, qa, prod)

vpc_cidr         = "10.20.0.0/16"     # VPC CIDR block
az_count         = 2                  # Number of availability zones
eks_version      = "1.33"             # Kubernetes version

# Node group configuration
node_instance_types = ["t3.large"]   # EC2 instance types
node_min_size       = 2               # Minimum nodes
node_desired_size   = 2               # Desired nodes
node_max_size       = 4               # Maximum nodes (for auto-scaling)

# GitHub OIDC
github_org       = "your-org"        # GitHub organization
github_repo      = "your-repo"       # GitHub repository
```

### Step 3: Deploy EKS Infrastructure (15-20 minutes)

```bash
# Review the complete plan before applying
terraform plan -out=tfplan

# Display plan details
terraform show tfplan

# Apply the configuration
terraform apply tfplan

# This will create:
# - VPC with subnets, IGW, NAT gateways
# - EKS cluster and managed node group
# - ECR repository
# - IAM roles and OIDC provider
# - KMS key for encryption
# - CloudWatch log group

# Save outputs for reference
terraform output -json > outputs.json
```

### Step 4: Configure kubectl Access

```bash
# Update kubeconfig with EKS cluster credentials
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name enterprise-eks-dev

# Verify cluster access
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

## Configuration

### Terraform Variables Reference

All variables are defined in `common/terraform/variables.tf`. Here's a detailed breakdown:

#### AWS & Project Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `ap-south-1` | AWS region where resources are deployed |
| `project_name` | string | `anand-app` | Project name (used in resource naming) |
| `environment` | string | `dev` | Environment name (dev/qa/prod) |

#### Network Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_cidr` | string | `10.20.0.0/16` | CIDR block for VPC (65,536 IP addresses) |
| `az_count` | number | `2` | Number of availability zones (2 or 3) |

#### Kubernetes Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `eks_version` | string | `1.33` | Kubernetes version for EKS cluster |

#### Node Group Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `node_instance_types` | list(string) | `["t3.large"]` | EC2 instance types for nodes |
| `node_min_size` | number | `2` | Minimum nodes in auto-scaling group |
| `node_desired_size` | number | `2` | Initial/desired number of nodes |
| `node_max_size` | number | `4` | Maximum nodes in auto-scaling group |

#### GitHub OIDC Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `github_org` | string | (required) | GitHub organization name |
| `github_repo` | string | (required) | GitHub repository name |

### backend.tf Configuration

The `backend.tf` file configures remote state storage:

```hcl
terraform {
  backend "s3" {
    bucket         = "enterprise-eks-terraform-state"  # From bootstrap output
    key            = "terraform/eks.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "enterprise-eks-terraform-lock"   # From bootstrap output
  }
}
```

## Components

### 1. VPC & Networking (vpc.tf)

#### Subnets
- **Public Subnets**: 2 subnets (one per AZ) for NAT gateways and load balancers
  - CIDR: 10.20.0.0/20, 10.20.1.0/20 (4,096 IPs each)
  - Auto-assign public IPs enabled
  - Tagged for ELB discovery

- **Private Subnets**: 2 subnets (one per AZ) for EKS nodes
  - CIDR: 10.20.2.0/20, 10.20.3.0/20 (4,096 IPs each)
  - Tagged for internal ELB discovery

#### Internet Connectivity
- **Internet Gateway**: Provides ingress/egress for public subnets
- **NAT Gateways**: One per AZ in public subnets
  - Provides outbound-only internet access for private subnets
  - Ensures high availability (if one AZ fails, other NAT continues working)
- **Elastic IPs**: Dedicated IPs for each NAT gateway

#### Route Tables
- Public route table: 0.0.0.0/0 → Internet Gateway
- Private route tables (per AZ): 0.0.0.0/0 → NAT Gateway in same AZ

### 2. EKS Cluster (eks.tf)

#### Control Plane
- **Managed Service**: AWS manages the Kubernetes control plane
- **High Availability**: Automatically distributed across availability zones
- **Endpoints**: Both private and public access enabled
- **Logging**: 5 types of logs sent to CloudWatch

#### Logging Configuration
```
- api              : API server logs
- audit            : Audit logs for compliance
- authenticator    : Authentication and authorization logs
- controllerManager: Controller manager logs
- scheduler        : Scheduler logs
```

#### Encryption
- **KMS Key**: Customer-managed key for EKS secret encryption
- **Key Rotation**: Automatic annual rotation enabled
- **Deletion Window**: 7-day grace period before permanent deletion

#### Node Group
- **Auto Scaling**: Configured to scale from 2 to 4 nodes
- **Rolling Updates**: Max 1 node unavailable during updates
- **Instance Types**: Configurable, defaults to t3.large
- **Networking**: Nodes deployed in private subnets only

### 3. ECR Repository (ecr.tf)

#### Repository Configuration
- **Name**: `{project-name}-{environment}` (e.g., `enterprise-eks-dev`)
- **Image Tag Mutability**: IMMUTABLE (tags cannot be overwritten)
- **Scanning**: Automatic vulnerability scanning on push

#### Lifecycle Policy
```
- Rule: Keep latest 100 images
- Action: Automatically expire older images
- Benefit: Reduces storage costs and simplifies image management
```

#### IAM Permissions for GitHub
- `ecr:GetAuthorizationToken`: Get authentication token
- `ecr:BatchCheckLayerAvailability`: Check layers
- `ecr:CompleteLayerUpload`: Complete uploads
- `ecr:InitiateLayerUpload`: Start uploads
- `ecr:PutImage`: Push images
- `ecr:UploadLayerPart`: Upload layer chunks
- `ecr:BatchGetImage`: Pull images
- `ecr:GetDownloadUrlForLayer`: Get download URLs

### 4. IAM Roles & Policies (iam.tf)

#### EKS Cluster Role
```hcl
Trust: eks.amazonaws.com
Policy: AmazonEKSClusterPolicy
```

#### EKS Node Role
```hcl
Trust: ec2.amazonaws.com
Policies:
  - AmazonEKSWorkerNodePolicy    : Basic worker node permissions
  - AmazonEKS_CNI_Policy         : VPC networking for pods
  - AmazonEC2ContainerRegistryPullOnly : Pull images from ECR
```

#### GitHub Application Role (OIDC)
```hcl
Trust: GitHub Actions (token.actions.githubusercontent.com)
Condition: repo:github_org/github_repo:ref:refs/heads/main
Permissions:
  - ECR: Push/pull images
  - EKS: Describe cluster
```

#### GitHub Terraform Role (OIDC)
```hcl
Trust: GitHub Actions (token.actions.githubusercontent.com)
Condition: repo:github_org/github_repo:ref:refs/heads/main
Permissions: AdministratorAccess (full infrastructure management)
```

### 5. EKS Addons (addons.tf)

#### VPC CNI
- **Purpose**: AWS networking for pods
- **Manages**: Pod IP addresses, security groups, network interfaces
- **Status**: Should be in Active state

#### CoreDNS
- **Purpose**: DNS service for Kubernetes
- **Resolves**: Service names to IP addresses
- **Status**: Should have 2+ replicas

#### Kube Proxy
- **Purpose**: Network proxy maintaining network rules
- **Implements**: Service networking and iptables
- **Status**: Should be running on all nodes

#### EBS CSI Driver
- **Purpose**: Persistent volumes using AWS EBS
- **Enables**: StatefulSets and PersistentVolumeClaims
- **Type**: Dynamic provisioning support

#### Pod Identity Agent
- **Purpose**: Provides temporary AWS credentials to pods
- **Enables**: Pods to assume IAM roles
- **Use Case**: Pods access S3, DynamoDB, other AWS services

## Network Architecture

### CIDR Planning

```
VPC: 10.20.0.0/16 (65,536 IPs)
├── Public Subnet 1 (AZ-1): 10.20.0.0/20 (4,096 IPs)
├── Public Subnet 2 (AZ-2): 10.20.1.0/20 (4,096 IPs)
├── Private Subnet 1 (AZ-1): 10.20.2.0/20 (4,096 IPs)
└── Private Subnet 2 (AZ-2): 10.20.3.0/20 (4,096 IPs)

Total allocated: 16,384 IPs out of 65,536 available
Remaining: 49,152 IPs (for future growth)
```

### Routing

#### Public Subnets
```
Destination    | Target
0.0.0.0/0     | Internet Gateway (direct internet access)
```

#### Private Subnets
```
Destination    | Target
0.0.0.0/0     | NAT Gateway in same AZ (outbound only)
```

### High Availability Considerations

1. **Multi-AZ Deployment**: All components deployed across 2 AZs
2. **NAT Gateway Redundancy**: One NAT per AZ ensures no single point of failure
3. **Node Distribution**: Nodes spread across AZs with auto-scaling
4. **Load Balancing**: Ready for AWS Load Balancer Controller (can be installed as addon)

## Security Features

### Defense in Depth

1. **Network Segmentation**
   - Private subnets for nodes (no direct internet access)
   - NAT gateways for controlled outbound traffic
   - Security groups for fine-grained control

2. **Encryption**
   - EKS secrets encrypted with customer-managed KMS key
   - Automatic key rotation enabled
   - TLS for all communications

3. **Identity & Access Control**
   - IAM roles with least privilege principle
   - Separate roles for cluster, nodes, and applications
   - OIDC provider for GitHub Actions (no static credentials)

4. **Logging & Monitoring**
   - 5 types of control plane logs to CloudWatch
   - 30-day log retention for compliance
   - Image scanning in ECR for vulnerability detection

5. **Future Security Enhancements**
   - Network Policies (via Calico or Weave)
   - Pod Security Policies or Pod Security Standards
   - Falco for runtime security
   - RBAC configuration for Kubernetes access control

## GitHub OIDC Integration

### Why OIDC?

OIDC (OpenID Connect) allows GitHub Actions to securely assume AWS roles **without storing static credentials**. This is more secure, easier to manage, and follows AWS best practices.

### How It Works

1. **GitHub Issues Token**: GitHub Actions request a token from GitHub's OIDC provider
2. **Token Exchange**: Your AWS account trusts GitHub's OIDC provider
3. **Role Assumption**: GitHub token is exchanged for temporary AWS credentials
4. **Time-Limited**: Credentials expire after ~1 hour
5. **Branch Restriction**: Only workflows on the main branch can assume the role

### GitHub Workflow Example

```yaml
name: Deploy to EKS

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::ACCOUNT-ID:role/enterprise-eks-dev-github-application
          aws-region: ap-south-1

      - name: Push to ECR
        run: |
          aws ecr get-login-password --region ap-south-1 | \
            docker login --username AWS --password-stdin ACCOUNT-ID.dkr.ecr.ap-south-1.amazonaws.com
          
          docker build -t enterprise-eks-dev:$GITHUB_SHA .
          docker tag enterprise-eks-dev:$GITHUB_SHA ACCOUNT-ID.dkr.ecr.ap-south-1.amazonaws.com/enterprise-eks-dev:$GITHUB_SHA
          docker push ACCOUNT-ID.dkr.ecr.ap-south-1.amazonaws.com/enterprise-eks-dev:$GITHUB_SHA

      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --region ap-south-1 --name enterprise-eks-dev
          kubectl set image deployment/my-app my-app=ACCOUNT-ID.dkr.ecr.ap-south-1.amazonaws.com/enterprise-eks-dev:$GITHUB_SHA
```

### Troubleshooting OIDC

```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check the OIDC provider details
aws iam get-open-id-connect-provider-thumbprint \
  --open-id-connect-provider-arn arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com

# Verify role trust relationship
aws iam get-role --role-name enterprise-eks-dev-github-application
```

## ECR Setup

### Accessing the Repository

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get repository URL
REPO_URL=$(aws ecr describe-repositories \
  --repository-names enterprise-eks-dev \
  --region ap-south-1 \
  --query 'repositories[0].repositoryUri' \
  --output text)

echo "Repository URL: $REPO_URL"
```

### Pushing Images Locally

```bash
# Authenticate Docker with ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

# Build image
docker build -t my-service:latest .

# Tag for ECR
docker tag my-service:latest $REPO_URL/my-service:latest
docker tag my-service:latest $REPO_URL/my-service:$(git rev-parse --short HEAD)

# Push to ECR
docker push $REPO_URL/my-service:latest
docker push $REPO_URL/my-service:$(git rev-parse --short HEAD)

# View images
aws ecr describe-images --repository-name enterprise-eks-dev --region ap-south-1
```

### Lifecycle Policy Details

```hcl
# Current Policy: Keep latest 100 images
# Actions:
#   - When image count exceeds 100, oldest images are expired
#   - Reduces storage costs
#   - Simplifies image management

# Customization:
#   Edit ecr.tf addons.tf and modify the lifecycle_policy
policy = jsonencode({
  rules = [{
    rulePriority = 1
    description  = "Keep latest N images"
    selection = {
      tagStatus   = "any"              # Apply to all images
      countType   = "imageCountMoreThan"
      countNumber = 100                # Keep this many images
    }
    action = { type = "expire" }       # Delete older images
  }]
})
```

## EKS Addons

### Installing Additional Addons

The current setup includes 5 core addons. Here are other popular addons you can add:

```hcl
# AWS Load Balancer Controller
resource "aws_eks_addon" "alb_controller" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-load-balancer-controller"
}

# Metrics Server (for HPA)
resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "metrics-server"
}

# CloudWatch Observability Addon
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "cloudwatch-observability"
}
```

### Monitoring Addon Status

```bash
# List all addons
aws eks list-addons --cluster-name enterprise-eks-dev --region ap-south-1

# Get addon details
aws eks describe-addon \
  --cluster-name enterprise-eks-dev \
  --addon-name vpc-cni \
  --region ap-south-1

# Check addon version
aws eks describe-addon-versions \
  --addon-name vpc-cni \
  --kubernetes-version 1.33 \
  --region ap-south-1
```

## Accessing the Cluster

### Prerequisites

```bash
# Install kubectl
brew install kubectl

# Install AWS IAM Authenticator
brew install aws-iam-authenticator

# Configure AWS credentials
aws configure
```

### Connection Steps

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name enterprise-eks-dev

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Check cluster resources
kubectl get svc
kubectl get pvc
kubectl get cm
```

### Using Multiple Clusters

```bash
# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context arn:aws:eks:ap-south-1:ACCOUNT-ID:cluster/enterprise-eks-dev

# Create context alias
kubectl config rename-context \
  arn:aws:eks:ap-south-1:ACCOUNT-ID:cluster/enterprise-eks-dev \
  eks-dev
```

## Managing Node Groups

### Scaling Nodes

```bash
# Get current ASG
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "eks-enterprise-eks-dev-nodes-*" \
  --region ap-south-1

# Scale to specific size
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "eks-enterprise-eks-dev-nodes-*" \
  --desired-capacity 3 \
  --region ap-south-1

# Or modify via Terraform
# Edit terraform.tfvars: node_desired_size = 3
terraform apply
```

### Viewing Node Information

```bash
# List nodes
kubectl get nodes

# Detailed node info
kubectl describe node <node-name>

# Node resource usage
kubectl top nodes

# Pod distribution across nodes
kubectl get pods --all-namespaces -o wide
```

### Updating Kubernetes Version

```bash
# Check current version
kubectl version --short

# Plan update (in terraform.tfvars)
# Change: eks_version = "1.34"

# Apply update
terraform plan
terraform apply

# Verify update
kubectl get nodes -o wide
# Each node will show the new kernel version
```

## Monitoring and Logging

### CloudWatch Logs

```bash
# View control plane logs
aws logs tail /aws/eks/enterprise-eks-dev/cluster --follow

# View specific log type (API logs)
aws logs tail /aws/eks/enterprise-eks-dev/cluster/api --follow

# View logs for a specific time range
aws logs filter-log-events \
  --log-group-name /aws/eks/enterprise-eks-dev/cluster \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --end-time $(date +%s)000

# Export logs
aws logs get-log-events \
  --log-group-name /aws/eks/enterprise-eks-dev/cluster \
  --log-stream-name <log-stream-name>
```

### Metrics & Monitoring

```bash
# Install Metrics Server (if not included)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View node metrics
kubectl top nodes

# View pod metrics
kubectl top pods --all-namespaces

# Check HPA status
kubectl get hpa --all-namespaces
```

### CloudWatch Dashboard

Create a dashboard to monitor your cluster:

```bash
# View cluster metrics in CloudWatch
# - CPU utilization
# - Memory usage
# - Network throughput
# - Log errors and warnings
```

### Logging Best Practices

1. **Log Levels**: Use appropriate log levels in applications
2. **Structured Logging**: Use JSON format for easier parsing
3. **Log Retention**: Current setting is 30 days (adjustable in eks.tf)
4. **Cost Monitoring**: Monitor CloudWatch costs with large clusters
5. **Compliance**: Maintain logs for audit trail and compliance requirements

## Cost Optimization

### Current Cost Drivers

```
1. EKS Cluster:        $0.10/hour (~$73/month)
2. EC2 Nodes (2x t3.large): ~$0.13/hour each (~$190/month total)
3. NAT Gateways (2):   $0.045/hour each (~$67/month total)
4. EBS Storage (20GB): ~$2/month
5. CloudWatch Logs:    ~$5-15/month (based on traffic)
6. ECR Storage:        ~$0.10/GB/month
─────────────────────────────────────
Estimated Monthly:     ~$350/month
```

### Cost Saving Strategies

1. **Use Reserved Instances**
   ```bash
   # Reserve t3.large for 1-year term
   # Savings: ~30-40% off on-demand pricing
   ```

2. **Implement Pod Limits**
   ```yaml
   resources:
     requests:
       memory: "256Mi"
       cpu: "100m"
     limits:
       memory: "512Mi"
       cpu: "500m"
   ```

3. **Scheduled Scaling**
   ```bash
   # Scale down during off-hours
   # Use cluster autoscaler to scale based on demand
   ```

4. **Right-Size Instances**
   ```hcl
   # For development: t3.medium or t3.small
   # For production: t3.large or bigger instances
   # Edit terraform.tfvars: node_instance_types = ["t3.medium"]
   ```

5. **Optimize Log Retention**
   ```hcl
   # Current: 30 days
   # For cost savings: Reduce to 7 or 14 days
   retention_in_days = 7  # in eks.tf
   ```

6. **Use Spot Instances** (for non-critical workloads)
   ```hcl
   # Add capacity type: SPOT in node group
   capacity_type = "SPOT"  # 70% discount vs on-demand
   ```

### Cost Monitoring

```bash
# Enable AWS Budgets
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json

# View costs in AWS Console
# Services → Cost Explorer → EKS, EC2, NAT Gateway
```

## Troubleshooting

### Common Issues

#### Issue: kubectl cannot connect to cluster

```bash
# Solution: Update kubeconfig
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name enterprise-eks-dev

# Verify credentials
aws sts get-caller-identity

# Check security group rules
aws ec2 describe-security-groups \
  --region ap-south-1 \
  --filters Name=group-name,Values=*eks*
```

#### Issue: Nodes not joining cluster

```bash
# Check node status
kubectl get nodes

# Describe problematic node
kubectl describe node <node-name>

# Check node logs
aws ec2 get-console-output --instance-id <instance-id> --region ap-south-1

# Check IAM role attachment
aws iam list-instance-profiles-for-role \
  --role-name enterprise-eks-dev-eks-nodes
```

#### Issue: Pod cannot pull image from ECR

```bash
# Solution: Verify ECR permissions
aws iam get-role-policy \
  --role-name enterprise-eks-dev-eks-nodes \
  --policy-name <policy-name>

# Manually test pull
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin ACCOUNT-ID.dkr.ecr.ap-south-1.amazonaws.com

docker pull ACCOUNT-ID.dkr.ecr.ap-south-1.amazonaws.com/enterprise-eks-dev:latest
```

#### Issue: Terraform state lock conflict

```bash
# View lock table
aws dynamodb scan \
  --table-name enterprise-eks-terraform-lock \
  --region ap-south-1

# Force unlock (use with caution!)
terraform force-unlock <LOCK-ID>
```

#### Issue: GitHub Actions OIDC token rejected

```bash
# Verify OIDC provider thumbprint
aws iam get-open-id-connect-provider-thumbprint \
  --open-id-connect-provider-arn arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com

# Check role trust policy
aws iam get-role --role-name enterprise-eks-dev-github-application

# Verify role can be assumed
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/enterprise-eks-dev-github-application \
  --role-session-name test-session \
  --web-identity-token $GITHUB_TOKEN
```

### Debugging Commands

```bash
# Check cluster connectivity
kubectl get cs

# Verify addon status
kubectl get daemonset -n kube-system
kubectl get deployment -n kube-system

# Check pod status
kubectl get pods --all-namespaces
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Check events
kubectl get events --all-namespaces
kubectl describe events -n <namespace>

# Network diagnostics
kubectl run -it --image=busybox:1.28 debug --restart=Never -- sh
  # Inside pod
  # nslookup kubernetes.default
  # nc -zv <service-name>
```

### Getting Help

- **AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **GitHub Issues**: Check the repository issues page
- **AWS Support**: Open a support case in AWS Console (requires support plan)

## Cleanup

### Removing Infrastructure (Costs Money!)

```bash
# WARNING: This will delete all resources including the cluster

# Delete applications and persistent volumes first
kubectl delete all --all --all-namespaces

# Switch to terraform directory
cd common/terraform

# Delete EKS infrastructure
terraform destroy

# Confirm deletion
# Type: yes

# Delete Terraform state backend
cd ../bootstrap-state
terraform destroy
```

### Important Notes

⚠️ **Warning**: Destroying infrastructure will:
- Delete the EKS cluster and all running pods
- Delete EC2 nodes and associated data
- Delete the ECR repository and all images
- Delete VPC and networking resources
- Delete KMS keys and other resources
- Incur additional data transfer charges

### Before Cleanup

1. **Backup Data**
   ```bash
   # Export persistent volumes
   kubectl get pvc --all-namespaces
   # Backup to S3 or local storage
   ```

2. **Export Configuration**
   ```bash
   # Get all manifests
   kubectl get all -A -o yaml > backup.yaml
   
   # Get Terraform state
   terraform output -json > terraform-outputs.json
   ```

3. **Verify No Critical Workloads**
   ```bash
   kubectl get deployments --all-namespaces
   kubectl get statefulsets --all-namespaces
   ```

### Partial Cleanup (Keep Infrastructure)

```bash
# Delete only the EKS cluster (keeps VPC, NAT, etc.)
cd common/terraform
terraform destroy -target=aws_eks_cluster.main

# Delete only ECR
terraform destroy -target=aws_ecr_repository.services
```

---

## Next Steps

After successful deployment:

1. **Set Up CI/CD**: Configure GitHub Actions workflows for deployment
2. **Install Ingress Controller**: Add AWS Load Balancer Controller
3. **Set Up Monitoring**: Install Prometheus and Grafana
4. **Configure RBAC**: Set up Kubernetes role-based access control
5. **Implement Network Policies**: Add network segmentation
6. **Set Up Logging**: Configure centralized logging (ELK, Datadog, etc.)
7. **Enable Pod Identity**: Configure pod-to-AWS service integration
8. **Production Hardening**: Review and implement security best practices

## Support & Contribution

For issues, questions, or contributions:
- Open an issue in the repository
- Review existing documentation
- Check AWS EKS best practices guide
