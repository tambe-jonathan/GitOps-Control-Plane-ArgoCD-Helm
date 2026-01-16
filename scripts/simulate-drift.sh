#!/bin/bash
set -e

APP_NAME="devops-taskmaster-prod"
NAMESPACE="production"
SELECTOR="app.kubernetes.io/name=devops-taskmaster"

echo " Starting Configuration Drift Simulation..."

# 1. Show current state
REPLICAS=$(kubectl get deployment -n $NAMESPACE -l $SELECTOR -o jsonpath='{.items[0].spec.replicas}')
echo " Current Git-defined state: $REPLICAS replicas."

# 2. Manually sabotage the cluster (The Drift)
echo " Sabotaging Cluster: Scaling to 10 replicas manually (ClickOps)..."
kubectl scale deployment -n $NAMESPACE -l $SELECTOR --replicas=10

# 3. Verify the drift
echo "  Waiting for ArgoCD to detect drift and Self-Heal..."

# 4. Watch for reconciliation (Loop until it goes back to original count)
for i in {1..20}; do
    CURRENT=$(kubectl get deployment -n $NAMESPACE -l $SELECTOR -o jsonpath='{.items[0].spec.replicas}')
    if [ "$CURRENT" == "$REPLICAS" ]; then
        echo "🔄 ArgoCD has detected drift and reconciled the state!"
        echo " Back to Git-defined state: $CURRENT replicas."
        exit 0
    fi
    echo "...still at $CURRENT replicas, waiting for ArgoCD sync..."
    sleep 3
done

echo "❌ Timeout: ArgoCD did not reconcile. Check if 'Self-Heal' is enabled in the UI."
