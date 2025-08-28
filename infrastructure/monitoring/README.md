# Monitoring Infrastructure

This directory contains the Terraform configuration for deploying comprehensive monitoring infrastructure using Azure Log Analytics, Application Insights, and Azure Monitor.

## Overview

The monitoring infrastructure provides:

- **Log Analytics Workspace** - Centralized logging and metrics collection
- **Application Insights** - Workspace-based application performance monitoring
- **Azure Monitor Alerts** - Comprehensive alerting for Function Apps
- **Action Groups** - Email, SMS, and webhook notifications
- **Smart Detection** - AI-powered anomaly detection
- **Monitoring Dashboard** - Custom workbook for visualization

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Infrastructure                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌──────────────────────────────┐   │
│  │ Log Analytics   │    │     Application Insights     │   │
│  │   Workspace     │◄───┤      (Workspace-based)      │   │
│  │                 │    │                              │   │
│  └─────────────────┘    └──────────────────────────────┘   │
│           ▲                           ▲                     │
│           │                           │                     │
│  ┌─────────────────┐    ┌──────────────────────────────┐   │
│  │ Function Apps   │    │      Azure Monitor           │   │
│  │ Diagnostic      │    │      - Metric Alerts         │   │
│  │ Settings        │    │      - Log Query Alerts      │   │
│  │                 │    │      - Activity Log Alerts   │   │
│  └─────────────────┘    └──────────────────────────────┘   │
│                                       │                     │
│                          ┌──────────────────────────────┐   │
│                          │      Action Groups           │   │
│                          │      - Email Notifications  │   │
│                          │      - SMS Notifications    │   │
│                          │      - Webhook Integration  │   │
│                          └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Core Infrastructure** - The core infrastructure must be deployed first
2. **Function Apps** - Function Apps should be deployed for monitoring integration
3. **Terraform Cloud** - Workspace `azure-policy-monitoring` must be configured
4. **Environment Variables** - `.env` file with required tokens

## Quick Start

1. **Initialize Terraform**:
   ```bash
   make init
   ```

2. **Review Configuration**:
   ```bash
   make show-config
   ```

3. **Plan Deployment**:
   ```bash
   make plan
   ```

4. **Deploy Infrastructure**:
   ```bash
   make apply
   ```

5. **Verify Deployment**:
   ```bash
   make integration-test
   ```

## Configuration

### Environment Variables


### Using the Example Configuration

An example configuration file is provided as `terraform.tfvars.example` in this directory. Copy it to `terraform.tfvars` and update the values as needed for your environment:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to match your Azure environment and notification settings
```

All required and optional variables are documented in the example file, including environment, resource group, notification settings, alert thresholds, feature toggles, and advanced options.

### Feature Toggles

Enable/disable features based on your needs:

```hcl
# Core Features
enable_log_alerts = true
enable_smart_detection = true
enable_workbook = true

# Optional Features
enable_budget_alerts = false
enable_private_endpoints = false
enable_availability_tests = false
```

## Monitoring Features

### Metric Alerts

- **CPU Usage** - Alerts when Function App CPU exceeds threshold
- **Memory Usage** - Alerts when Function App memory exceeds threshold
- **HTTP Errors** - Alerts on high number of 5xx errors
- **Response Time** - Alerts when response time exceeds threshold

### Log Query Alerts

- **Function Exceptions** - Detects high number of exceptions
- **Function Availability** - Monitors Function App availability
- **Function Performance** - Detects performance degradation

### Smart Detection

- **Failure Anomalies** - AI-detected failure patterns
- **Performance Anomalies** - AI-detected performance issues
- **Trace Severity** - Unusual trace patterns

### Activity Log Alerts

- **Resource Health** - Resource health degradation
- **Service Health** - Azure service health issues

## Integration with Function Apps

The monitoring infrastructure automatically integrates with existing Function Apps:

1. **Automatic Discovery** - Finds Function Apps by naming convention
2. **Diagnostic Settings** - Configures log forwarding to Log Analytics
3. **Application Insights** - Provides connection strings for Function Apps
4. **Custom Alerts** - Creates Function App-specific alerts

## Makefile Commands

### Basic Operations
```bash
make help          # Show all available commands
make init          # Initialize Terraform
make plan          # Plan changes
make apply         # Apply changes
make destroy       # Destroy resources
make output        # Show outputs
```

### Monitoring Specific
```bash
make status        # Show deployment status
make show-config   # Show current configuration
make test-alerts   # Test alert configuration
make integration-test  # Run integration tests
```

### Development
```bash
make dev-apply     # Apply with auto-approve
make dev-destroy   # Destroy with auto-approve
```

## Outputs

The infrastructure provides key outputs for integration:

```hcl
# For Function App Integration
application_insights_connection_string
application_insights_instrumentation_key

