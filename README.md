#  GitOps Control Plane: Enterprise-Grade SRE Platform
**A High-Availability, Self-Healing Microservice Lifecycle Management System**

[![ArgoCD Status](https://img.shields.io/badge/ArgoCD-Synced-green?logo=argo-cd)](https://argoproj.github.io/cd/) 
[![Kubernetes](https://img.shields.io/badge/K8s-v1.28+-blue?logo=kubernetes)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-v3-blue?logo=helm)](https://helm.sh/)
[![Governance](https://img.shields.io/badge/Policy-Kyverno-orange?logo=kyverno)](https://kyverno.io/)

---

##  Case Study: Transitioning to Declarative GitOps

### The Challenge
Even with a fast CI/CD pipeline, the organization suffered from **"Configuration Drift."** Manual `kubectl` hotfixes in production were never documented in Git, leading to environment inconsistency. Deployment rollbacks were slow, and there was no automated way to ensure that infrastructure met security compliance (like non-root execution) before deployment.

### The Solution
I implemented a **Pull-based GitOps architecture**. By moving from static YAML to standardized **Helm Charts** and using **ArgoCD Application Controllers**, the cluster now automatically synchronizes itself with this repository. I integrated **Kyverno** to enforce Policy-as-Code (PaC) at the admission level.

### The Result
* **Drift Correction:** Automated reconciliation reverts manual changes in **< 30 seconds**.
* **Governance:** 100% of deployments must pass Kyverno Security Policies (e.g., Disallow Root).
* **Auditability:** Every infrastructure change is captured via Git Commit history, providing a perfect audit trail for compliance.

---
##  Key Features

###  Declarative Self-Healing
* **Continuous Reconciliation:** The ArgoCD Application Controller monitors the cluster 24/7. Any manual change (Configuration Drift) is automatically overwritten by the "Source of Truth" in Git.
* **Automated Sync Policy:** Configured with `automated: { prune: true, selfHeal: true }` to ensure the cluster state is always an exact mirror of the repository.

###  Modular Infrastructure (Helm)
* **Standardized Templating:** Replaced 500+ lines of static YAML with dynamic Helm templates, allowing for environment-specific overrides (Staging vs. Production) using a single chart.
* **Versioned Releases:** Every infrastructure change follows semantic versioning, enabling precise tracking of the platform's evolution.

###  Policy-as-Code (Kyverno)
* **Security Admission Control:** Integrated Kyverno ClusterPolicies to enforce security best practices.
* **Guardrails:** Automatically blocks any container attempting to run as `root` or missing mandatory labels, shifting security "Left" in the development lifecycle.

###  App-of-Apps Pattern
* **Root Orchestration:** Implemented the "Root App" pattern, where a single ArgoCD manifest manages the lifecycle of multiple sub-applications (App, Monitoring, Security), enabling one-click cluster bootstrapping.

---

##  Tech Stack & Pillars
| Domain | Technology | Use Case |
| :--- | :--- | :--- |
| **GitOps Engine** | ArgoCD (v2.x) | Continuous Delivery & Self-Healing |
| **Packaging** | Helm v3 | Modular & Reusable Infrastructure |
| **Policy Engine** | Kyverno | Policy-as-Code (Admission Control) |
| **Observability** | Prometheus | Real-time Metrics & Sync Health |
| **Orchestration** | Kubernetes | Minikube (Local) / EKS (Cloud) |
| **Automation** | GNU Make & Bash | SRE Resiliency Playbooks |

---

##  Project Structure
```text
.
├── apps/                          # Business Logic
│   └── devops-taskmaster/         # Java App Source
├── charts/                        # THE HELM COMPONENTS (Standardized)
│   ├── devops-taskmaster/         # Application-specific Helm chart
│   │   ├── Chart.yaml             # Versioning: 2.1.0-stable
│   │   ├── values.yaml            # Default configs
│   │   └── templates/             # Deployments, Services, HPA
│   └── observability-stack/       # Umbrella Chart for Monitoring
│       ├── Chart.yaml             # Deps: Prometheus, Loki, Grafana
│       └── values-prod.yaml       # Corporate hardening
├── gitops/                        # The ArgoCD "Control Plane"
│   ├── base/                      # Common Argo Application definitions
│   └── clusters/                  # Environment-specific overrides
│       ├── production/            # Final state of the Prod Cluster
│       └── staging/               # Final state of the Staging Cluster
├── platform/                      # Cluster-wide Security & Policy
│   └── kyverno/                   # Policy-as-Code (No root containers)
├── scripts/                       # Automation
│   └── simulate-drift.sh          # For the Incident Response test
├── Makefile                       # make install-argocd, make sync-all
└── README.md                      # GitOps Maturity Model & Case Study

```

---
##  Visual Proof of Execution

### 1. Automated Sync Logs
When the `application.yaml` is applied, the controller performs a **Recursive Sync**. 
Below is the log output confirming the successful creation of the infrastructure:
```text
TIMESTAMP           NAME                          KIND        STATUS     MESSAGE
Jan 17 05:00:01     devops-taskmaster-service     Service     Synced     service/devops-taskmaster-service created
Jan 17 05:00:02     devops-taskmaster             Deployment  Synced     deployment.apps/devops-taskmaster created
Jan 17 05:00:05     devops-taskmaster-6fb8        Pod         Healthy    Pod is running on minikube-node-01
```

To validate the reliability and resilience of this GitOps Control Plane, I performed two critical SRE simulations.

### 2. Automated Drift Correction (Self-Healing)
**Scenario:** An engineer performs "ClickOps" by manually scaling the deployment to 10 replicas via CLI, bypassing Git.
**Result:** ArgoCD detects the deviation from the `develop` branch and automatically reconciles the cluster back to the desired state (3 replicas) in seconds.

![Drift Test Simulation](./docs/drift-detection.gif)

### 3. Instant Version Rollback
**Scenario:** A configuration change (scaling to 5 replicas) is pushed to Git, but we need to revert to a previous stable state immediately.
**Result:** Using ArgoCD's History & Rollback feature, the cluster is reverted to a previous known-good Commit SHA instantaneously.

![Rollback Simulation](./docs/rollback.gif)

---

##  Execution & Deployment Guide
### Prerequisites
Ensure you have the following tools installed:

1.  **Minikube or a K8s Cluster.**
2.  **kubectl.**
3.  **Helm.**
4.  **make.** ( `sudo apt install make `)

**standardized Installation (Makefile)This project uses a Makefile to simplify complex Kubernetes commands.CommandActionmake bootstrapInstalls ArgoCD and the Root Application Controllermake passwordRetrieves the ArgoCD admin passwordmake forwardPort-forwards the ArgoCD UI to localhost:8080make test-driftExecutes the SRE Resilience Test**

### Command,Action
1. **`make bootstrap`,Installs ArgoCD and the Root Application Controller**
2. **`make password`,Retrieves the ArgoCD admin password**
3. **`make forward`,Port-forwards the ArgoCD UI to localhost:8081**
4. **`make test-drift`,Executes the SRE Resilience Test**

## Run the script:
**`make test-drift`**
**Observation: The script manually "sabotages" the cluster by scaling the production deployment to 10 replicas.**
**Result: Within seconds, the ArgoCD controller detects the Drift, marks the cluster as OutOfSync, and forcefully reverts the count back to the Git-defined state (e.g., 3 replicas).**
 
### Governance: Policy-as-Code
1. **Every deployment is scanned by Kyverno.**
2. **Non-Root Execution: Any container attempting to run as root is blocked at the admission level.**
---
**Developed with 🛡️ by Agbor Jonathan** *Building secure, scalable, and resilient automated systems.*
---
![ArgoCD](https://img.shields.io/badge/ArgoCD-Synced%20%26%20Healthy-success?style=for-the-badge&logo=argo-cd)
![K8s Namespace](https://img.shields.io/badge/Namespace-webapp-blue?style=for-the-badge&logo=kubernetes)

---
[ ![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white) ](linkedin.com/in/agbor)
[ ![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=todoist&logoColor=white) ](YOUR_PORTFOLIO_URL)
