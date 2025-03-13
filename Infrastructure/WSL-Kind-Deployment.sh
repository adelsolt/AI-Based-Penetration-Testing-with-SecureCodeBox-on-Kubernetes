#!/bin/bash
set -e

echo "=== Updating package lists ==="
sudo apt update -y

echo "=== Installing prerequisites (ca-certificates, curl, gnupg, jq, apt-transport-https) ==="
sudo apt install -y ca-certificates curl gnupg jq apt-transport-https

# --------------------
# Docker Installation
# --------------------
echo "=== Setting up Docker repository ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Installing Docker ==="
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Docker version:"
docker --version

# --------------------
# Kind Installation
# --------------------
echo "=== Installing Kind ==="
if [ "$(uname -m)" = "x86_64" ]; then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
else
    echo "Unsupported architecture"
    exit 1
fi
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "Kind version:"
kind --version

# Creating a kind cluster
echo "=== Creating KIND cluster 'agentic-ai-scb' ==="
kind create cluster --name agentic-ai-scb

# --------------------
# Helm Installation
# --------------------
echo "=== Installing Helm ==="
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo tee /etc/apt/keyrings/helm.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/helm.asc] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
sudo apt update -y
sudo apt install -y helm
echo "Helm version:"
helm version

# --------------------
# Kubectl Installation
# --------------------
echo "=== Installing Kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "Kubectl version (client):"
kubectl version --client

# --------------------
# SecureCodeBox Operator Installation
# --------------------
echo "=== Installing SecureCodeBox Operator via Helm ==="
helm --namespace securecodebox-system upgrade --install --create-namespace securecodebox-operator oci://ghcr.io/securecodebox/helm/operator

echo ""
echo "SecureCodeBox Operator deployed successfully."
echo "Verify deployment with:"
echo "  kubectl get pods -n securecodebox-system"
echo ""
echo "To port-forward the MinIO instance, run:"
echo "  kubectl port-forward -n securecodebox-system service/securecodebox-operator-minio --address 0.0.0.0 9001:9001"
echo ""
echo "To retrieve MinIO credentials, run:"
echo "  kubectl get secret securecodebox-operator-minio -n securecodebox-system -o=jsonpath='{.data.root-user}' | base64 --decode; echo"
echo "  kubectl get secret securecodebox-operator-minio -n securecodebox-system -o=jsonpath='{.data.root-password}' | base64 --decode; echo"

# --------------------
# Create Namespace
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
kubectl create secret generic letta-secrets --namespace=letta-server --from-env-file=../.env

# --------------------
# Letta Server Deployment
# --------------------
echo "=== Deploying Letta Server from external YAML file ==="
kubectl apply -f letta-deployment.yaml


# --------------------
# Run port forwarding in the background with nohop
# --------------------
nohup kubectl port-forward -n letta-server svc/letta-service 8283:8283 > portforward.log 2>&1 &


