#!/bin/bash
#!/usr/bin/env bash
# Deploys everything needed for the ToDo app + MySQL StatefulSet.
# Adjust the file names below to match where the manifests live in the repo.
set -euo pipefail

kubectl config use-context "kind-kind"

# 2. MySQL (namespace first, then config/secrets/service, then the StatefulSet)
kubectl apply -f .infrastructure/mysqlNamespace.yml
kubectl apply -f .infrastructure/mysqlSecret.yml
kubectl apply -f .infrastructure/mysqlConfigMap.yml
kubectl apply -f .infrastructure/mysqlServices.yml
kubectl apply -f .infrastructure/statefulSet.yml

echo "Waiting for MySQL pods..."
kubectl -n mysql rollout status statefulset/mysql --timeout=600s

# 3. ToDo app
kubectl create namespace todoapp --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f .infrastructure/pv.yml
kubectl apply -f .infrastructure/pvc.yml
kubectl apply -f .infrastructure/secret.yml
kubectl apply -f .infrastructure/configMap.yml
kubectl apply -f .infrastructure/deployment.yml
# kubectl apply -f service.yml   # if the repo has a Service for the app

echo "Waiting for the app..."
kubectl -n todoapp rollout status deployment/todoapp --timeout=300s

kubectl get pods -n mysql
kubectl get pods -n todoapp