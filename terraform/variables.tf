variable "external_network_name" {
  description = "Name of the external/floating-IP network in your OpenStack — check Horizon > Network > Networks"
  type        = string
  default     = "public"  # change to match your env (e.g. "ext-net", "floating")
}

variable "app_cred_id" {
  description = "OpenStack application credential ID"
  type        = string
  sensitive   = true
}

variable "app_cred_secret" {
  description = "OpenStack application credential secret"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# ── Flavors (match names in your OpenStack)
variable "windows_flavor" {
  description = "Flavor for Windows server instances"
  type        = string
  default     = "m1.large"   # 4 vCPU / 8GB RAM recommended for Windows
}

variable "linux_flavor" {
  description = "Flavor for Linux service instances"
  type        = string
  default     = "m1.medium"  # 2 vCPU / 4GB RAM
}

variable "workstation_flavor" {
  description = "Flavor for blue team workstations"
  type        = string
  default     = "m1.small"
}

variable "red_flavor" {
  description = "Flavor for red team machines"
  type        = string
  default     = "m1.large"
}

# ── Image names (must match exactly what's uploaded in your OpenStack Glance)
variable "windows_2022_image" {
  description = "Windows Server 2022 image name in Glance"
  type        = string
  default     = "Windows-Server-2022"
}

variable "windows_2019_image" {
  description = "Windows Server 2019 image name in Glance"
  type        = string
  default     = "Windows-Server-2019"
}

variable "debian13_image" {
  description = "Debian 13 image name in Glance"
  type        = string
  default     = "Debian-13"
}

variable "rocky10_image" {
  description = "Rocky Linux 10 image name in Glance"
  type        = string
  default     = "Rocky-Linux-10"
}

variable "ubuntu_image" {
  description = "Ubuntu image for blue team workstations"
  type        = string
  default     = "Ubuntu-22.04"
}

variable "kali_image" {
  description = "Kali Linux image for red team machines"
  type        = string
  default     = "Kali-Linux-2024"
}
