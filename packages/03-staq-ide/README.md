# Integrated Development Environment (IDE) AI Stack

This repository contains the configuration for a Zarf package that creates a secure, air-gapped development environment with an IDE and AI tooling. The CI/CD pipeline handles building, scanning, and publishing the package.

> Current stable Zarf Package version 2.0

## Overview

This project provides a single Zarf package that deploys a complete, self-contained development environment, including:

*   **Code-Server:** A web-based IDE based on VS Code. Accessible at `http://code-server.localhost:8000`.
*   **Chatbot (Ollama):** A CPU-based LLM for agentic coding and chatting. The service is available at `http://chatbot.localhost:8000`. By default, it uses the `tinyllama` model.
*   **Web UI (Open WebUI):** A simple interface for the chatbot. Accessible at `http://web-ui.localhost:8000`.

All components are deployed in a secure, air-gapped environment, making it suitable for use in highly regulated industries.

## Deployment

The CI/CD pipeline in this repository automatically builds the Zarf package and publishes it to the project's GitLab container registry.

To deploy the package, you will need Zarf installed on your local machine.

1.  **Login to the GitLab Registry:**
    ```bash
    # Note: This may require a Personal Access Token with read_registry scope
    zarf tools registry login <your-gitlab-registry-url>
    ```

2.  **Deploy the Package:**
    Deploy the package directly from the OCI registry. Replace `<your-gitlab-registry-image-path>` and `<version>` with the correct values from your project's container registry. The version will typically be a git tag or short commit SHA.

    ```bash
    zarf package deploy oci://<your-gitlab-registry-image-path>:<version> --confirm
    ```

## Images

The `images.txt` file contains a list of container images used in this package. This file is used by the `zarf dev find-images` command to populate the `images` section of the `zarf.yaml` file.
