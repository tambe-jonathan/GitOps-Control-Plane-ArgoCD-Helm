#!/bin/bash
set -e

# CONFIGURATION - Updated to match your 'kubectl --show-labels' output
NAMESPACE="webapp"
SELECTOR="app=devops-taskmaster"

echo " Starting Configuration Drift Simulation in namespace: $NAMESPACE..."

# 1. Get the current replica count
REPLICAS=$(kubectl get deployment -n $NAMESPACE -l $SELECTOR -o jsonpath='{.items[0].spec.replicas}')
echo " Current Git-defined state: $REPLICAS replicas."

# 2. Manually sabotage the cluster
echo " Sabotaging Cluster: Scaling to 10 replicas manually..."
kubectl scale deployment -n $NAMESPACE -l $SELECTOR --replicas=10

# 3. Verify the drift
echo "  Waiting for ArgoCD to detect drift and Self-Heal..."

# 4. Watch for reconciliation loop
for i in {1..20}; do
    CURRENT=$(kubectl get deployment -n $NAMESPACE -l $SELECTOR -o jsonpath='{.items[0].spec.replicas}')
    if [ "$CURRENT" == "$REPLICAS" ]; then
        echo "🔄 ArgoCD has detected drift and reconciled the state!"
        echo "✅ Back to Git-defined state: $CURRENT replicas."
        exit 0
    fi
    echo "...current state: $CURRENT replicas. Waiting for ArgoCD sync..."
    sleep 5
done

