// TEMPLATE ONLY.
// This skeleton shows how a Packer vsphere-iso build can drive a Windows guest install.
// This is a vCenter path: datacenter and cluster inventory are required below.
// Do not treat free/standalone ESXi as a supported builder target. Create the VM
// manually and attach answer media when vCenter/licensed API automation is unavailable.

packer {
  required_plugins {
    vsphere = {
      version = "~> 1.4"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

variable "vcenter_server" {
  type        = string
  description = "vCenter Server endpoint; standalone ESXi is not supported by this template"
}

variable "username" {
  type        = string
  description = "API username"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "API password"
}

variable "insecure_connection" {
  type        = bool
  default     = false
  description = "Temporary opt-in only for a verified self-signed TLS exception."
}

variable "guest_winrm_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Guest communicator secret; keep separate from API credentials."
}

variable "datacenter" {
  type    = string
  default = "REPLACE_WITH_DATACENTER"
}

variable "cluster" {
  type    = string
  default = "REPLACE_WITH_CLUSTER"
}

variable "host" {
  type    = string
  default = "REPLACE_WITH_HOST"
}

variable "datastore" {
  type    = string
  default = "REPLACE_WITH_DATASTORE"
}

variable "network" {
  type    = string
  default = "REPLACE_WITH_NETWORK"
}

variable "iso_path" {
  type    = string
  default = "REPLACE_WITH_ISO_PATH"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:REPLACE_WITH_ISO_CHECKSUM"
}

variable "vm_name" {
  type    = string
  default = "win-template-vsphere-iso"
}

source "vsphere-iso" "windows" {
  vcenter_server      = var.vcenter_server
  username            = var.username
  password            = var.password
  insecure_connection = var.insecure_connection

  datacenter = var.datacenter
  cluster    = var.cluster
  host       = var.host
  datastore  = var.datastore
  vm_name    = var.vm_name

  guest_os_type   = "windows2019srv_64Guest"
  CPUs            = 2
  RAM             = 4096
  RAM_reserve_all = false
  disk_size       = 40960

  network_adapters {
    network      = var.network
    network_card = "vmxnet3"
  }

  iso_paths    = ["[${var.datastore}] iso/${var.iso_path}"]
  iso_checksum = var.iso_checksum

  communicator   = "winrm"
  winrm_username = "agent"
  winrm_password = var.guest_winrm_password
  winrm_timeout  = "6h"

  // Adapt these boot commands to the media layout you actually use.
  boot_wait    = "5s"
  boot_command = ["<spacebar>"]

  // If you generate an answer ISO or floppy image locally, document the attachment step here.
  shutdown_command    = "shutdown /s /t 10 /f"
  convert_to_template = false
}

build {
  sources = ["source.vsphere-iso.windows"]
}
