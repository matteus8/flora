# Flora: Platform STAQ Orchestrator

Flora is a Zarf-based orchestration repository designed to build, harden, and package **Platform STAQ** (Secure Tooling & AI Quarters). It enables the deployment of a full DevOps and AI development suite into air-gapped or highly regulated environments.

## Repository Structure

The repository is organized into modular Zarf packages, allowing for a "foundation-first" deployment model.

### Packages (`/packages`)

| Package | Component | Description |
| :--- | :--- | :--- |
| **01-staq-core** | **Foundation** | **Mandatory.** Ingress (Traefik), Cert-Manager, Logging (Loki), and Observability (Prometheus). |
| **02a-staq-gitlab** | **Source Control** | Self-hosted GitLab instance with integrated container registry and runners. |
| **02b-staq-factory** | **DevSecOps** | Tooling factory including ArgoCD, Nexus, SonarQube, and Harbor. |
| **03-staq-ide** | **AI Workspace** | Code-Server (VS Code), Ollama (AI Chatbot), and hardened AI models. |
| **04-staq-custom** | **User Stack** | A template for cherry-picking specific components for a bespoke deployment. |

---

## CI/CD Pipeline logic

The platform uses GitHub Actions to automate the transition from source code to airgap-ready OCI artifacts:

1.  **Model Hardening**: (See `packages/03-staq-ide/Dockerfile.model`) The pipeline downloads raw GGUF models, performs a security scan, and wraps them into a hardened data-container image
2.  **Package Creation**: Zarf bundles Kubernetes manifests, Helm charts, and images into OCI artifacts
3.  **OCI Publishing**: Artifacts are pushed to Amazon ECR using OIDC keyless authentication

---

## Local Deployment Instructions

### Prerequisites
*   [Zarf CLI](https://zarf.dev) installed locally
*   Access to a Kubernetes cluster (K8's or K3's)
*   (Optional) AWS CLI configured for ECR access

### 1. Authenticate to the Registry
```bash
aws ecr get-login-password --region us-east-2 | zarf tools registry login <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com -u AWS --password-stdin
```

### 2. Deploy the Foundation (Core)
The Core package must be deployed before any other services
```bash
zarf package deploy oci://<AWS_URL>/airgap-ai-testing/flora/staq-core:<VERSION> --confirm
```

### 3. Deploy the AI Workspace (IDE)
Includes the hardened AI model and web-based VS Code environment.
```bash
zarf package deploy oci://<AWS_URL>/airgap-ai-testing/flora/staq-ide:<VERSION> --confirm
```

---

## Airgap Preparation

To move this platform into a disconnected environment:

1.  **Pull the artifacts** on a connected machine:
    ```bash
    zarf package pull oci://<AWS_URL>/airgap-ai-testing/flora/staq-core:<VERSION>
    zarf package pull oci://<AWS_URL>/airgap-ai-testing/flora/staq-ide:<VERSION>
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