# For Diagnostic Settings
log_analytics_workspace_id

# For Custom Alerts
action_group_id

# For Reference
resource_names
monitoring_configuration
```

## Cost Optimization

### Log Analytics
- **Commitment Tiers** - Use `reservation_capacity_gb` for predictable workloads
- **Daily Quota** - Set `daily_quota_gb` to control ingestion costs
- **Retention** - Adjust `log_retention_days` based on compliance needs

### Application Insights
- **Sampling** - Reduce `sampling_percentage` for high-volume applications
- **Workspace-based** - Leverages Log Analytics pricing model

### Budget Alerts
Enable budget monitoring:
```hcl
enable_budget_alerts = true
budget_amount = 100
budget_notification_emails = ["finance@company.com"]
```

## Security

### Private Endpoints
For production environments, enable private endpoints:
```hcl
enable_private_endpoints = true
private_dns_zone_ids = [
  "/subscriptions/.../privateDnsZones/privatelink.monitor.azure.com"
]
```

### Diagnostic Settings
Audit logs for monitoring infrastructure:
```hcl
enable_workspace_diagnostics = true
```

## Troubleshooting

### Common Issues

1. **Function Apps Not Found**
   - Verify Function Apps are deployed
   - Check naming convention matches
   - Ensure resource group is correct

2. **Alerts Not Triggering**
   - Verify notification emails are correct
   - Check alert thresholds are appropriate
   - Ensure Function Apps are generating metrics

3. **High Costs**
   - Review Log Analytics ingestion
   - Consider enabling daily quota
   - Adjust sampling percentage

### Debugging Commands

```bash
# Check Terraform state
make output

# Validate configuration
make validate

# Test specific alerts
make test-alerts

# Check deployment status
make status
```

## Integration Examples

### Function App Configuration

After deploying monitoring, update Function Apps to use the new Application Insights:

```bash
# Get connection string
CONNECTION_STRING=$(cd infrastructure/monitoring && make output | grep application_insights_connection_string)

# Update Function App settings
az functionapp config appsettings set \
  --name "func-azpolicy-dev-001" \
  --resource-group "rg-azpolicy-dev-eastus" \
  --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$CONNECTION_STRING"
```

### Custom Alerts

Add custom alerts using the action group:

```hcl
resource "azurerm_monitor_metric_alert" "custom_alert" {
  name                = "custom-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_linux_function_app.custom.id]

  action {
    action_group_id = data.terraform_remote_state.monitoring.outputs.action_group_id
  }
}
```

## Deployment Workflow

1. **Deploy Core Infrastructure** first
2. **Deploy App Service Infrastructure**
3. **Deploy Function Apps**
4. **Deploy Monitoring Infrastructure** (this)
5. **Update Function Apps** to use new monitoring
6. **Test and Verify** monitoring is working

## Cleanup

To destroy the monitoring infrastructure:

```bash
# Review what will be destroyed
make plan -destroy

