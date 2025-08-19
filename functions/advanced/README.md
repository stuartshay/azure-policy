# Azure Functions - Advanced Timer with Service Bus Integration

An advanced Azure Functions application demonstrating timer-triggered functions with Azure Service Bus integration, comprehensive health monitoring, and production-ready features.

## Overview

This function app contains advanced Azure Functions that demonstrate:
- Timer-triggered functions with scheduled execution
- Azure Service Bus integration for message queuing
- Comprehensive health monitoring and diagnostics
- Error handling with retry logic
- Production-ready monitoring and observability
- Azure Functions v4 Python runtime

## Functions

### PolicyNotificationTimer
- **Trigger**: Timer (every 10 seconds)
- **Schedule**: `0/10 * * * * *` (CRON expression)
- **Description**: Sends structured messages to Service Bus policy-notifications queue

### HealthCheck
- **Trigger**: HTTP (GET)
- **Route**: `/api/health`
- **Description**: Comprehensive health check including Service Bus connectivity

### ServiceBusHealth
- **Trigger**: HTTP (GET)
- **Route**: `/api/health/servicebus`
- **Description**: Dedicated Service Bus connection health check

### FunctionInfo
- **Trigger**: HTTP (GET)
- **Route**: `/api/info`
- **Description**: Function app information and configuration details

### SendTestMessage
- **Trigger**: HTTP (POST)
- **Route**: `/api/test/send-message`
- **Description**: Manual endpoint to send test messages to Service Bus

## Prerequisites

- Python 3.13
- Azure Functions Core Tools v4
- Azure CLI (for deployment)
- Azure Service Bus namespace and queue
- Azure Storage Account (for function app storage)

## Service Bus Setup

### Create Service Bus Resources

1. **Create Service Bus Namespace**:
   ```bash
   az servicebus namespace create \
     --resource-group myResourceGroup \
     --name myServiceBusNamespace \
     --location westus \
     --sku Standard
   ```

2. **Create Queue**:
   ```bash
   az servicebus queue create \
     --resource-group myResourceGroup \
     --namespace-name myServiceBusNamespace \
     --name policy-notifications
   ```

3. **Get Connection String**:
   ```bash
   az servicebus namespace authorization-rule keys list \
     --resource-group myResourceGroup \
     --namespace-name myServiceBusNamespace \
     --name RootManageSharedAccessKey \
     --query primaryConnectionString \
     --output tsv
   ```

## Local Development

### Setup

1. **Install dependencies**:
   ```bash
   cd functions/advanced
   pip install -r requirements.txt
   ```

2. **Install development dependencies** (optional):
   ```bash
   pip install -r requirements-test.txt
   ```

3. **Configure local settings**:
   ```bash
   cp local.settings.json.template local.settings.json
   ```

4. **Update local.settings.json** with your Service Bus connection string:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "python",
       "AZURE_FUNCTIONS_ENVIRONMENT": "Development",
       "ServiceBusConnectionString": "Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=your-key",
       "PolicyNotificationsQueue": "policy-notifications"
     }
   }
   ```

### Running Locally

1. **Start Azurite** (for local storage emulation):
   ```bash
   azurite --silent --location azurite-data --debug azurite-data/debug.log
   ```

2. **Start the function app**:
   ```bash
   func start
   ```

The function app will be available at `http://localhost:7071`

## API Endpoints

### Health Check
```bash
curl http://localhost:7071/api/health
```

