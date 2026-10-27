# Software Factory Package (staq-factory)

This package contains the DevSecOps tooling suite for Platform STAQ:

## Included Components

| Component | Chart | Chart Version | App Version | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **SonarQube** | `sonarqube` (`https://SonarSource.github.io/helm-chart-sonarqube`) | `2026.5.1003` | `26.9.0-community` | Code Quality, Static Code Analysis (SAST) |
| **Nexus** | `nexus-repository-manager` (`https://sonatype.github.io/helm3-charts/`) | `64.2.0` | `3.97.3` | Binary & Artifact Proxy / Repository |
| **Harbor** | `harbor` (`https://helm.goharbor.io`) | `1.19.4` | `2.15.4` | OCI Container Registry & Vulnerability Scanning (Trivy, Valkey) |
| **ArgoCD** | `argo-cd` (`https://argoproj.github.io/argo-helm`) | `10.11.6` | `v3.5.6` | Declarative GitOps Continuous Delivery |

## Deployment

Deploy using Zarf:
```bash
zarf package deploy oci://<REGISTRY_URL>/airgap-ai-testing/flora/staq-factory:<VERSION> --confirm
```
