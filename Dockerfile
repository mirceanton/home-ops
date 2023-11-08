## ================================================================================================
## Utility versions
## ================================================================================================
ARG TERRAFORM_VERSION=1.6.3
ARG FLUX_VERSION=v2.1.2
ARG SOPS_VERSION=v3.8.1-alpine
ARG KUBECTL_VERSION=1.28.3
ARG K9S_VERSION=v0.28.0
ARG TALOSCTL_VERSION=v1.5.4
ARG HELM_VERSION=v3.13.1
ARG KSWITCHER_VERSION=v1.0.0
ARG AGE_VERSION=v1.1.1
ARG TASKFILE_VERSION=v3.31.0
ARG HELMFILE_VERSION=v0.158.1



## ================================================================================================
# "Build" stage for utilities with docker images already present
## ================================================================================================
FROM hashicorp/terraform:${TERRAFORM_VERSION} as terraform
FROM ghcr.io/getsops/sops:${SOPS_VERSION} as sops
FROM derailed/k9s:${K9S_VERSION} as k9s
FROM fluxcd/flux-cli:${FLUX_VERSION} as flux
FROM bitnami/kubectl:${KUBECTL_VERSION} as kubectl
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} as talosctl
FROM ghcr.io/helmfile/helmfile:${HELMFILE_VERSION} as helmfile

## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine as taskfile
ARG TASKFILE_VERSION
RUN wget https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz && \
    tar xvf task_linux_amd64.tar.gz && \
    mv task /bin/task
RUN wget https://raw.githubusercontent.com/go-task/task/${TASKFILE_VERSION}/completion/bash/task.bash -O /task_completion.bash

FROM alpine as age
ARG AGE_VERSION
RUN wget https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz -O age.tar.gz && \
    tar xvf age.tar.gz && \
    mv age/age /bin/age && \
    mv age/age-keygen /bin/age-keygen

FROM alpine as helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar xvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /bin/helm

FROM alpine as kswitcher
ARG KSWITCHER_VERSION
RUN wget https://raw.githubusercontent.com/mirceanton/kswitcher/${KSWITCHER_VERSION}/src/kswitcher.py -O /bin/kswitcher

## ================================================================================================
## Main image
## ================================================================================================
FROM python:3.12.0-bookworm AS workspace
ARG UID=1000
ARG GID=1000
ARG USERNAME=mike
ENV EDITOR=vim

# Install `sudo` and configure bash completion
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
    sudo bash-completion #EDITOR
RUN mkdir -p /etc/bash_completion.d

# Create user with sudo privileges
RUN groupadd --gid ${GID} ${USERNAME} && \
    useradd --uid ${UID} --gid ${GID} --groups sudo --create-home --shell /bin/bash ${USERNAME}
# Disable sudo password
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set active user
USER ${UID}

# Create required subdirs in `~/`
RUN mkdir -p ~/.talos ~/.kube/configs

# Install python requirements
COPY requirements.txt ./
RUN pip3 install -r requirements.txt

COPY --from=k9s /bin/k9s /usr/local/bin/k9s
COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=age /bin/age /usr/local/bin/age
COPY --from=age /bin/age-keygen /usr/local/bin/age-keygen
COPY --from=kswitcher /bin/kswitcher /usr/local/bin/kswitcher

# Install terraform and set up bash completion
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
RUN terraform -install-autocomplete

# Install talosctl and set up bash completion
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
RUN talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl.bash > /dev/null

# Install taskfile and set up bash completion
COPY --from=taskfile /bin/task /usr/local/bin/task
COPY --from=taskfile /task_completion.bash /etc/bash_completion.d/task.bash

# Install kubectl and set up bash completion
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
RUN kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null

# Install helm and set up bash completion
COPY --from=helm /bin/helm /usr/local/bin/helm
RUN helm completion bash | sudo tee /etc/bash_completion.d/helm.bash > /dev/null

# Install helmfile and set up bash completion
COPY --from=helmfile /usr/local/bin/helmfile /usr/local/bin/helmfile
RUN helmfile completion bash | sudo tee /etc/bash_completion.d/helmfile.bash > /dev/null

# Install flux and set up bash completion
COPY --from=flux /usr/local/bin/flux /usr/local/bin/flux
RUN flux completion bash | sudo tee /etc/bash_completion.d/flux.bash > /dev/null

WORKDIR /workspace
ENTRYPOINT sleep infinity