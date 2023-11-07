## ================================================================================================
## Utility versions
## ================================================================================================
ARG TERRAFORM_VERSION=1.6.3
ARG FLUX_VERSION=v2.1.2
ARG SOPS_VERSION=v3.7.3-alpine
ARG KUBECTL_VERSION=1.28.3
ARG K9S_VERSION=v0.28.0
ARG TALOSCTL_VERSION=v1.5.4
ARG HELM_VERSION=v3.13.1
ARG KSWITCHER_VERSION=v1.0.0
ARG AGE_VERSION=v1.1.1
ARG TASKFILE_VERSION=v3.31.0
ARG HELMFILE_VERSION=v0.144.0 

## ================================================================================================
# "Build" stage for utilities with docker images already present
## ================================================================================================
FROM hashicorp/terraform:${TERRAFORM_VERSION} as terraform
FROM fluxcd/flux-cli:${FLUX_VERSION} as flux
FROM mozilla/sops:${SOPS_VERSION} as sops
FROM bitnami/kubectl:${KUBECTL_VERSION} as kubectl
FROM derailed/k9s:${K9S_VERSION} as k9s
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} as talosctl
FROM quay.io/roboll/helmfile:${HELMFILE_VERSION} as helmfile

## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine as taskfile
ARG TASKFILE_VERSION
RUN wget https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz && \
    tar xvf task_linux_amd64.tar.gz && \
    mv task /bin/task

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
FROM python:3.9.18-bookworm

# Copy binaries from the previous images to the Python image
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
COPY --from=taskfile /bin/task /usr/local/bin/task
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --from=helm /bin/helm /usr/local/bin/helm
COPY --from=helmfile /usr/local/bin/helmfile /usr/local/bin/helmfile
COPY --from=flux /usr/local/bin/flux /usr/local/bin/flux
COPY --from=k9s /bin/k9s /usr/local/bin/k9s
COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=age /bin/age /usr/local/bin/age
COPY --from=age /bin/age-keygen /usr/local/bin/age-keygen
COPY --from=kswitcher /bin/kswitcher /usr/local/bin/kswitcher

COPY requirements.txt ./
RUN pip3 install -r requirements.txt

ENTRYPOINT /bin/bash
