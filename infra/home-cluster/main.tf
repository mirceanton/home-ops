module "networking" {
  source = "./modules/networking"

  node_data = var.node_data
  cluster_vip = var.cluster_vip
  cluster_service_lb = var.cluster_service_lb
  mikrotik = var.mikrotik
}

module "talos-cluster" {
  source = "./modules/talos-cluster"
  depends_on = [ module.networking ]

  cluster_name = var.cluster_name
  node_data = var.node_data
  cluster_vip = var.cluster_vip
  kubernetes_version = var.kubernetes_version
  talos_version = var.talos_version
}

provider "helm" {
  kubernetes {
    config_path =  module.talos-cluster.kubeconfig_file_path
  }
}
provider "kubernetes" {
  config_path =  module.talos-cluster.kubeconfig_file_path
}


module "kubernetes-core-components" {
  source = "./modules/kubernetes-core-services"
  depends_on = [ module.talos-cluster ]
}

module "talos-upgrade" {
  source = "./modules/talos-upgrade"
  depends_on = [ module.kubernetes-core-components ]
  
  talos_version = var.talos_version
  talosconfig_file_path = module.talos-cluster.talosconfig_file_path
  node_data = var.node_data
}

# module "kubernetes-flux-bootstrap" {
#   source = "./modules/kubernetes-flux-bootstrap"
#   depends_on = [ module.talos-upgrade ]
  
# }
