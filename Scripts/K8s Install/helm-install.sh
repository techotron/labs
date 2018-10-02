#!/bin/bash

echo "Installing helm..."
sudo wget -O helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz

echo "Unpacking helm"
sudo tar -zxvf ./helm.tar.gz

echo "Moving helm files to /usr/local/bin..."
sudo mv ./linux-amd64/helm /usr/local/bin/helm

# helm init will install the server component (tiller) onto the default cluster found with kubectl config current-context
echo "Initialise Helm and install Tiller (server)..."
sudo helm init

# Create k8s credentials
echo "Creating Kubernetes credentials..."
sudo kubectl create serviceaccount --namespace kube-system tiller
sudo kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
sudo kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
