# GCP DevOps Toolbox

*Cloud Shell-like experience*

A multi-architecture (`linux/amd64`, `linux/arm64`) development container pre-configured with Google Cloud SDK, Kubernetes, Terraform, Docker CLI, and GitHub CLI.

---

## Table of Contents
- [Overview](#overview)
- [Included Tools](#included-tools)
- [How to Use](#how-to-use)
  - [1. Starting the Container](#1-starting-the-container)
  - [2. Attaching to the Interactive Shell](#2-attaching-to-the-interactive-shell)
  - [3. Authenticating Your Tools](#3-authenticating-your-tools)
  - [4. Executing Commands Directly](#4-executing-commands-directly)
  - [5. Stopping and Cleaning Up](#5-stopping-and-cleaning-up)
- [Volume Persistence](#volume-persistence)
- [Building Multi-Architecture Images](#building-multi-architecture-images)
- [CI/CD Workflow](#cicd-workflow)
- [Security Considerations](#security-considerations)

---

## Overview

The `gcp-devops-toolbox` acts as an isolated, reproducible environment for managing infrastructure, Kubernetes clusters, and cloud resources without polluting your local operating system with multiple CLI tool installations.

---

## Included Tools

| Category | Tool | Version |
| --- | --- | --- |
| **Base OS** | Debian Bookworm / Python | 3.12 (Slim) |
| **Cloud** | Google Cloud SDK | 568.0.0 |
| **Infrastructure** | HashiCorp Terraform | 1.15.3 |
| **Orchestration** | kubectl | v1.32.0 |
| **Containerization** | Docker CLI | Latest Stable |
| **Source Control** | GitHub CLI / Git | Latest Stable |

---

## How to Use

### 1. Starting the Container

![compose-infra](https://storage.googleapis.com/gabrielkheisa/media/gcp-devops-toolbox-compose-diagram-3573498573457893457.png)

Because `docker-compose.yml` configures `tty: true` and `stdin_open: true`, running `docker compose up -d` will start the `devops-workspace` container detached in the background without exiting immediately.

```bash
docker compose up -d
```

Verify that the container is running:

```bash
docker compose ps
```

---

### 2. Attaching to the Interactive Shell

![flows](https://storage.googleapis.com/gabrielkheisa/media/gcp-devops-toolbox-flows-3573498573457893457.png?)


To enter the running container and access an interactive bash terminal with all tools available:

```bash
docker exec -it devops-workspace bash
```

Once inside, your local directory will be mounted directly at `/workspace`. Any changes made in `/workspace` will reflect instantly on your host machine.

---

### 3. Authenticating Your Tools

Because credentials persist across sessions via named Docker volumes, you only need to perform these login steps once inside the interactive shell:

#### Google Cloud SDK
```bash
gcloud auth login
gcloud auth application-default login
gcloud container clusters get-credentials CLUSTER_NAME --region REGION --project PROJECT_ID
```

#### GitHub CLI
```bash
gh auth login
```

#### Docker CLI
```bash
docker login ghcr.io
```

---

### 4. Executing Commands Directly

If you prefer not to open an interactive session, you can run commands directly from your host terminal using `docker exec`:

#### Terraform Execution
```bash
docker exec -it devops-workspace terraform plan
docker exec -it devops-workspace terraform apply
```

#### Kubernetes Queries
```bash
docker exec -it devops-workspace kubectl get pods -A
```

#### Google Cloud Operations
```bash
docker exec -it devops-workspace gcloud compute instances list
```

---

### 5. Stopping and Cleaning Up

To stop the background container without deleting persistent configuration volumes:

```bash
docker compose stop
```

To stop and remove the container instance completely:

```bash
docker compose down
```

*Note: Persistent data in `gcloud-config`, `gh-config`, and `kube-config` will remain intact for the next time you start the container.*

---

## Volume Persistence

The container uses Docker volumes and bind mounts to ensure your work and credentials are retained across restarts:

* **`/workspace`**: Bind-mounted to your current local directory (`.`) for live file sync.
* **`/root/.config/gcloud`**: Named volume (`gcloud-config`) persisting GCP login states.
* **`/root/.config/gh`**: Named volume (`gh-config`) persisting GitHub CLI credentials.
* **`/root/.kube`**: Named volume (`kube-config`) persisting Kubernetes cluster contexts.
* **`/root/.ssh`**: Read-only bind mount (`~/.ssh`) utilizing your host SSH keys for Git operations.
* **`/var/run/docker.sock`**: Bind mount connecting the container to the host Docker daemon.

---

## Building Multi-Architecture Images

![cicd](https://storage.googleapis.com/gabrielkheisa/media/gcp-devops-toolbox-cicd-3573498573457893457.png)

To build and push `gcp-devops-toolbox` for both `linux/amd64` and `linux/arm64` using Docker Buildx:

1. **Initialize Buildx:**
   ```bash
   docker buildx create --name multiarch-builder --use
   docker buildx inspect --bootstrap
   ```

2. **Authenticate to GHCR:**
   ```bash
   echo $GHCR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
   ```

3. **Build and Push:**
   ```bash
   docker buildx build \
     --platform linux/amd64,linux/arm64 \
     -t ghcr.io/YOUR_GITHUB_USER_OR_ORG/gcp-devops-toolbox:1.0 \
     -t ghcr.io/YOUR_GITHUB_USER_OR_ORG/gcp-devops-toolbox:latest \
     --push \
     .
   ```

---

## CI/CD Workflow

Automated multi-architecture builds are handled via GitHub Actions. Pushing a commit to the `main` branch or pushing a semantic tag (`v1.0.0`) triggers `.github/workflows/docker-publish.yml`, which builds and publishes the image to GitHub Container Registry (`ghcr.io`).

---

## Security Considerations

1. **Docker Socket Access:** Mounting `/var/run/docker.sock` exposes the host Docker daemon to the container, which grants root-level privileges on the host OS. Limit host socket access to trusted local development environments.
2. **SSH Mounts:** Host SSH keys are mounted as read-only (`:ro`) to prevent accidental modification or removal by scripts inside the container.
3. **Secret Isolation:** No tokens, service account keys, or passwords are baked into the Dockerfile image layers.