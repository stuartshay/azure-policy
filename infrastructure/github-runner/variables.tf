# Variables for GitHub Self-Hosted Runner with Public IP

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-azpolicy-dev-eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM access (leave empty to disable SSH key auth)"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub Personal Access Token for runner registration"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/stuartshay/azure-policy"
}

variable "vm_size" {
  description = "Size of the GitHub runner VM"
  type        = string
  default     = "Standard_B2s"
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_DS2_v2", "Standard_DS3_v2"
    ], var.vm_size)
    error_message = "VM size must be a supported size for GitHub runners."
  }
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking for the VM"
  type        = bool
  default     = false
}

variable "allowed_management_ips" {
  description = "Additional IP addresses allowed for SSH management (besides GitHub IPs)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for ip in var.allowed_management_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All management IPs must be valid CIDR blocks."
  }
}

variable "runner_labels" {
  description = "Labels to assign to the GitHub runner"
  type        = list(string)
  default     = ["azure", "vnet", "ubuntu", "self-hosted"]
}

variable "auto_shutdown_time" {
  description = "Time to auto-shutdown VM (HH:MM format, e.g., '23:00' for 11 PM)"
  type        = string
  default     = ""
  validation {
    condition     = var.auto_shutdown_time == "" || can(regex("^[0-2][0-9]:[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "Auto shutdown time must be in HH:MM format (24-hour) or empty to disable."
  }
}
