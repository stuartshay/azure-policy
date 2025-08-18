# Azure Functions Advanced Timer - Service Bus Integration

This Azure Function provides an advanced timer-triggered function that sends messages to a Service Bus queue every 10 seconds. It includes comprehensive health checks, error handling, and monitoring capabilities.

## 🚀 Features

- **Timer Trigger**: Executes every 10 seconds using CRON expression `0/10 * * * * *`
- **Service Bus Integration**: Sends structured messages to the `policy-notifications` queue
- **Health Checks**: Multiple health check endpoints for monitoring
- **Error Handling**: Comprehensive error handling with retry logic
- **Logging**: Detailed logging for debugging and monitoring
- **Testing**: Complete unit test suite with mocking

## 📁 Project Structure

```
functions/advanced/
├── function_app.py              # Main function application
├── host.json                    # Function host configuration
├── local.settings.json          # Local development settings
├── local.settings.json.template # Template for local settings
├── requirements.txt             # Python dependencies
├── .funcignore                  # Files to ignore during deployment
├── tests/
│   ├── __init__.py
│   └── test_function_app.py     # Unit tests
└── README.md                    # This file
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ServiceBusConnectionString` | Service Bus connection string | - | Yes |
| `PolicyNotificationsQueue` | Target queue name | `policy-notifications` | No |
| `AZURE_FUNCTIONS_ENVIRONMENT` | Environment name | `Development` | No |

### Local Settings

Copy `local.settings.json.template` to `local.settings.json` and update the Service Bus connection string:

```json
{
  "Values": {
    "ServiceBusConnectionString": "Endpoint=sb://sb-azpolicy-dev-eastus-001.servicebus.windows.net/;SharedAccessKeyName=FunctionAppAccess;SharedAccessKey=YOUR_KEY_HERE",
    "PolicyNotificationsQueue": "policy-notifications"
  }
}
```

## 🏃‍♂️ Running Locally

### Prerequisites

1. **Azure Functions Core Tools** (v4.x)
   ```bash
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```

2. **Python 3.9+** with virtual environment
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Azurite** (for local storage emulation)
   ```bash
   npm install -g azurite
   ```

### Setup Steps

1. **Install Dependencies**
   ```bash
   cd functions/advanced
   pip install -r requirements.txt
   ```

2. **Configure Local Settings**
   ```bash
   cp local.settings.json.template local.settings.json
   # Edit local.settings.json with your Service Bus connection string
   ```

3. **Start Azurite** (in a separate terminal)
   ```bash
   azurite --silent --location azurite-data --debug azurite-data/debug.log
   ```

4. **Start the Function**
   ```bash
   func start
   ```

The function will be available at `http://localhost:7072`

## 📊 Functions and Endpoints

### Timer Function

- **Name**: `PolicyNotificationTimer`
- **Trigger**: Timer (every 10 seconds)
- **Description**: Sends structured messages to Service Bus queue

### HTTP Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Comprehensive health check |
| `/api/health/servicebus` | GET | Service Bus connection health |
| `/api/info` | GET | Function app information |
| `/api/test/send-message` | POST | Send test message to Service Bus |

### Health Check Response

```json
{
  "status": "healthy",
  "timestamp": "2025-01-18T02:00:00.000Z",
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

## 📨 Message Format

Messages sent to Service Bus have the following structure:

```json
{
  "id": "uuid-v4",
  "timestamp": "2025-01-18T02:00:00.000Z",
  "type": "policy-notification",
  "source": "timer-trigger",
  "iteration": 42,
  "data": {
    "message": "Scheduled policy notification check",
    "environment": "Development",
    "function_name": "PolicyNotificationTimer",
    "schedule": "every-10-seconds",
    "past_due": false,
    "next_occurrence": "2025-01-18T02:00:10.000Z"
  }
}
```

## 🧪 Testing

### Run Unit Tests

```bash
cd functions/advanced
python -m pytest tests/ -v
```

### Run Specific Test

```bash
python -m pytest tests/test_function_app.py::TestServiceBusManager::test_send_message_success -v
```

### Test Coverage

```bash
python -m pytest tests/ --cov=function_app --cov-report=html
```

### Manual Testing

1. **Test Health Endpoint**
   ```bash
   curl http://localhost:7072/api/health
   ```

2. **Send Test Message**
   ```bash
   curl -X POST http://localhost:7072/api/test/send-message \
     -H "Content-Type: application/json" \
     -d '{"test": "data"}'
   ```

## 🔍 Monitoring and Logging

### Log Levels

- **Information**: Normal operation, message sending
- **Warning**: Timer running late, configuration issues
- **Error**: Service Bus errors, connection failures

### Key Log Messages

```
Timer trigger executed at 2025-01-18T02:00:00.000Z
Message sent successfully to queue 'policy-notifications': uuid-v4
Successfully processed timer trigger #42
Service Bus error sending message: Connection timeout
```

### Application Insights

In production, logs are automatically sent to Application Insights for monitoring and alerting.

## 🚀 Deployment

### Azure Function App Deployment

1. **Create Function App**
   ```bash
   az functionapp create \
     --resource-group rg-azpolicy-dev-eastus \
     --consumption-plan-location eastus \
     --runtime python \
     --runtime-version 3.9 \
     --functions-version 4 \
     --name func-azpolicy-advanced-dev-001 \
     --storage-account stazpolicydeveastus001
   ```

2. **Configure App Settings**
   ```bash
   az functionapp config appsettings set \
     --name func-azpolicy-advanced-dev-001 \
     --resource-group rg-azpolicy-dev-eastus \
     --settings ServiceBusConnectionString="YOUR_CONNECTION_STRING"
   ```

3. **Deploy Function**
   ```bash
   func azure functionapp publish func-azpolicy-advanced-dev-001
   ```

### Infrastructure as Code

Use the existing Terraform infrastructure in `/infrastructure/functions-app/` to deploy the Function App with proper configuration.

## 🔧 Troubleshooting

### Common Issues

1. **Service Bus Connection Failed**
   - Verify connection string in `local.settings.json`
   - Check Service Bus namespace and access key
   - Ensure queue `policy-notifications` exists

2. **Timer Not Triggering**
   - Check host.json configuration
   - Verify function is not disabled
   - Check Azure Functions runtime logs

3. **Import Errors**
   - Ensure all dependencies are installed: `pip install -r requirements.txt`
   - Activate virtual environment
   - Check Python version compatibility

### Debug Mode

Enable debug logging in `local.settings.json`:

```json
{
  "Values": {
    "AZURE_FUNCTIONS_ENVIRONMENT": "Development"
  },
  "logging": {
    "logLevel": {
      "default": "Debug"
    }
  }
}
```

## 📚 Related Documentation

- [Azure Functions Python Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-python)
- [Azure Service Bus Python SDK](https://docs.microsoft.com/en-us/python/api/overview/azure/servicebus-readme)
- [Timer Trigger for Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
