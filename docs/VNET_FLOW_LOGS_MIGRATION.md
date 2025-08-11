# VNet Flow Logs Migration Guide

## Overview

This guide covers the migration from NSG Flow Logs to VNet Flow Logs in response to Microsoft's announcement that NSG Flow Logs will be retired on September 30, 2027.

## Important Dates

- **June 30, 2025**: New NSG flow logs cannot be created
- **September 30, 2027**: NSG flow logs will be completely retired
- **Recommended Action**: Migrate to VNet flow logs immediately

## What Changed

### Before (NSG Flow Logs)
- Flow logs created per Network Security Group
- Limited to traffic filtered by NSG rules
- Multiple flow log resources to manage
- Storage container: `insights-logs-networksecuritygroupflowevent`

### After (VNet Flow Logs)
- Single flow log per Virtual Network
- Captures ALL traffic in the VNet (more comprehensive)
- Simplified management
- Enhanced metadata (Version 2)
- Storage container: `insights-logs-flowlog`

## Migration Steps

### 1. Update Terraform Configuration

The networking module has been updated to use VNet flow logs by default:

```hcl
# In your terraform configuration
module "networking" {
  source = "git::https://github.com/stuartshay/azure-policy.git//infrastructure/terraform/modules/networking?ref=develop"

  # ... other configuration ...

  # Enable VNet flow logs (recommended)
  enable_network_watcher = true
  enable_flow_logs       = true

  # Optional: Enable legacy NSG flow logs during transition
  enable_legacy_nsg_flow_logs = false  # Set to true only during migration
}
```

### 2. Deployment Strategy

#### Option A: Direct Migration (Recommended for new deployments)
```bash
# Deploy with VNet flow logs only
terraform plan
terraform apply
```

#### Option B: Parallel Deployment (For existing production systems)
```bash
# Step 1: Enable both VNet and legacy NSG flow logs
# Set enable_legacy_nsg_flow_logs = true in your configuration
terraform plan
terraform apply

# Step 2: Validate VNet flow logs are working
# Check storage containers and log data

# Step 3: Disable legacy NSG flow logs
# Set enable_legacy_nsg_flow_logs = false
terraform plan
terraform apply
```

### 3. Validation

After deployment, verify the VNet flow logs are working:

```bash
# Check VNet flow log resource
az network watcher flow-log show \
  --resource-group rg-azpolicy-dev-eastus \
  --name fl-vnet-azpolicy-dev

# Check storage container
az storage container list \
  --account-name stflowlogsazpolicydev001 \
  --query "[?name=='insights-logs-flowlog']"

# Verify log data is being written
az storage blob list \
  --account-name stflowlogsazpolicydev001 \
  --container-name insights-logs-flowlog
```

## Configuration Changes

### New Variables Added

```hcl
variable "enable_legacy_nsg_flow_logs" {
  description = "Enable legacy NSG flow logs alongside VNet flow logs (deprecated)"
  type        = bool
  default     = false
}
```

### Updated Resources

1. **VNet Flow Log**: `azurerm_network_watcher_flow_log.vnet`
   - Targets the entire VNet
   - Uses version 2 for enhanced metadata
   - Single resource per VNet

2. **Legacy NSG Flow Logs**: `azurerm_network_watcher_flow_log.nsg_legacy`
   - Optional backward compatibility
   - Marked as deprecated with tags
   - Will be removed in future versions

3. **Storage Containers**:
   - Primary: `insights-logs-flowlog` (VNet flow logs)
   - Legacy: `insights-logs-networksecuritygroupflowevent` (NSG flow logs)

## Benefits of VNet Flow Logs

### Enhanced Coverage
- Captures ALL traffic in the VNet
- Includes traffic that bypasses NSG rules
- Better visibility into inter-subnet communication

### Simplified Management
- One flow log per VNet instead of multiple per NSG
- Reduced complexity in Terraform configuration
- Easier monitoring and alerting setup

### Future-Proof
- Avoids service disruption from NSG flow log retirement
- Aligned with Microsoft's strategic direction
- Access to latest features and improvements

### Enhanced Metadata
- Version 2 flow logs provide additional information
- Better integration with analytics tools
- Improved troubleshooting capabilities

## Monitoring and Analytics

### Traffic Analytics
VNet flow logs work seamlessly with Traffic Analytics:

```hcl
enable_traffic_analytics = true
log_analytics_workspace_id = "/subscriptions/.../workspaces/..."
log_analytics_workspace_resource_id = "/subscriptions/.../workspaces/..."
```

### Log Queries
Update your Log Analytics queries to use the new VNet flow log format:

```kusto
// VNet Flow Logs query
AzureNetworkAnalytics_CL
| where SubType_s == "FlowLog" and ResourceType == "NetworkInterface"
| where FlowType_s == "ExternalPublic"
| project TimeGenerated, SrcIP_s, DestIP_s, SrcPort_d, DestPort_d, Protocol_s
```

## Troubleshooting

### Common Issues

1. **Flow logs not appearing**
   - Verify Network Watcher is enabled
   - Check storage account permissions
   - Ensure VNet has traffic to log

2. **Storage container not created**
   - Check Terraform apply output
   - Verify storage account exists
   - Check Azure RBAC permissions

3. **Legacy flow logs still running**
   - Set `enable_legacy_nsg_flow_logs = false`
   - Run `terraform apply` to remove them

### Validation Commands

```bash
# Check Network Watcher status
az network watcher list --query "[].{Name:name, Location:location, State:provisioningState}"

# List all flow logs
az network watcher flow-log list --location eastus

# Check storage account access
az storage account show --name stflowlogsazpolicydev001 --query "primaryEndpoints.blob"
```

## Cost Considerations

### VNet Flow Logs vs NSG Flow Logs
- **Storage**: Similar costs, potentially lower due to single flow log
- **Processing**: More efficient due to centralized logging
- **Analytics**: Same Traffic Analytics costs apply

### Optimization Tips
- Set appropriate retention periods (91-365 days)
- Use lifecycle policies for older data
- Monitor storage growth patterns

## Timeline and Action Items

### Immediate (Now - March 2025)
- [x] Update networking module to support VNet flow logs
- [x] Add backward compatibility for NSG flow logs
- [x] Update documentation and migration guide
- [ ] Test VNet flow logs in development environment

### Before June 2025
- [ ] Deploy VNet flow logs to all environments
- [ ] Validate log data and analytics
- [ ] Update monitoring dashboards and alerts
- [ ] Train operations team on new log format

### Before September 2027
- [ ] Remove all legacy NSG flow log configurations
- [ ] Clean up old storage containers
- [ ] Update disaster recovery procedures

## Support and Resources

### Microsoft Documentation
- [VNet Flow Logs Overview](https://docs.microsoft.com/en-us/azure/network-watcher/vnet-flow-logs-overview)
- [Migration Guide](https://docs.microsoft.com/en-us/azure/network-watcher/migrate-to-vnet-flow-logs)

### Internal Resources
- Terraform Module: `infrastructure/terraform/modules/networking/`
- Configuration: `infrastructure/core/main.tf`
- Outputs: Check `vnet_flow_log_id` and `vnet_flow_log_name`

### Getting Help
- Create GitHub issue for module-specific problems
- Contact Azure support for platform issues
- Review Terraform plan output for configuration validation

---

**Note**: This migration is mandatory due to Microsoft's retirement of NSG flow logs. Plan your migration well before the June 2025 cutoff date to avoid service disruptions.
