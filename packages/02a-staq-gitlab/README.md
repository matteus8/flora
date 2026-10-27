# GitLab Package (staq-gitlab)

This package contains the self-hosted GitLab air-gap deployment for Platform STAQ.

## Overview

- **Component**: GitLab
- **Helm Chart**: `gitlab/gitlab` version `9.11.14`
- **Application Version**: `v18.11.13` (Community Edition)
- **Included Services**:
  - GitLab Webservice & Workhorse
  - GitLab Sidekiq
  - GitLab Shell & Gitaly
  - GitLab Container Registry
  - GitLab Runner (`alpine-v18.11.2`)
  - Self-contained PostgreSQL (`16.6.0`), Redis (`7.2.4`), and MinIO object storage

## Deployment

Deploy using Zarf:
```bash
zarf package deploy oci://<REGISTRY_URL>/airgap-ai-testing/flora/staq-gitlab:<VERSION> --confirm
```
