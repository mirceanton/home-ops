<div align="center">
  <img src="https://raw.githubusercontent.com/mirceanton/home-ops/main/icon.png" align="center" width="144px" height="144px"/>
  <h3> My home operations repository </h3>
  <i>managed with Flux, Renovate and GitHub Actions</i> 🤖
</div>

---

## 📖 Overview

This is a monorepo for my homelab infrastructure automation. I try to adhere (as much as I reasonably can 😅) to Infrastructure as Code (IaC) and GitOps practices using the tools like `Terraform`, `Kubernetes`, `FluxCD`, `Renovate` and `GitHub Actions`.

### Directories

```sh
📁 .devcontainer        # Holds the configuration files for the devcontainer setup
📁 .github              # CI workflows and various tool configurations
📁 .taskfiles           # Holds all of the "modules" for my Taskfile automation
📁 scripts              # Various scripts used for automation, generally called within tasks
📁 terraform            # Terraform configuration for managing infrastructure outside of K8S
```

## ⭐ Stargazers

<div align="center">
    <a href="https://star-history.com/#mirceanton/home-ops&Date">
        <img src="https://api.star-history.com/svg?repos=mirceanton/home-ops&type=Date">
    </a>
</div>

## 🤝 Gratitude and Thanks

There is a template over at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template).

Thanks to all the people who donate their time to the [Kubernetes @Home](https://discord.gg/k8s-at-home) Discord community. A lot of inspiration for my cluster comes from the people that have shared their clusters using the [k8s-at-home](https://github.com/topics/k8s-at-home) GitHub topic. Be sure to check out the [Kubernetes @Home search](https://nanne.dev/k8s-at-home-search/) for ideas on how to deploy applications or get ideas on what you can deploy.

## 📜 Changelog

See my _awful_ [commit history](https://github.com/mirceanton/home-ops/commits/main)
