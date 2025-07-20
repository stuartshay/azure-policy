# Azure Functions - Basic HTTP Triggers

This directory contains a basic Azure Functions application with HTTP triggers, demonstrating the Azure Functions Python v2 programming model with Python 3.13.

## Features

- **Hello World HTTP Function**: Basic HTTP trigger that returns a greeting message
- **Health Check Endpoint**: Monitoring endpoint for application health
- **Info Endpoint**: Returns application and endpoint information
- **Python 3.13**: Latest Python runtime support
- **Azure Functions v4**: Latest Azure Functions runtime
- **Comprehensive Testing**: Unit tests with pytest
- **DevContainer Support**: Complete development environment setup
- **Local Development**: Azurite storage emulator integration

## Quick Start

### Prerequisites

- Docker and VS Code with Dev Containers extension, OR
- Python 3.13
- Azure Functions Core Tools v4
- Azure CLI

### Using DevContainer (Recommended)

1. Open this repository in VS Code
2. When prompted, click "Reopen in Container" or use Command Palette: `Dev Containers: Reopen in Container`
3. Wait for the container to build and setup to complete
4. Open a terminal in VS Code and navigate to `functions/basic`
5. Start the Azure Functions:
   ```bash
   func start
   ```

### Manual Setup

1. Navigate to the functions/basic directory:
   ```bash
   cd functions/basic
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Start Azurite (Azure Storage Emulator):
   ```bash
   azurite --silent --location /tmp/azurite --debug /tmp/azurite/debug.log
   ```

5. Start Azure Functions:
   ```bash
   func start
   ```

## Available Endpoints

Once the function app is running (default: http://localhost:7071), you can access:

### Hello World Function
- **URL**: `GET/POST http://localhost:7071/api/hello`
- **Query Parameter**: `?name=YourName`
- **POST Body**: `{"name": "YourName"}`
- **Example**:
  ```bash
  curl "http://localhost:7071/api/hello?name=Azure"
  curl -X POST "http://localhost:7071/api/hello" -H "Content-Type: application/json" -d '{"name":"Functions"}'
  ```

### Health Check
- **URL**: `GET http://localhost:7071/api/health`
- **Purpose**: Application health monitoring
- **Example**:
  ```bash
  curl "http://localhost:7071/api/health"
  ```

### Application Info
- **URL**: `GET http://localhost:7071/api/info`
- **Purpose**: Application and endpoint information
- **Example**:
  ```bash
  curl "http://localhost:7071/api/info"
  ```

## Development

### Running Tests

```bash
# Run all tests
python -m pytest tests/ -v

# Run tests with coverage
python -m pytest tests/ --cov=. --cov-report=html
```

### Code Quality

```bash
# Format code
black .

# Lint code
pylint function_app.py

# Sort imports
isort .

# Type checking
mypy function_app.py
```

### VS Code Tasks

The following tasks are available in VS Code (Ctrl+Shift+P → "Tasks: Run Task"):

- **Start Azure Functions**: Start the function app locally
- **Start Azurite**: Start the Azure Storage emulator
- **Install Python Dependencies**: Install/update Python packages
- **Run Tests**: Execute unit tests
- **Format Code**: Format code with Black
- **Lint Code**: Run pylint on the code

## Project Structure

```
functions/basic/
├── function_app.py              # Main Azure Functions application
├── host.json                    # Azure Functions host configuration
├── local.settings.json          # Local development settings
├── local.settings.json.template # Template for local settings
├── requirements.txt             # Python dependencies
├── .funcignore                  # Files to exclude from deployment
├── tests/                       # Unit tests
│   ├── __init__.py
│   └── test_function_app.py
└── README.md                    # This file
```

## Configuration

### Local Settings

The `local.settings.json` file contains local development configuration:

- **AzureWebJobsStorage**: Set to use Azurite storage emulator
- **FUNCTIONS_WORKER_RUNTIME**: Set to "python"
- **CORS**: Enabled for all origins during development

### Host Configuration

The `host.json` file configures the Azure Functions host:

- **Version**: 2.0 (latest)
- **Extension Bundle**: Microsoft.Azure.Functions.ExtensionBundle v4
- **Timeout**: 5 minutes
- **Logging**: Configured for development

## Deployment

### Azure Deployment

1. Create an Azure Function App:
   ```bash
   az functionapp create --resource-group myResourceGroup --consumption-plan-location westus --runtime python --runtime-version 3.11 --functions-version 4 --name myFunctionApp --storage-account mystorageaccount
   ```

2. Deploy the function:
   ```bash
   func azure functionapp publish myFunctionApp
   ```

### Environment Variables

For production deployment, configure these application settings:

- `AzureWebJobsStorage`: Connection string to Azure Storage Account
- `FUNCTIONS_WORKER_RUNTIME`: "python"
- `WEBSITE_RUN_FROM_PACKAGE`: "1" (recommended)

## Troubleshooting

### Common Issues

1. **Function not starting**: Check that all dependencies are installed and virtual environment is activated
2. **Storage errors**: Ensure Azurite is running or Azure Storage connection string is correct
3. **Import errors**: Verify Python path and virtual environment setup
4. **Port conflicts**: Check if port 7071 is available or configure a different port

### Debugging

1. **VS Code Debugging**: Use the provided launch configurations
2. **Logs**: Check function logs in the terminal output
3. **Azurite Logs**: Check `/tmp/azurite/debug.log` for storage-related issues

### Getting Help

- [Azure Functions Python Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-python)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Python Azure Functions Samples](https://github.com/Azure/azure-functions-python-samples)

## Next Steps

- Add more HTTP triggers for different endpoints
- Implement timer triggers for scheduled tasks
- Add blob storage triggers for file processing
- Integrate with Azure Key Vault for secrets management
- Add Application Insights for monitoring and telemetry
- Implement authentication and authorization
