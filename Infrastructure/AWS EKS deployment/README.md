# Automated AWS EKS Cluster Deployment for Letta + SecureCodeBox

This guide explains how to automate the deployment and deletion of an AWS EKS cluster that will run the Letta AI agent and SecureCodeBox operator. The deployment uses eksctl from a local WSL Ubuntu environment.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
  - [1. AWS Credentials Setup](#1-aws-credentials-setup)
  - [2. Cluster Creation](#2-cluster-creation)
  - [3. Application Deployment](#3-application-deploymen)
    - [3.1 Deploy SecureCodeBox Operator](#31-deploy-the-securecodebox-operator)
    - [3.2 Deploy Letta Server](#32-deploy-the-letta-server)
  - [4. Cleanup](#4-cleanup)

## Overview

The deployment stack includes:
- **AWS EKS**: Amazon's managed Kubernetes service
- **eksctl**: CLI tool for EKS cluster management
- **kubectl**: Kubernetes command-line tool
- **AWS CLI**: AWS command-line interface
- **.env file**: Secure credential storage

## Prerequisites

Before starting, ensure you have:

1. **Environment**
   - WSL Ubuntu installed and running
   - AWS account with EKS cluster creation permissions


2. **Required Tools**
   - AWS CLI
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws version
```
   - eksctl
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

```
   - kubectl
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

```

   - Helm (optional, for application deployment)
```
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo tee /etc/apt/keyrings/helm.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/helm.asc] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
sudo apt update -y
sudo apt install -y helm
helm version

```

## Installation Steps

### 1. AWS Credentials Setup

1. Create a `.env` file in your project root:
   ```dotenv
   AWS_ACCESS_KEY_ID=your_access_key_id
   AWS_SECRET_ACCESS_KEY=your_secret_access_key
   AWS_DEFAULT_REGION=us-east-1
   ```

2. Add `.env` to `.gitignore`:
   ```plaintext
   .env
   ```

3. Load credentials into your shell:
   ```bash
   source .env
   ```

### 2. Cluster Creation

Deploy your EKS cluster using eksctl:

```
eksctl create cluster --name agentic-ai-scb --region $AWS_DEFAULT_REGION --nodes 2 --node-type t3.medium --managed
```

#### Note:
Specifications of t3.medium:
2 vCPUs
4 GB RAM
Burstable performance

Verify the Cluster

```
kubectl get nodes
```


### 3. Application Deploymen

#### 3.1. Deploy the SecureCodeBox operator

Use Helm to deploy the SecureCodeBox operator (which includes a built-in MinIO):

```
helm --namespace securecodebox-system upgrade --install --create-namespace securecodebox-operator oci://ghcr.io/securecodebox/helm/operator
```

Verify deployment:

```
kubectl get pods -n securecodebox-system
```

(Optional) To access the MinIO instance:

```
kubectl port-forward -n securecodebox-system service/securecodebox-operator-minio --address 0.0.0.0 9001:9001
```

Retrieve credentials if needed:

```
kubectl get secret securecodebox-operator-minio -n securecodebox-system -o=jsonpath='{.data.root-user}' | base64 --decode; echo
kubectl get secret securecodebox-operator-minio -n securecodebox-system -o=jsonpath='{.data.root-password}' | base64 --decode; echo
```
#### 3.2. Deploy the Letta Server

Deploy it using:

```
kubectl apply -f letta-deployment.yaml
```

Verify that the Letta server is running:

```
kubectl get pods -n letta-server
```

And check logs for any errors:

```
kubectl logs <letta-pod-name> -n letta-server
```

### 4-cleanup

Delete the Cluster When Finished

```
eksctl delete cluster --name agentic-ai-scb --region $AWS_DEFAULT_REGION
```