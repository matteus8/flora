# Flora: Platform STAQ Orchestrator

Flora is a Zarf-based orchestration repository designed to build, harden, and package **Platform STAQ** (Secure Tooling & AI Quarters). It enables the deployment of a full DevOps and AI development suite into air-gapped or highly regulated environments.

## Repository Structure

The repository is organized into modular Zarf packages, allowing for a "foundation-first" deployment model.

### Packages (`/packages`)

| Package | Component | Versions & Tools | Description |
| :--- | :--- | :--- | :--- |
| **01-staq-core** | **Foundation** | Traefik (Chart 42.1.3 / v3.7.16), Gateway API (v1.6.3), Cert-Manager (v1.21.3), Kube-Prometheus-Stack (92.14.1 / Prom v3.15.1, Grafana 13.2.4), Loki (7.5.0 / v3.6.11), Promtail (6.17.1 / v3.5.1) | **Mandatory.** Ingress, Cert-Manager, Logging, and Observability foundation. |
| **02a-staq-gitlab** | **Source Control** | GitLab (Chart 9.11.14 / v18.11.13 CE), Runner (v18.11.2), PostgreSQL (16.6.0), Redis (7.2.4), MinIO | Self-hosted GitLab instance with integrated container registry, runners, and storage. |
| **02b-staq-factory** | **DevSecOps** | ArgoCD (Chart 10.11.6 / v3.5.6), SonarQube (2026.5.1003 / 26.9.0-community), Nexus (64.2.0 / 3.97.3), Harbor (1.19.4 / 2.15.4) | Tooling factory including GitOps CD, SAST, artifact repository, and container registry. |
| **03-staq-ide** | **AI Workspace** | Code-Server (Chart 3.0.0 / 4.100.0), Ollama (Chart 1.92.0 / 0.40.11), Open WebUI (Chart 17.0.0 / 0.12.0), TinyLlama 1.1B | Web-based VS Code IDE, CPU-based LLM chatbot, and Open WebUI frontend. |
| **04-staq-custom** | **User Stack** | Custom cherry-picked components | A template for cherry-picking specific components for a bespoke deployment. |

---

## CI/CD Pipeline logic

The platform uses GitHub Actions to automate the transition from source code to airgap-ready OCI artifacts:

1.  **Model Hardening**: (See `packages/03-staq-ide/Dockerfile.model`) The pipeline downloads raw GGUF models, performs a security scan, and wraps them into a hardened data-container image
2.  **Package Creation**: Zarf bundles Kubernetes manifests, Helm charts, and images into OCI artifacts
3.  **OCI Publishing**: Artifacts are pushed directly to GitHub Container Registry (`ghcr.io/matteus8/flora`)

---

## Local Deployment Instructions

### Prerequisites
*   [Zarf CLI](https://zarf.dev) installed locally
*   Access to a Kubernetes cluster (K8s or K3s)

### 1. Authenticate to the Registry
```bash
echo "<GITHUB_PAT>" | zarf tools registry login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

### 2. Deploy the Foundation (Core)
The Core package must be deployed before any other services:
```bash
zarf package deploy oci://ghcr.io/matteus8/flora/staq-core:<VERSION> --confirm
```

### 3. Deploy the AI Workspace (IDE)
Includes the hardened AI model and web-based VS Code environment:
```bash
zarf package deploy oci://ghcr.io/matteus8/flora/staq-ide:<VERSION> --confirm
```

---

## Airgap Preparation

To move this platform into a disconnected environment:

1.  **Pull the artifacts** on a connected machine:
    ```bash
    zarf package pull oci://ghcr.io/matteus8/flora/staq-core:<VERSION>
    zarf package pull oci://ghcr.io/matteus8/flora/staq-ide:<VERSION>
    ```
2.  **Transfer** the resulting `.tar.zst` files to the airgapped network
3.  **Initialize** the airgap cluster:
    ```bash
    zarf init
    ```
4.  **Deploy locally**:
    ```bash
    zarf package deploy zarf-package-staq-core-amd64-<VERSION>.tar.zst
    ```

---
**Note:** For custom configurations, refer to the `zarf-config.yaml` at the root of the repository to set global deployment variables