variable "talosconfig_content" {
  description = "Content of the talosconfig file"
  type        = string
  default     = ""
  sensitive   = true
}

variable "talosconfig_save_path" {
  description = "Path to save the talosconfig file. If empty, the file will not be saved."
  type        = string
  default     = ""
}

variable "kubeconfig_content" {
  description = "Content of the kubeconfig file"
  type        = string
  default     = ""
  sensitive   = true
}

variable "kubeconfig_save_path" {
  description = "Path to save the kubeconfig file. If empty, the file will not be saved."
  type        = string
  default     = ""
}
