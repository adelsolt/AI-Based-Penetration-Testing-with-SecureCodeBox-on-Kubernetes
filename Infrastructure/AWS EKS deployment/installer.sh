#!/bin/bash
set -e

echo "=== Updating package lists and installing prerequisites ==="
sudo apt update -y
sudo apt install -y ca-certificates curl gnupg jq apt-transport-https unzip

# --------------------
# Install AWS CLI v2
# --------------------
if ! command -v aws &>/dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi
echo "AWS CLI version: $(aws --version)"

# --------------------
# Install eksctl
# --------------------
if ! command -v eksctl &>/dev/null; then
    echo "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi
echo "eksctl version: $(eksctl version)"

# --------------------
# Install kubectl
# --------------------
if ! command -v kubectl &>/dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi
echo "kubectl version: $(kubectl version --client --short)"

# --------------------
# Install Helm (optional)
# --------------------
if ! command -v helm &>/dev/null; then
    echo "Installing Helm..."
    curl -fsSL https://baltocdn.com/helm/signing.asc | sudo tee /etc/apt/keyrings/helm.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/helm.asc] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
    sudo apt update -y
    sudo apt install -y helm
fi
echo "Helm version: $(helm version)"

# --------------------
# Load AWS Credentials from .env
# --------------------
if [ ! -f .env ]; then
  echo "Error: .env file not found. Please create a .env file with your AWS credentials."
  exit 1
fi
echo "Loading AWS credentials from .env..."
source .env

echo "AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"

# --------------------
# Configure AWS CLI using environment variables
# --------------------
echo "Configuring AWS CLI..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set default.region "${AWS_DEFAULT_REGION:-us-east-1}"
# Optional: set a default output format
aws configure set default.output json

# --------------------
# Create the EKS Cluster
# --------------------
echo "Creating EKS cluster '$CLUSTER_NAME'..."
eksctl create cluster --name $CLUSTER_NAME --region "$AWS_DEFAULT_REGION" --nodes 2 --node-type t3.medium --managed

echo "Verifying cluster nodes..."
kubectl get nodes

# --------------------
# Deploy SecureCodeBox Operator
# --------------------
echo "Deploying SecureCodeBox Operator using Helm..."
helm --namespace securecodebox-system upgrade --install --create-namespace securecodebox-operator oci://ghcr.io/securecodebox/helm/operator

echo "Verifying SecureCodeBox Operator deployment..."
kubectl get pods -n securecodebox-system

echo "To access the MinIO instance (if needed), run:"
echo "  kubectl port-forward -n securecodebox-system service/securecodebox-operator-minio --address 0.0.0.0 9001:9001"
echo "To retrieve MinIO credentials:"
echo "  kubectl get secret securecodebox-operator-minio -n securecodebox-system -o=jsonpath='{.data.root-user}' | base64 --decode; echo"
echo "  kubectl get secret securecodebox-operator-minio -n securecodebox-system -o=jsonpath='{.data.root-password}' | base64 --decode; echo"


# --------------------
# Create Letta-Server Namespace
# --------------------
echo "=== Creating namespace letta-server ==="
kubectl create namespace letta-server --dry-run=client -o yaml | kubectl apply -f -

# --------------------
# Letta secrets deployment
# --------------------
echo "=== Deploying Letta Secrets ==="
kubectl create secret generic letta-secrets --namespace=letta-server --from-env-file=.env


# --------------------
# Letta Secrets Deployment
# --------------------
echo "=== Deploying Letta Secrets ==="
kubectl create secret generic letta-secrets --namespace=letta-server --from-env-file=.env

# --------------------
# Deploy Letta Server (using your existing manifest)
# --------------------
echo "Deploying Letta Server using manifest letta-deployment.yaml..."
kubectl apply -f letta-deployment.yaml

echo "Verifying Letta Server deployment..."
kubectl get pods -n letta-server

echo "Deployment complete! Check Letta Server logs with:"
echo "  kubectl logs <letta-pod-name> -n letta-server"
