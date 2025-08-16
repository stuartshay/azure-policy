# Azure Service Bus Infrastructure

This Terraform module creates Azure Service Bus infrastructure for the Azure Policy project, including namespace, queues, topics, and subscriptions optimized for policy compliance workflows.

## Features

- **Service Bus Namespace** with configurable SKU (Basic, Standard, Premium)
- **Pre-configured Queues** for policy compliance workflows
- **Topics and Subscriptions** for pub/sub messaging patterns
- **Authorization Rules** for secure Function App integration
- **Private Endpoint Support** for enhanced security
- **Zone Redundancy** (Premium SKU only)
- **Dead Letter Queues** for message reliability

## Architecture

The Service Bus infrastructure is designed to support Azure Policy workflows:

```
┌─────────────────────────────────────────────────────────────┐
│ Service Bus Namespace                                       │
│                                                             │
│ ┌─────────────────────┐  ┌─────────────────────────────────┐ │
│ │ Queues              │  │ Topics & Subscriptions          │ │
│ │                     │  │                                 │ │
│ │ • policy-compliance │  │ • policy-events                 │ │
│ │ • policy-remediation│  │   └─ all-policy-events         │ │
│ │ • policy-audit-logs │  │ • compliance-reports            │ │
│ │ • policy-notifications│ │   └─ all-compliance-reports    │ │
│ │ • custom queues     │  │ • custom topics                 │ │
│ └─────────────────────┘  └─────────────────────────────────┘ │
│                                                             │
│ Authorization Rules:                                        │
│ • FunctionAppAccess (Listen, Send)                         │
│ • ReadOnlyAccess (Listen)                                  │
│ • AdminAccess (Listen, Send, Manage) [Optional]           │
└─────────────────────────────────────────────────────────────┘
```

## Default Messaging Entities

### Queues
- `policy-compliance-checks` - For compliance evaluation tasks
- `policy-remediation-tasks` - For remediation workflows
- `policy-audit-logs` - For audit logging and reporting
- `policy-notifications` - For alert and notification processing

### Topics
- `policy-events` - General policy-related events
- `compliance-reports` - Compliance reporting events

## Prerequisites

- Core infrastructure must be deployed (provides VNet for private endpoints)
- Resource group must exist

## Usage

```bash
# Initialize the workspace
make init

# Plan the deployment
make plan

# Deploy Service Bus
make apply

# Check status
make status
```

## Configuration

Key variables for Service Bus configuration:

- `service_bus_sku`: Service Bus tier ("Basic", "Standard", "Premium")
- `custom_queues`: Additional queues beyond defaults
- `custom_topics`: Additional topics beyond defaults
- `enable_private_endpoint`: Enable private endpoint for secure access
- `max_queue_size_mb`: Maximum queue size (1024-5120 MB)

## Function App Integration

The Service Bus is configured for seamless Azure Function integration:

1. **Connection String**: Available via `function_app_connection_string` output
2. **Authorization**: Dedicated `FunctionAppAccess` rule with listen/send permissions
3. **Queue Names**: Available via `queue_names` output for binding configuration
4. **Topics**: Available via `topic_names` output for pub/sub scenarios

### Example Function App Settings

```json
{
  "ServiceBusConnectionString": "<from terraform output>",
  "PolicyComplianceQueue": "policy-compliance-checks",
  "PolicyRemediationQueue": "policy-remediation-tasks",
  "PolicyEventsTopic": "policy-events"
}
```

## Security Features

- **Authorization Rules**: Granular access control
- **Private Endpoints**: Network isolation (when enabled)
- **RBAC Ready**: Compatible with managed identity authentication
- **TLS Encryption**: All communication encrypted in transit

## Monitoring and Observability

- **Dead Letter Queues**: Automatic dead lettering for failed messages
- **Message TTL**: Configurable time-to-live for messages
- **Duplicate Detection**: Built-in duplicate message handling
- **Azure Monitor Integration**: Metrics and logging support

## Cost Optimization