**Response Example**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-19T00:48:00.000Z",
  "service": "Azure Functions - Advanced Timer",
  "version": "1.0.0",
  "components": {
    "timer_function": {
      "status": "healthy",
      "message_counter": 42,
      "schedule": "every 10 seconds"
    },
    "service_bus": {
      "status": "healthy",
      "queue_name": "policy-notifications",
      "connection": "successful"
    },
    "configuration": {
      "queue_name": "policy-notifications",
      "connection_configured": true
    }
  }
}
```

### Service Bus Health Check
```bash
curl http://localhost:7071/api/health/servicebus
```

**Response Example**:
```json
{
  "timestamp": "2025-01-19T00:48:00.000Z",
  "service_bus": {
    "status": "healthy",
    "queue_name": "policy-notifications",
    "connection": "successful"
  },
  "configuration": {
    "queue_name": "policy-notifications",
    "connection_string_configured": true
  }
}
```

### Function Information
```bash
curl http://localhost:7071/api/info
```

**Response Example**:
```json
{
  "name": "Azure Functions - Advanced Timer with Service Bus",
  "description": "Timer-triggered function that sends messages to Service Bus every 10 seconds",
  "version": "1.0.0",
  "runtime": "Python 3.13",
  "framework": "Azure Functions v4",
  "functions": {
    "PolicyNotificationTimer": {
      "type": "timer",
      "schedule": "every 10 seconds",
      "description": "Sends messages to Service Bus policy-notifications queue",
      "message_counter": 42
    }
  },
  "endpoints": {
    "health": {
      "path": "/api/health",
      "methods": ["GET"],
      "description": "Comprehensive health check"
    },
    "servicebus_health": {
      "path": "/api/health/servicebus",
      "methods": ["GET"],
      "description": "Service Bus connection health check"
    },
    "info": {
      "path": "/api/info",
      "methods": ["GET"],
      "description": "Function app information"
    }
  },
  "configuration": {
    "service_bus_queue": "policy-notifications",
    "environment": "Development"
  },
  "timestamp": "2025-01-19T00:48:00.000Z"
}
```

### Send Test Message
```bash
# Send default test message
curl -X POST http://localhost:7071/api/test/send-message \
  -H "Content-Type: application/json"

# Send custom test message
curl -X POST http://localhost:7071/api/test/send-message \
  -H "Content-Type: application/json" \
  -d '{"custom_field": "custom_value", "test_data": "example"}'
```

**Response Example**:
```json
{
  "status": "success",
  "message": "Test message sent successfully",
  "message_id": "12345678-1234-1234-1234-123456789012",
  "queue": "policy-notifications",
  "timestamp": "2025-01-19T00:48:00.000Z"
}
```

## Timer Function Behavior

The `PolicyNotificationTimer` function:
- Runs every 10 seconds automatically
- Sends structured messages to the Service Bus queue
- Includes comprehensive metadata in each message
- Tracks message count and execution statistics
- Handles errors gracefully with detailed logging

### Message Structure

Each timer-generated message includes:
```json
{
  "id": "unique-uuid",
  "timestamp": "2025-01-19T00:48:00.000Z",
  "type": "policy-notification",
  "source": "timer-trigger",
  "iteration": 42,
  "data": {
    "message": "Scheduled policy notification check",
    "environment": "Development",
    "function_name": "PolicyNotificationTimer",
    "schedule": "every-10-seconds",
    "past_due": false,
    "next_occurrence": null
  }
}
```

## Testing

### Unit Tests
```bash
# Install test dependencies
pip install -r requirements-test.txt

# Run tests
pytest tests/
```

### Integration Testing

1. **Test Service Bus Connection**:
   ```bash
   curl http://localhost:7071/api/health/servicebus
   ```

2. **Send Test Message**:
   ```bash
   curl -X POST http://localhost:7071/api/test/send-message \
     -H "Content-Type: application/json" \
     -d '{"test": true}'
   ```

3. **Monitor Timer Function**:
   - Check function logs for timer executions
   - Verify messages appear in Service Bus queue
   - Monitor health endpoint for message counter

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `ServiceBusConnectionString` | Service Bus connection string | Yes | - |
| `PolicyNotificationsQueue` | Service Bus queue name | No | `policy-notifications` |
| `AZURE_FUNCTIONS_ENVIRONMENT` | Environment name | No | `Development` |

### Local Settings Template
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AZURE_FUNCTIONS_ENVIRONMENT": "Development",
    "ServiceBusConnectionString": "Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=your-key",
    "PolicyNotificationsQueue": "policy-notifications"
  }
}
```

