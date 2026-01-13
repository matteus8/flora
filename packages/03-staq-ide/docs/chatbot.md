# Chatbot

This document provides details on the chatbot component of the Flora project.

## Functionality

The chatbot is a simple, CPU-based LLM that provides agentic coding features. It is designed to be lightweight and run in an air-gapped environment.

*   **AI Engine**: The service is powered by Ollama, a lightweight, extensible framework for running large language models locally.
*   **Model**: It uses the `TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF` model, which is a compact model suitable for CPU-based inference.

## Deployment

The chatbot is deployed as the `chatbot` component in the `zarf.yaml` package. The deployment process is carefully orchestrated to handle the air-gapped environment:

1.  **Storage**: A `PersistentVolumeClaim` (PVC) is created to store the AI model.
2.  **Model Seeding**: A one-time Kubernetes Job (`ollama-seed-job`) runs to copy the `tinyllama` model from its container image into the PVC.
3.  **Service Startup**: The main `ollama` deployment is initially scaled to 0 replicas. Once the seed job is complete, an `onDeploy` action scales the deployment to 1 replica.
4.  **Model Registration**: After the Ollama pod is ready, another `onDeploy` action executes a command inside the pod to register the model from the file system, making it available to the API.

This entire process is automated by Zarf to ensure a reliable startup sequence.

## Security

*   **Air-Gapped**: The Ollama service and the AI model are bundled within the Zarf package and do not require internet access.
*   **Model Scanning**: Before being packaged, the AI model is scanned for security vulnerabilities using `modelaudit` in the GitLab CI pipeline.
*   **Network Policy**: The service is isolated in its own `chatbot` namespace and exposed internally to the `web-ui` component.
