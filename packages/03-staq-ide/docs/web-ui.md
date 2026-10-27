# Web UI

This document provides details on the Web UI component for the chatbot.

## Functionality

The Web UI provides a user-friendly, chat-based interface for interacting with the backend Ollama service. It is designed to be intuitive and easy to use for asking questions and getting assistance from the AI model.

This service is provided by the open-source Open WebUI project.

## Deployment

The Web UI is deployed as the `web-ui` component in the `zarf.yaml` package.

*   **Technology**: It uses the `open-webui/open-webui:0.12.0` container image.
*   **Configuration**: The Helm chart values are configured to connect the UI to the internal `ollama` service endpoint within the cluster.
*   **Routing**: An `HTTPRoute` manifest configures the Traefik gateway to route traffic from the `/chat` path to the Open WebUI service.

> TEST LOCALLY: `kubectl port-forward svc/open-webui -n web-ui 8080:8080`

## Security

The Web UI runs as a containerized application in its own `web-ui` namespace. It only communicates with the backend `ollama` service and does not have access to the underlying system or other components, ensuring a secure and isolated user interface.
