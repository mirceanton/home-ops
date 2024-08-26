## ================================================================================================
# Utility versions
## ================================================================================================
ARG TERRAFORM_VERSION=1.9.5
ARG FLUX_VERSION=v2.3.0
ARG KUBECTL_VERSION=1.31.0
ARG SOPS_VERSION=v3.9.0-alpine
ARG K9S_VERSION=v0.32.4
ARG TALOSCTL_VERSION=v1.7.6
ARG HELM_VERSION=v3.13.3
ARG AGE_VERSION=v1.1.1
ARG TASKFILE_VERSION=v3.32.0
ARG KUSTOMIZE_VERSION=v5.4.3
ARG TALHELPER_VERSION=v3.0.5
ARG STERN_VERSION=1.30.0
ARG CILIUM_VERSION=v0.15.19
ARG KUBESWITCHER_VERSION=v1.0.2
ARG TALSWITCHER_VERSION=v1.1.0


## ================================================================================================
# "Build" stage for utilities with docker images already present
## ================================================================================================
FROM registry.k8s.io/kustomize/kustomize:${KUSTOMIZE_VERSION} AS kustomize
FROM bitnami/kubectl:${KUBECTL_VERSION} AS kubectl
FROM ghcr.io/stern/stern:${STERN_VERSION} AS stern
FROM fluxcd/flux-cli:${FLUX_VERSION} AS flux
FROM derailed/k9s:${K9S_VERSION} AS k9s
FROM ghcr.io/getsops/sops:${SOPS_VERSION} AS sops
FROM hashicorp/terraform:${TERRAFORM_VERSION} AS terraform
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} AS talosctl
FROM ghcr.io/budimanjojo/talhelper:${TALHELPER_VERSION} AS talhelper
FROM ghcr.io/mirceanton/kube-switcher:${KUBESWITCHER_VERSION} AS kubeswitcher
FROM ghcr.io/mirceanton/talswitcher:${TALSWITCHER_VERSION} AS talswitcher


## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine AS taskfile
ARG TASKFILE_VERSION
RUN wget https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz && tar xvf task_linux_amd64.tar.gz && mv task /bin/task
RUN wget https://raw.githubusercontent.com/go-task/task/${TASKFILE_VERSION}/completion/bash/task.bash -O /task_completion.bash

FROM alpine AS age
ARG AGE_VERSION
RUN wget https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz -O age.tar.gz && tar xvf age.tar.gz && mv age/age /bin/age && mv age/age-keygen /bin/age-keygen

FROM alpine AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && tar xvf helm-${HELM_VERSION}-linux-amd64.tar.gz && mv linux-amd64/helm /bin/helm

FROM alpine AS cilium
ARG CILIUM_VERSION
RUN wget https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VERSION}/cilium-linux-amd64.tar.gz -O cilium.tar.gz && tar xvf cilium.tar.gz && mv cilium /bin/cilium


## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye AS workspace
ENV EDITOR=vim

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && apt-get upgrade -y && \
	apt-get install -y \
	sudo \
	git \
	bash-completion \
	vim \
	curl \
	wget \
	unzip \
	htop \
	net-tools \
	iputils-ping \
	dnsutils && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Enable passwordless sudo :kek:
RUN echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install tools with no bash completion
COPY --from=k9s /bin/k9s /usr/local/bin/k9s
COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=age /bin/age /usr/local/bin/age
COPY --from=age /bin/age-keygen /usr/local/bin/age-keygen

# Install kustomize and set up bash completion
COPY --from=kustomize /app/kustomize /usr/local/bin/kustomize
RUN kustomize completion bash | sudo tee /etc/bash_completion.d/kustomize.bash > /dev/null

# Install cilium and set up bash completion
COPY --from=cilium /bin/cilium /usr/local/bin/cilium
RUN cilium completion bash | sudo tee /etc/bash_completion.d/cilium.bash > /dev/null

# Install stern and set up bash completion
COPY --from=stern /usr/local/bin/stern /usr/local/bin/stern
RUN stern --completion=bash | sudo tee /etc/bash_completion.d/stern.bash > /dev/null

# Install terraform and set up bash completion
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
RUN terraform -install-autocomplete

# Install talosctl and set up bash completion
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
RUN talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl.bash > /dev/null

# Install talhelper and set up bash completion
COPY --from=talhelper /usr/local/bin/talhelper /usr/local/bin/talhelper
RUN talhelper completion bash | sudo tee /etc/bash_completion.d/talhelper.bash > /dev/null

# Install talswitcher and set up bash completion
COPY --from=talswitcher /talswitcher /usr/local/bin/talswitcher
RUN talswitcher completion bash | sudo tee /etc/bash_completion.d/talswitcher.bash > /dev/null

# Install taskfile and set up bash completion
COPY --from=taskfile /bin/task /usr/local/bin/task
COPY --from=taskfile /task_completion.bash /etc/bash_completion.d/task.bash

# Install kubectl and set up bash completion
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
RUN kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null

# Install kubeswitcher as a kubectl plugin
COPY --from=kubeswitcher /kube-switcher /usr/local/bin/kubectl-switch
RUN kubectl switch completion bash | sudo tee /etc/bash_completion.d/kubectl-switch.bash > /dev/null

# Install helm and set up bash completion
COPY --from=helm /bin/helm /usr/local/bin/helm
RUN helm completion bash | sudo tee /etc/bash_completion.d/helm.bash > /dev/null

# Install flux and set up bash completion
COPY --from=flux /usr/local/bin/flux /usr/local/bin/flux
RUN flux completion bash | sudo tee /etc/bash_completion.d/flux.bash > /dev/null

# Install Docker
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/bin/docker-compose /usr/local/bin/docker-compose

USER vscode
WORKDIR /workspace
ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
