# Monitoring Module

This Terraform module creates a comprehensive monitoring solution for Azure resources using Log Analytics Workspace, Application Insights, and Azure Monitor.

## Features

- **Log Analytics Workspace** - Centralized logging and metrics collection
- **Application Insights** - Workspace-based application performance monitoring
- **Azure Monitor Alerts** - Metric alerts, log query alerts, and activity log alerts
- **Action Groups** - Email, SMS, and webhook notifications
- **Smart Detection** - AI-powered anomaly detection
- **Cost Management** - Budget alerts and cost optimization
- **Security** - Private endpoints and diagnostic settings

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  # Required variables
  resource_group_name = "rg-myapp-dev-eastus"
  location           = "East US"
  workload           = "myapp"
  environment        = "dev"
  location_short     = "eastus"
  subscription_id    = "12345678-1234-1234-1234-123456789012"

  # Notification configuration
  notification_emails = {
    admin = "admin@company.com"
    team  = "team@company.com"
  }

  # Function Apps to monitor
  monitored_function_apps = {
    basic = {
      resource_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/func-myapp-basic-dev-001"
      name        = "func-myapp-basic-dev-001"
    }
    advanced = {
      resource_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/func-myapp-advanced-dev-001"
      name        = "func-myapp-advanced-dev-001"
    }
  }

  # Alert thresholds
  cpu_threshold          = 80
  memory_threshold       = 85
  error_threshold        = 10
  response_time_threshold = 5

  # Feature toggles
  enable_log_alerts         = true
  enable_activity_log_alerts = true
  enable_smart_detection    = true
  enable_workbook          = true

  tags = {
    Environment = "dev"
    Project     = "myapp"
    Owner       = "platform-team"
  }
}
```

## Resources Created

### Core Monitoring Resources
- `azurerm_log_analytics_workspace` - Central logging workspace
- `azurerm_application_insights` - Application performance monitoring
- `azurerm_monitor_action_group` - Notification action group

### Alert Rules
- `azurerm_monitor_metric_alert` - CPU, memory, errors, response time alerts
- `azurerm_monitor_scheduled_query_rules_alert_v2` - Log query alerts
- `azurerm_monitor_activity_log_alert` - Resource and service health alerts

### Optional Resources
- `azurerm_storage_account` - Monitoring data storage (if enabled)
- `azurerm_private_endpoint` - Private endpoint for Log Analytics (if enabled)
- `azurerm_application_insights_workbook` - Monitoring dashboard (if enabled)
- `azurerm_consumption_budget_resource_group` - Budget alerts (if enabled)

## Alert Types

### Metric Alerts
- **CPU Usage** - Triggers when CPU usage exceeds threshold
- **Memory Usage** - Triggers when memory usage exceeds threshold
- **HTTP Errors** - Triggers on high number of 5xx errors
- **Response Time** - Triggers when response time exceeds threshold

### Log Query Alerts
- **Function Exceptions** - High number of exceptions in Function Apps
- **Function Availability** - Function App availability issues
- **Function Performance** - Performance degradation detection

### Activity Log Alerts
- **Resource Health** - Resource health degradation
- **Service Health** - Azure service health issues

### Smart Detection
- **Failure Anomalies** - AI-detected failure patterns
- **Performance Anomalies** - AI-detected performance issues
- **Trace Severity** - Unusual trace patterns

## Configuration Options

### Log Analytics
- **SKU**: PerGB2018 (default), Free, PerNode, Standalone, Standard, Premium
- **Retention**: 30-730 days (default: 30)
- **Daily Quota**: Unlimited (default) or specific GB limit
- **Reservation Capacity**: Cost optimization for high-volume workloads

### Application Insights
- **Sampling**: 1-100% (default: 100%)
- **Workspace-based**: Always enabled for better integration
- **IP Masking**: Disabled for dev, enabled for production

### Notifications
- **Email**: Multiple email addresses supported
- **SMS**: Country code and phone number
- **Webhooks**: HTTPS URLs for integration

### Alert Thresholds
All thresholds are configurable with sensible defaults:
- CPU: 80%
- Memory: 85%
- HTTP Errors: 10 errors
- Response Time: 5 seconds
- Exceptions: 5 exceptions
- Availability: 95%
- Performance: 5000ms

## Private Endpoints

When `enable_private_endpoints = true`, the module creates:
- Private endpoint for Log Analytics Workspace
- Private DNS zone integration
- Network security for monitoring traffic

## Cost Optimization

### Log Analytics
- **Commitment Tiers**: Use `reservation_capacity_gb` for predictable workloads
- **Daily Quota**: Set `daily_quota_gb` to control costs
- **Retention**: Adjust `log_retention_days` based on compliance needs

### Application Insights
- **Sampling**: Reduce `sampling_percentage` for high-volume applications
- **Data Retention**: Workspace-based retention follows Log Analytics settings

### Budget Alerts
Enable `enable_budget_alerts` to monitor spending:
- 80% threshold warning
- 100% threshold critical alert

## Integration with Function Apps

The module is designed to integrate with Azure Function Apps:

1. **Automatic Monitoring**: Function Apps automatically send telemetry
2. **Custom Metrics**: Support for custom application metrics
3. **Distributed Tracing**: End-to-end request tracking
4. **Performance Insights**: Detailed performance analysis

## Security Features

- **Private Endpoints**: Secure network access to monitoring resources
- **Diagnostic Settings**: Audit logs for monitoring infrastructure
- **RBAC Integration**: Works with Azure role-based access control
- **Data Encryption**: All data encrypted at rest and in transit

## Outputs

The module provides comprehensive outputs for integration:

### Essential Outputs
- `application_insights_connection_string` - For Function App configuration
- `application_insights_instrumentation_key` - Legacy instrumentation key
- `log_analytics_workspace_id` - For diagnostic settings

### Advanced Outputs
- `action_group_id` - For custom alert rules
- `monitoring_configuration` - Complete configuration summary
- `resource_names` - All created resource names

## Examples

### Basic Monitoring
```hcl
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = "rg-myapp-dev-eastus"
  location           = "East US"
  workload           = "myapp"
  environment        = "dev"
  location_short     = "eastus"
  subscription_id    = var.subscription_id

  notification_emails = {
    admin = "admin@company.com"
  }

  tags = var.common_tags
}
```

### Production Monitoring with Cost Optimization
```hcl
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = "rg-myapp-prod-eastus"
  location           = "East US"
  workload           = "myapp"
  environment        = "prod"
  location_short     = "eastus"
  subscription_id    = var.subscription_id

  # Cost optimization
  log_retention_days      = 90
  daily_quota_gb         = 10
  reservation_capacity_gb = 100
  sampling_percentage    = 50

  # Enhanced notifications
  notification_emails = {
    admin    = "admin@company.com"
    oncall   = "oncall@company.com"
    platform = "platform@company.com"
  }

  notification_sms = {
    oncall = {
      country_code = "1"
      phone_number = "5551234567"
    }
  }

  # Stricter thresholds
  cpu_threshold    = 70
  memory_threshold = 80
  error_threshold  = 5

  # Full feature set
  enable_budget_alerts       = true
  enable_private_endpoints   = true
  enable_availability_tests  = true
  enable_workspace_diagnostics = true

  budget_amount = 500
  budget_notification_emails = ["finance@company.com"]

  tags = var.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| azurerm | ~> 4.40 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.40 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for resources | `string` | n/a | yes |
