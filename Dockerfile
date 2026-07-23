# Start with Python 3.12 on Bookworm Slim 
FROM python:3.12-slim-bookworm

# Set versions for pinning
# Consider updating it if it's too lagging behind
ARG GCLOUD_VERSION=568.0.0
ARG TERRAFORM_VERSION=1.15.3
ARG KUBECTL_VERSION=v1.32.0

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    WORKDIR=/workspace

# Combine all installations into one single RUN command
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    git \
    unzip \
    bzip2 \
    nano \
    jq \
    && mkdir -p -m 0755 /etc/apt/keyrings \
    # --- Install GitHub CLI ---
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    # --- Install Google Cloud SDK ---
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    # --- Setup Docker CLI Repository ---
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    # --- Sync and Install CLIs + GKE Auth Plugin + Docker CLI ---
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gh \
        google-cloud-cli=${GCLOUD_VERSION}-0 \
        google-cloud-cli-gke-gcloud-auth-plugin=${GCLOUD_VERSION}-0 \
        docker-ce-cli \
    # --- Install Terraform ---
    && curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$(dpkg --print-architecture).zip -o terraform.zip \
    && unzip terraform.zip -d /usr/local/bin/ \
    # --- Install kubectl ---
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl" \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    # --- Cleanup ---
    && rm -rf /var/lib/apt/lists/* terraform.zip \
    && apt-get clean

# Verify everything installs correctly during the build phase
RUN python3 --version \
    && pip3 --version \
    && gh --version \
    && terraform version \
    && gcloud --version \
    && kubectl version --client \
    && docker --version \
    && gzip --version

WORKDIR ${WORKDIR}
CMD ["/bin/bash"]