- **SKU Selection**: Choose appropriate tier (Basic < Standard < Premium)
- **Message Retention**: Configurable TTL to manage storage costs
- **Partitioning**: Optional for higher throughput (Standard/Premium)
- **Auto-delete**: Configurable idle cleanup

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.37 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.39.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.admin_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.function_app_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.namespace_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.read_only_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_private_endpoint.service_bus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_servicebus_namespace.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace) | resource |
| [azurerm_servicebus_namespace_authorization_rule.admin_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule) | resource |
| [azurerm_servicebus_namespace_authorization_rule.function_app_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule) | resource |
| [azurerm_servicebus_namespace_authorization_rule.read_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule) | resource |
| [azurerm_servicebus_queue.queues](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue) | resource |
| [azurerm_servicebus_subscription.compliance_reports_all](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_subscription) | resource |
| [azurerm_servicebus_subscription.policy_events_all](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_subscription) | resource |
| [azurerm_servicebus_topic.topics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic) | resource |
| [time_rotating.keyvault_secret_rotation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [azurerm_key_vault.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_delete_on_idle"></a> [auto\_delete\_on\_idle](#input\_auto\_delete\_on\_idle) | Auto delete queues/topics when idle for specified duration (ISO 8601) | `string` | `"P10675199DT2H48M5.4775807S"` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center for resource billing | `string` | `"development"` | no |
| <a name="input_create_admin_access_rule"></a> [create\_admin\_access\_rule](#input\_create\_admin\_access\_rule) | Create an admin access authorization rule | `bool` | `false` | no |
| <a name="input_custom_queues"></a> [custom\_queues](#input\_custom\_queues) | List of custom queue names to create in addition to default queues | `list(string)` | `[]` | no |
| <a name="input_custom_topics"></a> [custom\_topics](#input\_custom\_topics) | List of custom topic names to create in addition to default topics | `list(string)` | `[]` | no |
| <a name="input_default_message_ttl"></a> [default\_message\_ttl](#input\_default\_message\_ttl) | Default message time-to-live in ISO 8601 format | `string` | `"P14D"` | no |
| <a name="input_duplicate_detection_window"></a> [duplicate\_detection\_window](#input\_duplicate\_detection\_window) | Duplicate detection history time window in ISO 8601 format | `string` | `"PT10M"` | no |
| <a name="input_enable_duplicate_detection"></a> [enable\_duplicate\_detection](#input\_enable\_duplicate\_detection) | Enable duplicate detection for queues and topics | `bool` | `true` | no |
| <a name="input_enable_keyvault_integration"></a> [enable\_keyvault\_integration](#input\_enable\_keyvault\_integration) | Enable storing Service Bus connection strings in Key Vault | `bool` | `false` | no |
| <a name="input_enable_partitioning"></a> [enable\_partitioning](#input\_enable\_partitioning) | Enable partitioning for queues and topics | `bool` | `false` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Enable private endpoint for Service Bus | `bool` | `false` | no |
| <a name="input_enable_zone_redundancy"></a> [enable\_zone\_redundancy](#input\_enable\_zone\_redundancy) | Enable zone redundancy (Premium SKU only) | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name) | Name of the existing Key Vault | `string` | `""` | no |
| <a name="input_keyvault_resource_group_name"></a> [keyvault\_resource\_group\_name](#input\_keyvault\_resource\_group\_name) | Resource group name where the Key Vault exists | `string` | `""` | no |
| <a name="input_keyvault_secret_expiration_days"></a> [keyvault\_secret\_expiration\_days](#input\_keyvault\_secret\_expiration\_days) | Number of days until Key Vault secrets expire (30-365 days recommended) | `number` | `90` | no |
| <a name="input_keyvault_secret_names"></a> [keyvault\_secret\_names](#input\_keyvault\_secret\_names) | Names for the secrets to be stored in Key Vault | <pre>object({<br/>    namespace_connection_string    = optional(string, "servicebus-namespace-connection-string")<br/>    function_app_connection_string = optional(string, "servicebus-function-app-connection-string")<br/>    read_only_connection_string    = optional(string, "servicebus-read-only-connection-string")<br/>    admin_connection_string        = optional(string, "servicebus-admin-connection-string")<br/>  })</pre> | <pre>{<br/>  "admin_connection_string": "servicebus-admin-connection-string",<br/>  "function_app_connection_string": "servicebus-function-app-connection-string",<br/>  "namespace_connection_string": "servicebus-namespace-connection-string",<br/>  "read_only_connection_string": "servicebus-read-only-connection-string"<br/>}</pre> | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resources | `string` | `"East US"` | no |
| <a name="input_max_delivery_count"></a> [max\_delivery\_count](#input\_max\_delivery\_count) | Maximum number of delivery attempts before dead lettering | `number` | `10` | no |
| <a name="input_max_queue_size_mb"></a> [max\_queue\_size\_mb](#input\_max\_queue\_size\_mb) | Maximum size of queues in megabytes | `number` | `1024` | no |
| <a name="input_max_topic_size_mb"></a> [max\_topic\_size\_mb](#input\_max\_topic\_size\_mb) | Maximum size of topics in megabytes | `number` | `1024` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources (team name or email) | `string` | `"platform-team"` | no |
| <a name="input_premium_messaging_units"></a> [premium\_messaging\_units](#input\_premium\_messaging\_units) | Number of premium messaging units (1-8, Premium SKU only) | `number` | `1` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group | `string` | n/a | yes |
| <a name="input_service_bus_sku"></a> [service\_bus\_sku](#input\_service\_bus\_sku) | SKU for the Service Bus namespace | `string` | `"Standard"` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_workload"></a> [workload](#input\_workload) | Name of the workload or application | `string` | `"azpolicy"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cost_optimization_info"></a> [cost\_optimization\_info](#output\_cost\_optimization\_info) | Information about cost optimization settings |
| <a name="output_function_app_connection_string"></a> [function\_app\_connection\_string](#output\_function\_app\_connection\_string) | Connection string for Function App access to Service Bus |
| <a name="output_function_app_connection_string_key_name"></a> [function\_app\_connection\_string\_key\_name](#output\_function\_app\_connection\_string\_key\_name) | Key name for Function App Service Bus access |
| <a name="output_keyvault_integration"></a> [keyvault\_integration](#output\_keyvault\_integration) | Key Vault integration information |
| <a name="output_private_endpoint_enabled"></a> [private\_endpoint\_enabled](#output\_private\_endpoint\_enabled) | Whether private endpoint is enabled |
| <a name="output_private_endpoint_ip"></a> [private\_endpoint\_ip](#output\_private\_endpoint\_ip) | Private endpoint IP address (if enabled) |
| <a name="output_queue_names"></a> [queue\_names](#output\_queue\_names) | List of created queue names |
| <a name="output_read_only_connection_string"></a> [read\_only\_connection\_string](#output\_read\_only\_connection\_string) | Read-only connection string for monitoring/reporting |
| <a name="output_service_bus_config_for_functions"></a> [service\_bus\_config\_for\_functions](#output\_service\_bus\_config\_for\_functions) | Service Bus configuration summary for Function App integration |
| <a name="output_service_bus_configuration"></a> [service\_bus\_configuration](#output\_service\_bus\_configuration) | Service Bus configuration details |
| <a name="output_service_bus_namespace_hostname"></a> [service\_bus\_namespace\_hostname](#output\_service\_bus\_namespace\_hostname) | Service Bus namespace hostname |
| <a name="output_service_bus_namespace_id"></a> [service\_bus\_namespace\_id](#output\_service\_bus\_namespace\_id) | ID of the Service Bus namespace |
| <a name="output_service_bus_namespace_name"></a> [service\_bus\_namespace\_name](#output\_service\_bus\_namespace\_name) | Name of the Service Bus namespace |
| <a name="output_service_bus_sku"></a> [service\_bus\_sku](#output\_service\_bus\_sku) | SKU of the Service Bus namespace |
| <a name="output_subscription_names"></a> [subscription\_names](#output\_subscription\_names) | Map of topic subscriptions |
| <a name="output_topic_names"></a> [topic\_names](#output\_topic\_names) | List of created topic names |
| <a name="output_zone_redundancy_enabled"></a> [zone\_redundancy\_enabled](#output\_zone\_redundancy\_enabled) | Whether zone redundancy is enabled |
<!-- END_TF_DOCS -->