| workload | Name of the workload or application | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| location_short | Short name for the location | `string` | n/a | yes |
| subscription_id | Azure subscription ID | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| notification_emails | Map of email addresses for notifications | `map(string)` | `{}` | no |
| monitored_function_apps | Map of Function Apps to monitor | `map(object)` | `{}` | no |
| cpu_threshold | CPU usage threshold for alerts (percentage) | `number` | `80` | no |
| memory_threshold | Memory usage threshold for alerts (percentage) | `number` | `85` | no |
| enable_log_alerts | Enable log query alerts | `bool` | `true` | no |
| enable_smart_detection | Enable Application Insights smart detection | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| application_insights_connection_string | Connection string for Application Insights |
| application_insights_instrumentation_key | Instrumentation key for Application Insights |
| log_analytics_workspace_id | ID of the Log Analytics Workspace |
| action_group_id | ID of the monitoring action group |
| monitoring_configuration | Summary of monitoring configuration |

## License

This module is part of the Azure Policy project and follows the same license terms.

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

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_application_insights.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_application_insights_smart_detection_rule.failure_anomalies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.performance_anomalies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_smart_detection_rule.trace_severity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_smart_detection_rule) | resource |
| [azurerm_application_insights_workbook.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights_workbook) | resource |
| [azurerm_consumption_budget_resource_group.monitoring](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/consumption_budget_resource_group) | resource |
| [azurerm_log_analytics_solution.security_center](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution) | resource |
| [azurerm_log_analytics_solution.updates](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution) | resource |
| [azurerm_log_analytics_workspace.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_action_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_activity_log_alert.resource_health](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.service_health](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_data_collection_rule.vm_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
| [azurerm_monitor_diagnostic_setting.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.app_insights_availability](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.function_app_cpu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.function_app_errors](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.function_app_memory](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.function_app_response_time](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.function_availability](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.function_exceptions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.function_performance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_private_endpoint.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_storage_account.monitoring](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_threshold"></a> [availability\_threshold](#input\_availability\_threshold) | Availability percentage threshold | `number` | `95` | no |
| <a name="input_budget_amount"></a> [budget\_amount](#input\_budget\_amount) | Budget amount for monitoring resources | `number` | `100` | no |
| <a name="input_budget_notification_emails"></a> [budget\_notification\_emails](#input\_budget\_notification\_emails) | List of email addresses for budget notifications | `list(string)` | `[]` | no |
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
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_error_threshold"></a> [error\_threshold](#input\_error\_threshold) | Number of HTTP errors to trigger alert | `number` | `10` | no |
| <a name="input_exception_threshold"></a> [exception\_threshold](#input\_exception\_threshold) | Number of exceptions to trigger alert | `number` | `5` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resources | `string` | n/a | yes |
| <a name="input_location_short"></a> [location\_short](#input\_location\_short) | Short name for the location | `string` | n/a | yes |
| <a name="input_log_analytics_sku"></a> [log\_analytics\_sku](#input\_log\_analytics\_sku) | SKU for Log Analytics Workspace | `string` | `"PerGB2018"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs in Log Analytics | `number` | `30` | no |
| <a name="input_memory_threshold"></a> [memory\_threshold](#input\_memory\_threshold) | Memory usage threshold for alerts (percentage) | `number` | `85` | no |
| <a name="input_monitored_function_apps"></a> [monitored\_function\_apps](#input\_monitored\_function\_apps) | Map of Function Apps to monitor | <pre>map(object({<br/>    resource_id = string<br/>    name        = string<br/>  }))</pre> | `{}` | no |
| <a name="input_notification_emails"></a> [notification\_emails](#input\_notification\_emails) | Map of email addresses for notifications | `map(string)` | `{}` | no |
| <a name="input_notification_sms"></a> [notification\_sms](#input\_notification\_sms) | Map of SMS numbers for notifications | <pre>map(object({<br/>    country_code = string<br/>    phone_number = string<br/>  }))</pre> | `{}` | no |
| <a name="input_notification_webhooks"></a> [notification\_webhooks](#input\_notification\_webhooks) | Map of webhook URLs for notifications | `map(string)` | `{}` | no |
| <a name="input_performance_threshold"></a> [performance\_threshold](#input\_performance\_threshold) | Performance threshold in milliseconds | `number` | `5000` | no |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | List of private DNS zone IDs | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | Subnet ID for private endpoints | `string` | `null` | no |
| <a name="input_reservation_capacity_gb"></a> [reservation\_capacity\_gb](#input\_reservation\_capacity\_gb) | Reservation capacity in GB per day for cost optimization | `number` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_response_time_threshold"></a> [response\_time\_threshold](#input\_response\_time\_threshold) | Response time threshold in seconds | `number` | `5` | no |
| <a name="input_sampling_percentage"></a> [sampling\_percentage](#input\_sampling\_percentage) | Sampling percentage for Application Insights | `number` | `100` | no |
| <a name="input_smart_detection_emails"></a> [smart\_detection\_emails](#input\_smart\_detection\_emails) | List of email addresses for smart detection notifications | `list(string)` | `[]` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_workload"></a> [workload](#input\_workload) | Name of the workload or application | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_action_group_id"></a> [action\_group\_id](#output\_action\_group\_id) | ID of the monitoring action group |
| <a name="output_action_group_name"></a> [action\_group\_name](#output\_action\_group\_name) | Name of the monitoring action group |
| <a name="output_action_group_short_name"></a> [action\_group\_short\_name](#output\_action\_group\_short\_name) | Short name of the monitoring action group |
| <a name="output_activity_log_alert_ids"></a> [activity\_log\_alert\_ids](#output\_activity\_log\_alert\_ids) | List of activity log alert IDs |
| <a name="output_application_insights_app_id"></a> [application\_insights\_app\_id](#output\_application\_insights\_app\_id) | App ID for Application Insights |
| <a name="output_application_insights_connection_string"></a> [application\_insights\_connection\_string](#output\_application\_insights\_connection\_string) | Connection string for Application Insights |
| <a name="output_application_insights_id"></a> [application\_insights\_id](#output\_application\_insights\_id) | ID of the Application Insights instance |
| <a name="output_application_insights_instrumentation_key"></a> [application\_insights\_instrumentation\_key](#output\_application\_insights\_instrumentation\_key) | Instrumentation key for Application Insights |
| <a name="output_application_insights_name"></a> [application\_insights\_name](#output\_application\_insights\_name) | Name of the Application Insights instance |
| <a name="output_budget_alert_id"></a> [budget\_alert\_id](#output\_budget\_alert\_id) | ID of the budget alert |
| <a name="output_log_alert_ids"></a> [log\_alert\_ids](#output\_log\_alert\_ids) | List of log query alert IDs |
| <a name="output_log_analytics_diagnostic_setting_id"></a> [log\_analytics\_diagnostic\_setting\_id](#output\_log\_analytics\_diagnostic\_setting\_id) | ID of the Log Analytics diagnostic setting |
| <a name="output_log_analytics_primary_shared_key"></a> [log\_analytics\_primary\_shared\_key](#output\_log\_analytics\_primary\_shared\_key) | Primary shared key for Log Analytics Workspace |
| <a name="output_log_analytics_private_endpoint_id"></a> [log\_analytics\_private\_endpoint\_id](#output\_log\_analytics\_private\_endpoint\_id) | ID of the Log Analytics private endpoint |
| <a name="output_log_analytics_private_endpoint_ip"></a> [log\_analytics\_private\_endpoint\_ip](#output\_log\_analytics\_private\_endpoint\_ip) | Private IP address of the Log Analytics private endpoint |
| <a name="output_log_analytics_secondary_shared_key"></a> [log\_analytics\_secondary\_shared\_key](#output\_log\_analytics\_secondary\_shared\_key) | Secondary shared key for Log Analytics Workspace |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | ID of the Log Analytics Workspace |
| <a name="output_log_analytics_workspace_id_key"></a> [log\_analytics\_workspace\_id\_key](#output\_log\_analytics\_workspace\_id\_key) | Workspace ID for Log Analytics |
| <a name="output_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#output\_log\_analytics\_workspace\_name) | Name of the Log Analytics Workspace |
| <a name="output_log_analytics_workspace_resource_id"></a> [log\_analytics\_workspace\_resource\_id](#output\_log\_analytics\_workspace\_resource\_id) | Resource ID of the Log Analytics Workspace |
| <a name="output_metric_alert_ids"></a> [metric\_alert\_ids](#output\_metric\_alert\_ids) | Map of metric alert IDs by function app |
| <a name="output_monitoring_configuration"></a> [monitoring\_configuration](#output\_monitoring\_configuration) | Summary of monitoring configuration |
| <a name="output_monitoring_storage_account_id"></a> [monitoring\_storage\_account\_id](#output\_monitoring\_storage\_account\_id) | ID of the monitoring storage account |
| <a name="output_monitoring_storage_account_name"></a> [monitoring\_storage\_account\_name](#output\_monitoring\_storage\_account\_name) | Name of the monitoring storage account |
| <a name="output_monitoring_storage_primary_connection_string"></a> [monitoring\_storage\_primary\_connection\_string](#output\_monitoring\_storage\_primary\_connection\_string) | Primary connection string for monitoring storage account |
| <a name="output_monitoring_workbook_id"></a> [monitoring\_workbook\_id](#output\_monitoring\_workbook\_id) | ID of the monitoring workbook |
| <a name="output_resource_names"></a> [resource\_names](#output\_resource\_names) | Names of created monitoring resources |
| <a name="output_security_center_solution_id"></a> [security\_center\_solution\_id](#output\_security\_center\_solution\_id) | ID of the Security Center solution |
| <a name="output_smart_detection_rule_ids"></a> [smart\_detection\_rule\_ids](#output\_smart\_detection\_rule\_ids) | List of smart detection rule IDs |
| <a name="output_update_management_solution_id"></a> [update\_management\_solution\_id](#output\_update\_management\_solution\_id) | ID of the Update Management solution |
| <a name="output_vm_insights_data_collection_rule_id"></a> [vm\_insights\_data\_collection\_rule\_id](#output\_vm\_insights\_data\_collection\_rule\_id) | ID of the VM Insights data collection rule |
<!-- END_TF_DOCS -->
