# Azure Functions Infrastructure Management

This Azure Function provides automated secret rotation for Service Bus authorization rules, updating the corresponding Key Vault secrets every 24 hours.

## Features

- **Automated Secret Rotation**: Timer-triggered function runs daily at midnight UTC
- **Service Bus Integration**: Rotates authorization rule keys for FunctionAppAccess and ReadOnlyAccess
- **Key Vault Integration**: Updates secrets with new connection strings
- **Health Monitoring**: Comprehensive health check endpoints
- **Manual Trigger**: API endpoint for manual secret rotation
- **Audit Logging**: Detailed logging for compliance and troubleshooting

## Functions

### ServiceBusSecretRotation
- **Type**: Timer Trigger
- **Schedule**: Daily at midnight UTC (`0 0 0 * * *`)
- **Purpose**: Rotates Service Bus authorization rule keys and updates Key Vault secrets

### Health Endpoints
- `GET /api/health` - Overall health check
- `GET /api/info` - Function information and configuration

### Management Endpoints
- `POST /api/rotate` - Manual trigger for secret rotation

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Required |
| `SERVICE_BUS_RESOURCE_GROUP` | Resource group containing Service Bus | `rg-azpolicy-dev-eastus` |
| `SERVICE_BUS_NAMESPACE` | Service Bus namespace name | `sb-azpolicy-dev-eastus-001` |
| `KEY_VAULT_URI` | Key Vault URI | Required |
| `ROTATION_ENABLED` | Enable/disable rotation | `true` |
| `ROTATE_ADMIN_ACCESS` | Include admin access rule | `false` |

### Authorization Rules Rotated

1. **FunctionAppAccess** - Send/Listen permissions
   - Secret: `servicebus-function-app-connection-string` <!-- pragma: allowlist secret -->
2. **ReadOnlyAccess** - Listen only permissions
   - Secret: `servicebus-read-only-connection-string` <!-- pragma: allowlist secret -->
3. **AdminAccess** - Full permissions (optional)
   - Secret: `servicebus-admin-connection-string` <!-- pragma: allowlist secret -->

## Security

### Required Permissions

The function app's managed identity requires:

1. **Service Bus Permissions**:
   - `Azure Service Bus Data Owner` role on the namespace
   - Or custom role with `Microsoft.ServiceBus/namespaces/authorizationRules/regenerateKeys/action`

2. **Key Vault Permissions**:
   - `Key Vault Secrets Officer` role
   - Or access policy with Get, Set, List permissions on secrets

### Rotation Process

1. Regenerate primary key for authorization rule
2. Wait 30 seconds for propagation
3. Update Key Vault secret with new primary connection string
4. Wait 5 minutes grace period
5. Regenerate secondary key
6. Wait 30 seconds for propagation

## Deployment

### Prerequisites

1. Service Bus namespace with authorization rules
2. Key Vault with appropriate access policies
3. Function App with system-assigned managed identity
4. Required RBAC roles assigned to managed identity

### Local Development

1. Copy `local.settings.json.template` to `local.settings.json`
2. Update configuration values
3. Install dependencies: `pip install -r requirements.txt`
4. Run locally: `func start`

### Production Deployment

Deploy using the GitHub Actions workflow with function type `infrastructure`.

## Monitoring

### Health Checks

- **Service Bus**: Tests connection to namespace and authorization rules
- **Key Vault**: Tests connection and secret access
- **Overall**: Combines all component health status

### Logging

All rotation activities are logged with:
- Rotation ID for tracking
- Timestamps and duration
- Success/failure status
- Error details for troubleshooting

### Alerts

Configure Azure Monitor alerts on:
- Function execution failures
- Health check failures
- Rotation duration exceeding thresholds

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Verify managed identity has required RBAC roles
   - Check Key Vault access policies

2. **Connection Failures**
   - Verify network connectivity if using private endpoints
   - Check firewall rules and VNet integration

3. **Rotation Failures**
   - Check Service Bus authorization rule existence
   - Verify Key Vault secret names match configuration

### Manual Recovery

If automatic rotation fails:
1. Use the manual rotation endpoint: `POST /api/rotate`
2. Check logs for specific error details
3. Verify permissions and connectivity
4. Manually rotate keys in Azure Portal if needed

## Testing

Run unit tests:
```bash
pip install -r requirements-test.txt
pytest tests/ -v --cov=.
```

## Version History

- **1.0.0**: Initial release with basic secret rotation functionality
