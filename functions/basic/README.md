# Azure Functions - Basic HTTP Triggers

A basic Azure Functions application demonstrating HTTP-triggered functions using the Azure Functions Python v2 programming model.

## Overview

This function app contains simple HTTP-triggered Azure Functions that demonstrate:
- Basic HTTP request/response handling
- JSON response formatting
- Health monitoring endpoints
- Error handling and logging
- Azure Functions v4 Python runtime

## Functions

### HelloWorld
- **Trigger**: HTTP (GET, POST)
- **Route**: `/api/hello`
- **Description**: Returns a personalized greeting message

### HealthCheck
- **Trigger**: HTTP (GET)
- **Route**: `/api/health`
- **Description**: Health monitoring endpoint for application status

### Info
- **Trigger**: HTTP (GET)
- **Route**: `/api/info`
- **Description**: Returns function app information and available endpoints

## Prerequisites

- Python 3.13
- Azure Functions Core Tools v4
- Azure CLI (for deployment)

## Local Development

### Setup

1. **Install dependencies**:
   ```bash
   cd functions/basic
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

### Running Locally

Start the function app locally:
```bash
func start
```

The function app will be available at `http://localhost:7071`

## API Endpoints

### Hello World
```bash
# GET request
curl http://localhost:7071/api/hello

# GET with name parameter
curl "http://localhost:7071/api/hello?name=Azure"

# POST with JSON body
curl -X POST http://localhost:7071/api/hello \
  -H "Content-Type: application/json" \
  -d '{"name": "Functions"}'
```

**Response Example**:
```json
{
  "message": "Hello, Azure!",
  "timestamp": "2025-01-19T00:48:00.000Z",
  "method": "GET",
  "url": "http://localhost:7071/api/hello?name=Azure",
  "function_name": "HelloWorld",
  "version": "1.0.0",
  "status": "success"
}
```

### Health Check
```bash
curl http://localhost:7071/api/health
```

**Response Example**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-19T00:48:00.000Z",
  "service": "Azure Functions - Basic",
  "version": "1.0.0",
  "uptime": "Available"
}
```

### Function Information
```bash
curl http://localhost:7071/api/info
```

**Response Example**:
```json
{
  "name": "Azure Functions - Basic HTTP Triggers",
  "description": "A basic Azure Functions app with HTTP triggers",
  "version": "1.0.0",
  "runtime": "Python 3.13",
  "framework": "Azure Functions v4",
  "endpoints": {
    "hello": {
      "path": "/api/hello",
      "methods": ["GET", "POST"],
      "description": "Returns a Hello World message"
    },
    "health": {
      "path": "/api/health",
      "methods": ["GET"],
      "description": "Health check endpoint"
    },
    "info": {
      "path": "/api/info",
      "methods": ["GET"],
      "description": "Function app information"
    }
  },
  "timestamp": "2025-01-19T00:48:00.000Z"
}
```

## Testing

Run the test suite:
```bash
# Install test dependencies
pip install -r requirements-test.txt

# Run tests
pytest tests/
```

## Configuration

### Local Settings
The `local.settings.json` file contains local development configuration:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AZURE_FUNCTIONS_ENVIRONMENT": "Development"
  }
}
```

### Host Configuration
The `host.json` file configures the function host:

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

1. **Create a Function App in Azure**:
   ```bash
   az functionapp create \
     --resource-group myResourceGroup \
     --consumption-plan-location westus \
     --runtime python \
     --runtime-version 3.13 \
     --functions-version 4 \
     --name myFunctionApp \
     --storage-account mystorageaccount
   ```

2. **Deploy the function**:
   ```bash
   func azure functionapp publish myFunctionApp
   ```

### Environment Variables

For production deployment, configure these application settings:
- `AZURE_FUNCTIONS_ENVIRONMENT`: Set to "Production"
- Additional environment-specific settings as needed

## Monitoring

### Application Insights
The function app is configured to work with Application Insights for monitoring and telemetry.

### Health Monitoring
Use the `/api/health` endpoint for:
- Load balancer health checks
- Application monitoring
- Automated health verification

## Error Handling

The functions include comprehensive error handling:
- Input validation
- JSON parsing error handling
- Structured error responses
- Detailed logging for troubleshooting

## Security Considerations

- Input validation on all endpoints
- Structured logging (avoid logging sensitive data)
- Error responses don't expose internal details
- HTTPS enforcement in production

## File Structure

```
functions/basic/
├── function_app.py          # Main function definitions
├── host.json               # Function host configuration
├── local.settings.json.template  # Local settings template
├── requirements.txt        # Python dependencies
├── requirements-test.txt   # Test dependencies
├── pytest.ini            # Test configuration
├── tests/                 # Test files
│   ├── __init__.py
│   └── test_function_app.py
└── README.md              # This file
```

## Contributing

1. Follow the existing code style and patterns
2. Add tests for new functionality
3. Update documentation as needed
4. Ensure all pre-commit hooks pass

## Support

For issues and questions:
- Check the Azure Functions documentation
- Review the test files for usage examples
- Check application logs for troubleshooting
