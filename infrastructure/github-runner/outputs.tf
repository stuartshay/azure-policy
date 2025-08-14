# GitHub Runner Module Outputs

output "vm_private_ip" {
  description = "Private IP address of the GitHub runner VM"
  value       = azurerm_linux_virtual_machine.github_runner.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the GitHub runner VM"
  value       = azurerm_public_ip.github_runner.ip_address
}

output "vm_name" {
  description = "Name of the GitHub runner VM"
  value       = azurerm_linux_virtual_machine.github_runner.name
}

output "resource_group_name" {
  description = "Name of the resource group containing the GitHub runner"
  value       = data.azurerm_resource_group.main.name
}

output "vm_id" {
  description = "ID of the GitHub runner VM"
  value       = azurerm_linux_virtual_machine.github_runner.id
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.runner.id
}