### Host Configuration
The `host.json` file configures the function host with optimized settings for timer functions:

```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "excludedTypes": "Request"
      }
    }
  },
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

## Deployment

### Azure Deployment

1. **Create Function App**:
   ```bash
   az functionapp create \
     --resource-group myResourceGroup \
     --consumption-plan-location westus \
     --runtime python \
     --runtime-version 3.13 \
     --functions-version 4 \
     --name myAdvancedFunctionApp \
     --storage-account mystorageaccount
   ```

2. **Configure Application Settings**:
   ```bash
   az functionapp config appsettings set \
     --name myAdvancedFunctionApp \
     --resource-group myResourceGroup \
     --settings \
     ServiceBusConnectionString="your-connection-string" \
     PolicyNotificationsQueue="policy-notifications" \
     AZURE_FUNCTIONS_ENVIRONMENT="Production"
   ```

3. **Deploy the function**:
   ```bash
   func azure functionapp publish myAdvancedFunctionApp
   ```

### Production Considerations

- **Service Bus Scaling**: Consider using Premium or Standard tier for production
- **Monitoring**: Enable Application Insights for comprehensive monitoring
- **Security**: Use Managed Identity instead of connection strings when possible
- **Error Handling**: Monitor dead letter queues for failed messages
- **Performance**: Adjust timer schedule based on actual requirements

## Monitoring and Observability

### Application Insights Integration
The function app integrates with Application Insights for:
- Function execution tracking
- Performance monitoring
- Error tracking and alerting
- Custom telemetry and metrics

### Health Monitoring
Multiple health endpoints provide different levels of monitoring:
- `/api/health` - Overall application health
- `/api/health/servicebus` - Service Bus connectivity
- Built-in Azure Functions health monitoring

### Logging
Comprehensive logging includes:
- Timer execution details
- Service Bus operation results
- Error conditions and stack traces
- Performance metrics

## Error Handling

The application includes robust error handling:
- Service Bus connection failures
- Message serialization errors
- Timer execution errors
- Graceful degradation when Service Bus is unavailable

## Security Considerations

- **Connection Strings**: Store in Azure Key Vault for production
- **Managed Identity**: Use for Service Bus authentication when possible
- **Network Security**: Configure VNet integration for production
- **Access Control**: Implement proper RBAC for Service Bus resources

## Troubleshooting

### Common Issues

1. **Service Bus Connection Errors**:
   - Verify connection string format
   - Check Service Bus namespace and queue exist
   - Validate access permissions

2. **Timer Not Executing**:
   - Check function app is running
   - Verify timer schedule syntax
   - Review function logs for errors

3. **Messages Not Appearing in Queue**:
   - Test Service Bus health endpoint
   - Check queue permissions
   - Verify queue name configuration

### Debug Commands

```bash
# Check Service Bus health
curl http://localhost:7071/api/health/servicebus

# Send test message
curl -X POST http://localhost:7071/api/test/send-message

# View function info
curl http://localhost:7071/api/info
```

## File Structure

```
functions/advanced/
├── function_app.py          # Main function definitions
├── host.json               # Function host configuration
├── local.settings.json.template  # Local settings template
├── requirements.txt        # Python dependencies
├── requirements-test.txt   # Test dependencies
├── pytest.ini            # Test configuration
├── setup-connection.sh    # Service Bus setup script
├── tests/                 # Test files
│   ├── __init__.py
│   └── test_advanced_function_app.py
└── README.md              # This file
```

## Contributing

1. Follow the existing code style and patterns
2. Add tests for new functionality
3. Update documentation as needed
4. Ensure all pre-commit hooks pass
5. Test Service Bus integration thoroughly

## Support

For issues and questions:
- Check Azure Functions documentation
- Review Azure Service Bus documentation
- Check application logs and Application Insights
- Review the test files for usage examples
