# Minimal K3s Foundation Package (Dependency)

This Zarf package provides the minimal core infrastructure and observability stack required for a small-scale, air-gapped environment.

## 💡 Distribution Rationale: Why K3s over EKS-D/K8s?

This foundation is built upon K3s for three primary reasons:

1.  **Minimal Footprint:** K3s is a highly lightweight, certified Kubernetes distribution designed for resource-constrained environments (edge, IoT, CI). It consumes significantly fewer resources (memory and CPU) than full-distribution options like EKS-D, RKE, or vanilla Kubernetes.
2.  **Air-Gap Optimization:** K3s uses a single binary and fewer moving parts, simplifying the initial Zarf packaging and deployment process.
3.  **Targeted Scaling Profile:** K3s is designed to efficiently manage smaller, constrained environments, providing stability and performance for:
    *   **Resource Goal:** Typically running with **< 512MB RAM** overhead for the core K3s services on an idle server.
    *   **Workload Capacity:** Reliably supporting **~25-50 total workloads (Pods)** across **1-5 worker nodes** with a single control-plane/master node.
    *   **Architectural Fit:** Optimally deployed on low-power devices, virtual machines, or environments where the primary focus is low latency and high stability at the edge.

## 🚀 Deployment Environment Strategy (Air-Gap vs. Scaled Services)

This package uses K3s to establish the core services on a minimal platform. This serves a dual purpose:

1.  **Air-Gap Testbed:** It confirms that all core dependencies (Traefik, Cert-Manager, Observability) are fully Zarf-packaged and function correctly in a resource-constrained, air-gapped environment.
2.  **Scalability Foundation:** This architecture is **not intended** for resource-heavy services (like GitLab, Harbor, or Nexus). For those workloads, a **dedicated, scaled Kubernetes distribution** (e.g., RKE or EKS-D) is required. Zarf facilitates this transition simply by targeting the new cluster during the `zarf deploy` phase.

## Core Components Overview

| Component         | Installation Method                                            | Purpose & Rationale |
| :---              | :---                                                           | :--- |
| **Ingress-Traefik**| Custom Zarf Component (Helm Chart)                             | Serves as the Ingress Controller with Gateway API enabled. **Requires a LoadBalancer to expose the service.** |
| **Cert-Manager**  | Separate Zarf Component (Helm Chart)                           | Automates the provisioning and rotation of TLS certificates. **Industry-standard** for robust security. |
| **Observability** | **Single** Zarf Component (`kube-prometheus-stack` Helm Chart) | Provides the core *metrics* and *dashboarding* capabilities: **Prometheus**, **Grafana**, and **Alertmanager**. |
| **Logging Stack** | Separate Zarf Component (Loki & Promtail Helm Chart)           | Provides resource-light log collection via **Promtail** and scalable, centralized log storage via **Loki**. |

## 📐 Architectural & Security Rationale

### 1. Security and Control over Ingress (Custom vs. K3s Default)

While Zarf's K3s component disables the default Traefik, we deploy our own chart to achieve a **hardened security posture**. This gives us auditable, explicit control over all security settings, allows for independent patching of the Ingress Controller for vulnerabilities, and enables advanced features like the Gateway API.

### 2. Observability Stack: PLG vs. ELK/ECK

We use the **PLG Stack (Prometheus/Loki/Grafana)** instead of the ELK/ECK Stack because:
*   **Resource Usage:** PLG is designed for minimal overhead, whereas **Elasticsearch is notoriously memory and CPU intensive**, directly conflicting with the minimal K3s goal.
*   **Conclusion:** PLG offers the best **resource-to-footprint ratio** for observability in a small, constrained cluster.

### 3. Resource Optimization & K3s Integration Notes

*   **External Load Balancer Requirement:** The Traefik Ingress Controller is deployed as a **`LoadBalancer` service type**. In bare-metal or air-gapped K3s deployments, a separate implementation (e.g., **MetalLB or Kube-VIP**) must be running on the cluster to expose Traefik to the network. This package assumes a working Load Balancer implementation is available. Consider OpenStack CPI to get a Load Balancer from Octavia.

*   **Retention and Limits:** All metric and log components are aggressively tuned for low-resource use:
    *   Configured retention for both **Prometheus metrics and Loki logs** to a minimal **7 days**.
    *   Storage (PVC) for both Prometheus and Loki is **explicitly size-limited**.
*   **Policy Enforcement:** Policy enforcement relies on the **K3s native Admission Controller** features, eliminating the need for a separate Helm deployment (e.g., Gatekeeper, Kyverno).