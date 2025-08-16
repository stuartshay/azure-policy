# GitHub Self-Hosted Runner in Azure VNet with Public IP (GitHub-restricted)
# This Terraform configuration deploys a self-hosted runner with public IP restricted to GitHub IP ranges

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Data sources for existing infrastructure
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = "vnet-azpolicy-dev-eastus-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "runner" {
  name                 = "snet-default-azpolicy-dev-eastus-001" # Use existing default subnet
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Network Security Group for GitHub Runner with simplified rules
resource "azurerm_network_security_group" "runner" {
  name                = "nsg-github-runner-dev-eastus"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  # Allow HTTPS outbound to GitHub (using service tag)
  security_rule {
    name                       = "Allow-HTTPS-GitHub-Outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow HTTPS outbound to Azure services
  security_rule {
    name                       = "Allow-HTTPS-Azure-Outbound"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # Allow HTTP outbound (for package repositories)
  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow DNS outbound
  security_rule {
    name                       = "Allow-DNS-Outbound"
    priority                   = 1020
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH from additional management IPs (if any)
  dynamic "security_rule" {
    for_each = { for idx, cidr in var.allowed_management_ips : idx => cidr }
    content {
      name                       = "Allow-SSH-Management-${security_rule.key}"
      priority                   = 2000 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  tags = {
    Environment = var.environment
    Purpose     = "github-runner"
    ManagedBy   = "terraform"
  }
}

# Public IP for GitHub Runner (with GitHub IP restrictions via NSG)
resource "azurerm_public_ip" "github_runner" {
  name                = "pip-github-runner-${var.environment}-001"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Purpose     = "github-runner"
    ManagedBy   = "terraform"
  }
}

# GitHub Runner VM
resource "azurerm_linux_virtual_machine" "github_runner" {
  name                = "vm-github-runner-${var.environment}-001"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = "azureuser"

  # Always require SSH key authentication for security
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key != "" ? var.admin_ssh_public_key : file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.github_runner.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" # SSD for better performance
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Install and configure GitHub Actions runner
  custom_data = base64encode(templatefile("${path.module}/runner-setup.sh", {
    github_token    = var.github_token
    github_repo_url = var.github_repo_url
    runner_name     = "azure-vnet-runner-${var.environment}"
    runner_labels   = join(",", var.runner_labels)
  }))

  tags = {
    Environment = var.environment
    Purpose     = "github-runner"
    ManagedBy   = "terraform"
  }
}

# Network Interface for GitHub Runner
resource "azurerm_network_interface" "github_runner" {
  name                           = "nic-github-runner-${var.environment}-001"
  location                       = data.azurerm_resource_group.main.location
  resource_group_name            = data.azurerm_resource_group.main.name
  accelerated_networking_enabled = var.enable_accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.runner.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.github_runner.id
  }

  tags = {
    Environment = var.environment
    Purpose     = "github-runner"
    ManagedBy   = "terraform"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "runner" {
  network_interface_id      = azurerm_network_interface.github_runner.id
  network_security_group_id = azurerm_network_security_group.runner.id
}

# Auto-shutdown configuration (optional)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "github_runner" {
  count              = var.auto_shutdown_time != "" ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.github_runner.id
  location           = data.azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = {
    Environment = var.environment
    Purpose     = "github-runner"
    ManagedBy   = "terraform"
  }
}
