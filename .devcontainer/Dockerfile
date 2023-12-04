## ================================================================================================
## Utility versions
## ================================================================================================
ARG TERRAFORM_VERSION=1.6.5
ARG FLUX_VERSION=v2.1.2
ARG SOPS_VERSION=v3.8.1-alpine
ARG KUBECTL_VERSION=1.28.4
ARG K9S_VERSION=v0.28.2
ARG TALOSCTL_VERSION=v1.5.5
ARG HELM_VERSION=v3.13.1
ARG AGE_VERSION=v1.1.1
ARG TASKFILE_VERSION=v3.31.0
ARG DOCKER_VERSION=24.0.7-cli
ARG TALHELPER_VERSION=v1.15.0


## ================================================================================================
# "Build" stage for utilities with docker images already present
## ================================================================================================
FROM hashicorp/terraform:${TERRAFORM_VERSION} as terraform
FROM ghcr.io/getsops/sops:${SOPS_VERSION} as sops
FROM derailed/k9s:${K9S_VERSION} as k9s
FROM fluxcd/flux-cli:${FLUX_VERSION} as flux
FROM bitnami/kubectl:${KUBECTL_VERSION} as kubectl
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} as talosctl
FROM docker:${DOCKER_VERSION} as docker

## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine as taskfile
ARG TASKFILE_VERSION
RUN wget https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz && tar xvf task_linux_amd64.tar.gz && mv task /bin/task
RUN wget https://raw.githubusercontent.com/go-task/task/${TASKFILE_VERSION}/completion/bash/task.bash -O /task_completion.bash

FROM alpine as age
ARG AGE_VERSION
RUN wget https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz -O age.tar.gz && tar xvf age.tar.gz && mv age/age /bin/age && mv age/age-keygen /bin/age-keygen

FROM alpine as helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && tar xvf helm-${HELM_VERSION}-linux-amd64.tar.gz && mv linux-amd64/helm /bin/helm

FROM alpine as kswitcher
ARG KSWITCHER_VERSION
RUN wget https://raw.githubusercontent.com/mirceanton/kswitcher/${KSWITCHER_VERSION}/src/kswitcher.py -O /bin/kswitcher && chmod +x /bin/kswitcher

FROM alpine as talhelper
ARG TALHELPER_VERSION
RUN wget https://github.com/budimanjojo/talhelper/releases/download/${TALHELPER_VERSION}/talhelper_linux_amd64.tar.gz -O talhelper.tar.gz && tar xvf talhelper.tar.gz && mv talhelper /bin/talhelper


## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/base:debian AS workspace
ENV EDITOR=vim

# Install `sudo` and configure bash completion
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
	apt-get -y upgrade && \
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
RUN mkdir -p /etc/bash_completion.d

# Enable passwordless sudo :kek:
RUN echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY --from=k9s /bin/k9s /usr/local/bin/k9s
COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=age /bin/age /usr/local/bin/age
COPY --from=age /bin/age-keygen /usr/local/bin/age-keygen

# Install terraform and set up bash completion
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
RUN terraform -install-autocomplete

# Install talosctl and set up bash completion
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
RUN talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl.bash > /dev/null

# Install talhelper and set up bash completion
COPY --from=talhelper /bin/talhelper /usr/local/bin/talhelper
RUN talhelper completion bash | sudo tee /etc/bash_completion.d/talhelper.bash > /dev/null

# Install taskfile and set up bash completion
COPY --from=taskfile /bin/task /usr/local/bin/task
COPY --from=taskfile /task_completion.bash /etc/bash_completion.d/task.bash

# Install kubectl and set up bash completion
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
RUN kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null

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
