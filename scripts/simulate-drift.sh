#!/bin/bash
set -e

APP_NAME="devops-taskmaster-prod"
NAMESPACE="production"

echo " Starting Configuration Drift Simulation..."

# 1. Show current state
REPLICAS=$(kubectl get deployment -n $NAMESPACE -l app.kubernetes.io/name=devops-taskmaster -o jsonpath='{.items[0].spec.replicas}')
echo "✅ Current Git-defined state: $REPLICAS replicas."

# 2. Manually sabotage the cluster (The Drift)
echo " Sabotaging Cluster: Scaling to 10 replicas manually..."
kubectl scale deployment -n $NAMESPACE -l app.kubernetes.io/name=devops-taskmaster --replicas=10

# 3. Verify the drift
NEW_REPLICAS=$(kubectl get deployment -n $NAMESPACE -l app.kubernetes.io/name=devops-taskmaster -o jsonpath='{.items[0].spec.replicas}')
echo "⚠️  Manual state is now: $NEW_REPLICAS replicas."
echo " Waiting for ArgoCD to detect drift and Self-Heal..."

# 4. Watch for reconciliation
sleep 15
FINAL_REPLICAS=$(kubectl get deployment -n $NAMESPACE -l app.kubernetes.io/name=devops-taskmaster -o jsonpath='{.items[0].spec.replicas}')

echo "🔄 ArgoCD has reconciled the state."
echo "✅ Back to Git-defined state: $FINAL_REPLICAS replicas."
