# IDE

This document provides details on the Integrated Development Environment (IDE) component.

## Functionality

The IDE is an instance of **code-server**, which provides a full-featured Visual Studio Code experience directly in the browser. This allows developers to work from anywhere without needing to install a local IDE.

The IDE can be extended with plugins to interact with the chatbot, providing features like code completion and generation.

## Deployment

The IDE is deployed as the `code-server` component in the `zarf.yaml` package.

*   **Technology**: It uses the `coder/code-server:4.18.0` container image.
*   **Namespace**: It is deployed into a dedicated `code-server` namespace.
*   **Routing**: Access to the IDE is managed by an `HTTPRoute` manifest, which configures the Traefik gateway to route traffic from the `/ide` path to the code-server service.

> TEST LOCALLY: `kubectl port-forward svc/code-server -n code-server 8888:8080`

> PASSWORD:     `kubectl get secret code-server-password --namespace code-server -o jsonpath="{.data.password}" | base64 --decode`

## Security

The IDE runs in a sandboxed container within the Kubernetes cluster, isolated from the host system and other services. All container images are mirrored to a private GitLab registry and bundled by Zarf, ensuring they are scanned and verified.
