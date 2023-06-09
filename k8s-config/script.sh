#!/usr/bin/env bash
kind create cluster --config=kind-config.yaml
kubectl proxy --port=8000 --address 0.0.0.0 --accept-hosts '.*' &
kubectl create serviceaccount github-actions
kubectl apply -f clusterrole.yaml
kubectl create clusterrolebinding continuous-deployment \
    --clusterrole=continuous-deployment --serviceaccount=default:github-actions
# kubectl create token github-actions --duration=99999h
kubectl create -f secret.yaml
echo "\n\n-------------COPY THIS OUTPUT-------------\n"
kubectl  get secrets github-action-token -o yaml