#!/bin/bash

# K8s Proxy VM Startup Script
# Install Kubectl
sudo apt-get install kubectl
export ZONE=europe-west6-a
export PROJECT_ID=$(gcloud config list --format="value(core.project)")
export CONTAINER_CLUSTER=$(gcloud container clusters list --format="value(name)")

gcloud container clusters get-credentials $CONTAINER_CLUSTER --zone=$ZONE --internal-ip

kubectl run k8s-api-proxy --image=gcr.io/$PROJECT_ID/k8s-api-proxy:latest --port=8118

# Retrieve the ilb.yaml from somewhere, perhaps a bucket or something ??
# Deploy the internal Load Balancer
kubectl create -f ilb.yaml

# Check for the service and wait for an IP address
kubectl get service/k8s-api-proxy

sleep 60

# Check for the service and wait for an IP address
kubectl get service/k8s-api-proxy

# Save the IP address of the LB as an environment variable
export LB_IP=$(kubectl get  service/k8s-api-proxy -o jsonpath='{.status.loadBalancer.ingress[].ip}')

# Save the Cluster master IP address in a variable
export MASTER_IP=$(gcloud container clusters describe $CONTAINER_CLUSTER --zone=$ZONE --format="get(privateClusterConfig.privateEndpoint)")

#Verify the proxy is usable by accessing the Kubernetes API through it
curl -k -x $LB_IP:8118 https://$MASTER_IP/api

# Set the https_proxy variable
export https_proxy=$LB_IP:8118

# Test the configuration
kubectl get pods