# Destroy resources
make destroy
```

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Terraform logs
3. Verify Azure resource status in the portal
4. Check the main project documentation

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values
- `Makefile` - Deployment commands
- `README.md` - This documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.40 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.40.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_monitoring"></a> [monitoring](#module\_monitoring) | ../terraform/modules/monitoring | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_diagnostic_setting.function_app_advanced](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.function_app_basic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.function_app_infrastructure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_linux_function_app.advanced](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/linux_function_app) | data source |
| [azurerm_linux_function_app.basic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/linux_function_app) | data source |
| [azurerm_linux_function_app.infrastructure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/linux_function_app) | data source |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_threshold"></a> [availability\_threshold](#input\_availability\_threshold) | Availability percentage threshold | `number` | `95` | no |
| <a name="input_budget_amount"></a> [budget\_amount](#input\_budget\_amount) | Budget amount for monitoring resources | `number` | `100` | no |
| <a name="input_budget_notification_emails"></a> [budget\_notification\_emails](#input\_budget\_notification\_emails) | List of email addresses for budget notifications | `list(string)` | `[]` | no |
| <a name="input_budget_start_date"></a> [budget\_start\_date](#input\_budget\_start\_date) | The start date for the budget period (format: YYYY-MM-DD or RFC3339). Required for budget alert time\_period. | `string` | `"2025-01-01"` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center for resource billing | `string` | `"development"` | no |
| <a name="input_cpu_threshold"></a> [cpu\_threshold](#input\_cpu\_threshold) | CPU usage threshold for alerts (percentage) | `number` | `80` | no |
| <a name="input_daily_quota_gb"></a> [daily\_quota\_gb](#input\_daily\_quota\_gb) | Daily ingestion quota in GB for Log Analytics (-1 for unlimited) | `number` | `-1` | no |
| <a name="input_enable_activity_log_alerts"></a> [enable\_activity\_log\_alerts](#input\_enable\_activity\_log\_alerts) | Enable activity log alerts | `bool` | `true` | no |
| <a name="input_enable_availability_tests"></a> [enable\_availability\_tests](#input\_enable\_availability\_tests) | Enable availability test alerts | `bool` | `false` | no |
| <a name="input_enable_budget_alerts"></a> [enable\_budget\_alerts](#input\_enable\_budget\_alerts) | Enable budget alerts | `bool` | `false` | no |
| <a name="input_enable_log_alerts"></a> [enable\_log\_alerts](#input\_enable\_log\_alerts) | Enable log query alerts | `bool` | `true` | no |
| <a name="input_enable_private_endpoints"></a> [enable\_private\_endpoints](#input\_enable\_private\_endpoints) | Enable private endpoints for monitoring resources | `bool` | `false` | no |
| <a name="input_enable_security_center"></a> [enable\_security\_center](#input\_enable\_security\_center) | Enable Security Center solution | `bool` | `true` | no |
| <a name="input_enable_smart_detection"></a> [enable\_smart\_detection](#input\_enable\_smart\_detection) | Enable Application Insights smart detection | `bool` | `true` | no |
| <a name="input_enable_storage_monitoring"></a> [enable\_storage\_monitoring](#input\_enable\_storage\_monitoring) | Enable storage account for monitoring data | `bool` | `false` | no |
| <a name="input_enable_update_management"></a> [enable\_update\_management](#input\_enable\_update\_management) | Enable Update Management solution | `bool` | `false` | no |
| <a name="input_enable_vm_insights"></a> [enable\_vm\_insights](#input\_enable\_vm\_insights) | Enable VM Insights data collection | `bool` | `false` | no |
| <a name="input_enable_workbook"></a> [enable\_workbook](#input\_enable\_workbook) | Enable monitoring workbook | `bool` | `true` | no |
| <a name="input_enable_workspace_diagnostics"></a> [enable\_workspace\_diagnostics](#input\_enable\_workspace\_diagnostics) | Enable diagnostic settings for Log Analytics workspace | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_error_threshold"></a> [error\_threshold](#input\_error\_threshold) | Number of HTTP errors to trigger alert | `number` | `10` | no |
| <a name="input_exception_threshold"></a> [exception\_threshold](#input\_exception\_threshold) | Number of exceptions to trigger alert | `number` | `5` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resources | `string` | `"East US"` | no |
| <a name="input_log_analytics_sku"></a> [log\_analytics\_sku](#input\_log\_analytics\_sku) | SKU for Log Analytics Workspace | `string` | `"PerGB2018"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs in Log Analytics | `number` | `30` | no |
| <a name="input_memory_threshold"></a> [memory\_threshold](#input\_memory\_threshold) | Memory usage threshold for alerts (percentage) | `number` | `85` | no |
| <a name="input_monitor_advanced_function"></a> [monitor\_advanced\_function](#input\_monitor\_advanced\_function) | Monitor the advanced Function App | `bool` | `true` | no |
| <a name="input_monitor_basic_function"></a> [monitor\_basic\_function](#input\_monitor\_basic\_function) | Monitor the basic Function App | `bool` | `true` | no |
| <a name="input_monitor_existing_functions"></a> [monitor\_existing\_functions](#input\_monitor\_existing\_functions) | Enable monitoring of existing Function Apps | `bool` | `true` | no |
| <a name="input_monitor_infrastructure_function"></a> [monitor\_infrastructure\_function](#input\_monitor\_infrastructure\_function) | Monitor the infrastructure Function App | `bool` | `false` | no |
| <a name="input_notification_emails"></a> [notification\_emails](#input\_notification\_emails) | Map of email addresses for notifications | `map(string)` | <pre>{<br/>  "admin": "admin@example.com"<br/>}</pre> | no |
| <a name="input_notification_sms"></a> [notification\_sms](#input\_notification\_sms) | Map of SMS numbers for notifications | <pre>map(object({<br/>    country_code = string<br/>    phone_number = string<br/>  }))</pre> | `{}` | no |
| <a name="input_notification_webhooks"></a> [notification\_webhooks](#input\_notification\_webhooks) | Map of webhook URLs for notifications | `map(string)` | `{}` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources (team name or email) | `string` | `"platform-team"` | no |
| <a name="input_performance_threshold"></a> [performance\_threshold](#input\_performance\_threshold) | Performance threshold in milliseconds | `number` | `5000` | no |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | List of private DNS zone IDs | `list(string)` | `[]` | no |
| <a name="input_reservation_capacity_gb"></a> [reservation\_capacity\_gb](#input\_reservation\_capacity\_gb) | Reservation capacity in GB per day for cost optimization | `number` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group | `string` | n/a | yes |
| <a name="input_response_time_threshold"></a> [response\_time\_threshold](#input\_response\_time\_threshold) | Response time threshold in seconds | `number` | `5` | no |
| <a name="input_sampling_percentage"></a> [sampling\_percentage](#input\_sampling\_percentage) | Sampling percentage for Application Insights | `number` | `100` | no |
| <a name="input_smart_detection_emails"></a> [smart\_detection\_emails](#input\_smart\_detection\_emails) | List of email addresses for smart detection notifications | `list(string)` | `[]` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_workload"></a> [workload](#input\_workload) | Name of the workload or application | `string` | `"azpolicy"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_action_group_id"></a> [action\_group\_id](#output\_action\_group\_id) | ID of the monitoring action group |
| <a name="output_action_group_name"></a> [action\_group\_name](#output\_action\_group\_name) | Name of the monitoring action group |
| <a name="output_activity_log_alert_ids"></a> [activity\_log\_alert\_ids](#output\_activity\_log\_alert\_ids) | List of activity log alert IDs |
| <a name="output_application_insights_app_id"></a> [application\_insights\_app\_id](#output\_application\_insights\_app\_id) | App ID for Application Insights |
| <a name="output_application_insights_connection_string"></a> [application\_insights\_connection\_string](#output\_application\_insights\_connection\_string) | Connection string for Application Insights |
| <a name="output_application_insights_id"></a> [application\_insights\_id](#output\_application\_insights\_id) | ID of the Application Insights instance |
| <a name="output_application_insights_instrumentation_key"></a> [application\_insights\_instrumentation\_key](#output\_application\_insights\_instrumentation\_key) | Instrumentation key for Application Insights |
| <a name="output_application_insights_name"></a> [application\_insights\_name](#output\_application\_insights\_name) | Name of the Application Insights instance |
| <a name="output_deployment_info"></a> [deployment\_info](#output\_deployment\_info) | Information about the monitoring deployment |
| <a name="output_log_alert_ids"></a> [log\_alert\_ids](#output\_log\_alert\_ids) | List of log query alert IDs |
| <a name="output_log_analytics_primary_shared_key"></a> [log\_analytics\_primary\_shared\_key](#output\_log\_analytics\_primary\_shared\_key) | Primary shared key for Log Analytics Workspace |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | ID of the Log Analytics Workspace |
| <a name="output_log_analytics_workspace_id_key"></a> [log\_analytics\_workspace\_id\_key](#output\_log\_analytics\_workspace\_id\_key) | Workspace ID for Log Analytics |
| <a name="output_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#output\_log\_analytics\_workspace\_name) | Name of the Log Analytics Workspace |
| <a name="output_log_analytics_workspace_resource_id"></a> [log\_analytics\_workspace\_resource\_id](#output\_log\_analytics\_workspace\_resource\_id) | Resource ID of the Log Analytics Workspace |
| <a name="output_metric_alert_ids"></a> [metric\_alert\_ids](#output\_metric\_alert\_ids) | Map of metric alert IDs by function app |
| <a name="output_monitored_function_apps"></a> [monitored\_function\_apps](#output\_monitored\_function\_apps) | Summary of monitored Function Apps |
| <a name="output_monitoring_configuration"></a> [monitoring\_configuration](#output\_monitoring\_configuration) | Summary of monitoring configuration |
| <a name="output_monitoring_integration"></a> [monitoring\_integration](#output\_monitoring\_integration) | Key outputs for integration with other infrastructure modules |
| <a name="output_resource_names"></a> [resource\_names](#output\_resource\_names) | Names of created monitoring resources |
| <a name="output_smart_detection_rule_ids"></a> [smart\_detection\_rule\_ids](#output\_smart\_detection\_rule\_ids) | List of smart detection rule IDs |
<!-- END_TF_DOCS -->
