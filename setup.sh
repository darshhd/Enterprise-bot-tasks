#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="demo"
NAMESPACE="demo"
RELEASE_NAME="demo"
IMAGE_REPO="demo-service"
IMAGE_TAG="1.0.0"
IMAGE="${IMAGE_REPO}:${IMAGE_TAG}"


echo "Checking if kind cluster '${CLUSTER_NAME}' exists"
if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "Cluster '${CLUSTER_NAME}' already exists, reusing"
else
  echo "Creating cluster '${CLUSTER_NAME}'"
  kind create cluster --name "${CLUSTER_NAME}"
fi

# Make sure kubectl is talking to the kind cluster
kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null

echo "Installing / upgrading ingress-nginx controller"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update ingress-nginx >/dev/null

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.watchIngressWithoutClass=true \
  --wait \
  --timeout 5m

echo "Waiting for ingress-nginx controller to be ready"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "Building Docker image ${IMAGE}"
docker build -t "${IMAGE}" ./service

echo "Loading image into kind cluster '${CLUSTER_NAME}'"
kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"

echo "Ensuring namespace '${NAMESPACE}' exists"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Installing / upgrading Helm release '${RELEASE_NAME}'"
helm upgrade --install "${RELEASE_NAME}" ./chart \
  --namespace "${NAMESPACE}" \
  --set image.repository="${IMAGE_REPO}" \
  --set image.tag="${IMAGE_TAG}" \
  --set image.pullPolicy=IfNotPresent \
  --wait \
  --timeout 3m

echo ""
echo "Setup complete"
echo "Cluster: kind-${CLUSTER_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Release: ${RELEASE_NAME}"
echo "Image: ${IMAGE}"
echo ""
echo "See README.md for verification commands."
