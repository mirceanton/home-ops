resource "kubernetes_namespace_v1" "example" {
  metadata {
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
	  "pod-security.kubernetes.io/audit" = "privileged"
	  "pod-security.kubernetes.io/warn" = "privileged"
    }

    name = "cilium-system"
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.14.2"
  namespace = kubernetes_namespace_v1.example.metadata[0].name
  wait = true

  values = [
    "${file("${path.module}/files/cilium-values.yaml")}"
  ]
}

resource "helm_release" "coredns" {
  name       = "coredns"
  repository = "https://coredns.github.io/helm/"
  chart      = "coredns"
  version    = "1.26.0"
  namespace = "kube-system"
  wait = true

  values = [
    "${file("${path.module}/files/coredns-values.yaml")}"
  ]
}
