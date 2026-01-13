# Flora: Platform STAQ

Flora is the repository for **Platform STAQ**, which includes comprehensive, airgap-friendly staq's for development platform builds. It provides a suite of tools including GitLab, ArgoCD, SonarQube, Nexus, and a VS Code-based IDE with AI assistants (Ollama, Open WebUI).

## Getting Started

### Prerequisites
- Linux (AMD64)
- Docker (for building)
- [Zarf](https://zarf.dev) (optional, if not using the `staq` CLI wrapper)

## Components

There are 4 comonents. YOU MUST INSTALL the first `1` as this is the foundation. The others are all optional, you can install them independatly of option `1`.
1.  **Core** (`this is mandatory`):  
    - The base Kubernetes layer (cert-manager, ingress, logging, observability) you can read more [here](./packages/01-staq-core/README.md).
2. **Gitlab and/or Factory** (`optional`)
    - (A) **GitLab**: A self-hosted GitLab instance with runners.
    - (B) **Factory**: External DevOps tools (ArgoCD, Nexus, SonarQube, Harbor).
3.  **Integrated Development Environment (IDE)** (`optional`) 
    - A developer workspace with Code-Server (web based VS-Code) and AI model (tinyllama:1.1b-v2).
4. **Customize**: and save with liberty mutual (`optional`)
    - Cherry pick services from this entire repo and build your own staq
      > NOTE: Size contraints should be considered when developing a custom package.

## Using the CLI (`staq`)

This project includes a custom CLI wrapper called `staq` (built from the `cli/` directory). It simplifies the deployment and management of the platform.
> NOTE: The staq CLI is just a wrapper for [zarf](https://docs.zarf.dev/)

### Building the CLI Wrapper
```bash
make build-cli
# This will create/provide you the cli --- "staq-linux-amd64"
```

### Deploying the Platform
You can then deploy packages directly from the OCI registry using the `staq` cli:

```markdown
# Login to the registry
`./staq tools registry login <AWS-URL> -u <user> -p <token>`

# Deploy Core
# Change the version of staq core
`./staq deploy oci://<AWS-URL>/airgap-ai-testing/flora/staq-core:vx.x.x`
```

## Release Process

Releases are automated via GitLab CI/CD.

1.  **Development**: Push changes to `main`.
2.  **Release**:
    *   Before cutting a **GitLab Release**. You **must** update the release page. This page is is created with downloadable links and instructions - these instructions can and should be updated before each release. You can update those instructions [here](.gitlab-ci.yml#L148). Once you are happy with the release notes...
    *   Create a tag: `git tag -a v1.0.X -m "Release v1.0.X"`
    *   Push the tag: `git push origin v1.0.X` --- see which version we are on before cutting.
3.  **Artifacts**:
    *   The pipeline builds the Zarf/Staq packages and streams them to the **AWS ECR** (OCI).
    *   Instructions and the downloadable CLI are then cut and released on the [release page](https://gitlab.com/airgap-ai-testing/flora/-/releases).

## Airgap Usage

For air-gapped environments where you cannot access `AWS ECR`:

1.  **Download the Packages**:
    On a connected machine, pull the packages to local files:
    ```bash
    # THE BASELINE
    ./staq package pull oci://<AWS-URL/airgap-ai-testing/flora/staq-core:vx.x.x
    
    # THE ADDITONS
    ./staq package pull oci://<AWS-URL/airgap-ai-testing/flora/staq-<PACKAGE-NAME>:vx.x.x
    ```
    This will pull down the core package locally as well as anything else you need.

2.  **Transfer**: Move the `.tar.zst` files and the `staq` binary to your air-gapped machine.

3.  **Deploy**:
    ```bash
    # AUTHENTICATE TO THE CLUSTER OR ENSURE YOU ARE ON THE RIGHT CLUSTER
    
    kubectl config -h
    kubectl config get-contexts

    kubectl config set-context <cluster you want> --user=cluster-admin

    # DEPLOY THE BASELINE
    ./staq deploy zarf-package-staq-core-amd64-vx.x.x.tar.zst

    # DEPLOY THE ADDITONS
    ./staq deploy zarf-package-staq-<service>-amd64-vx.x.x.tar.zst
    ```
