variable "talos_version" {
  description = "The version of Talos to install."
  type        = string
}

variable "talosconfig_file_path" {
  type = string
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      system_extensions = list(string)
    }))

    workers = map(object({
      system_extensions = list(string)
    }))
  })
}
