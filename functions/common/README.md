# Azure Functions Common Logging Library

This library provides centralized Application Insights logging and telemetry for Azure Functions with support for both local development and production environments.

## Features

- **Application Insights Integration**: Automatic telemetry collection with OpenCensus
- **Structured Logging**: Consistent log formatting with correlation IDs
- **Custom Events & Metrics**: Easy tracking of business events and performance metrics
- **Function Decorators**: Automatic instrumentation with minimal code changes
- **Local Development Support**: Works with Azurite and local Application Insights
- **Production Ready**: Seamless transition to Azure-hosted Application Insights

## Quick Start

### 1. Import and Initialize

```python
import azure.functions as func
from common.logging_config import get_logger, setup_application_insights
from common.decorators import log_function_execution
from common.telemetry import track_custom_event, track_custom_metric

# Initialize Application Insights (done automatically on import)
setup_application_insights()

# Get a logger for your module
logger = get_logger(__name__)
```

### 2. Use the Function Decorator

```python
@app.function_name(name="MyFunction")
@app.route(route="myroute", methods=["GET", "POST"])
@log_function_execution(
    function_name="MyFunction",
    track_performance=True,
    track_events=True,
    custom_properties={"version": "1.0.0"}
)
def my_function(req: func.HttpRequest) -> func.HttpResponse:
    # Your function code here
    func_logger = get_logger(__name__, function_name="MyFunction")
    func_logger.info("Processing request")

    # Track custom events
    track_custom_event("UserAction", properties={"action": "button_click"})

    # Track custom metrics
    track_custom_metric("ProcessingTime", 123.45, properties={"status": "success"})

    return func.HttpResponse("Hello World")
```

## Configuration

### Environment Variables

Set these in your `local.settings.json` for local development:

```json
{
  "Values": {
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=your-key;IngestionEndpoint=https://your-region.in.applicationinsights.azure.com/;LiveEndpoint=https://your-region.livediagnostics.monitor.azure.com/",
    "APPLICATIONINSIGHTS_SAMPLING_PERCENTAGE": "100",
    "LOGGING_LEVEL": "INFO"
  }
}
```

For production, these are automatically configured through the Function App settings.

### Host.json Configuration

The `host.json` file includes enhanced Application Insights settings:

```json
{
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 20
      },
      "enableLiveMetrics": true,
      "enableDependencyTracking": true,
      "enablePerformanceCountersCollection": true
    }
  }
}
```

## API Reference

### Logging

#### `get_logger(name, function_name=None, correlation_id=None, custom_properties=None)`

Creates a configured logger with optional context.

**Parameters:**
- `name`: Logger name (typically `__name__`)
- `function_name`: Azure Function name for context
- `correlation_id`: Correlation ID for request tracking
- `custom_properties`: Additional properties to include in logs

**Example:**
```python
logger = get_logger(__name__, function_name="HelloWorld")
logger.info("Processing request", extra={"user_id": "123"})
```

### Telemetry

#### `track_custom_event(name, properties=None, measurements=None)`

Track a custom event in Application Insights.

**Parameters:**
- `name`: Event name
- `properties`: Custom properties (string values)
- `measurements`: Custom measurements (numeric values)

**Example:**
```python
track_custom_event(
    "UserLogin",
    properties={"user_type": "premium", "source": "mobile"},
    measurements={"login_time": 1.23}
)
```

#### `track_custom_metric(name, value, properties=None)`

Track a custom metric in Application Insights.

**Parameters:**
- `name`: Metric name
- `value`: Metric value (float)
- `properties`: Custom properties

**Example:**
```python
track_custom_metric(
    "ResponseTime",
    456.78,
    properties={"endpoint": "/api/users", "status": "success"}
)
```

#### `track_dependency(name, dependency_type, target, success, duration_ms, properties=None)`

Track a dependency call in Application Insights.

**Example:**
```python
track_dependency(
    "Database Query",
    "SQL",
    "users-db.database.windows.net",
    True,
    123.45,
    properties={"query": "SELECT * FROM users"}
)
```

### Decorators

#### `@log_function_execution(function_name=None, track_performance=True, track_events=True, custom_properties=None)`

Automatically instruments Azure Functions with logging and telemetry.

**Parameters:**
- `function_name`: Override function name for logging
- `track_performance`: Whether to track execution time
- `track_events`: Whether to track start/end events
- `custom_properties`: Additional properties to include

**Features:**
- Automatic correlation ID generation
- Performance timing
- Exception tracking
- Custom event logging
- Request/response logging

#### `@log_dependency_call(dependency_name, dependency_type="HTTP", target=None)`

Automatically tracks dependency calls.

**Example:**
```python
@log_dependency_call("External API", "HTTP", "api.example.com")
def call_external_api():
    # Your API call code
    pass
```

#### `@retry_with_logging(max_retries=3, delay_seconds=1.0, backoff_multiplier=2.0)`

Adds retry logic with exponential backoff and logging.

**Example:**
```python
@retry_with_logging(max_retries=3, delay_seconds=1.0)
def unreliable_operation():
    # Your operation that might fail
    pass
```

## Local Development

### Using with Azurite

The logging system works seamlessly with Azurite for local development:

1. Start Azurite: `azurite --silent --location azurite-data --debug azurite-data/debug.log`
2. Copy `local.settings.json.template` to `local.settings.json`
3. Update the Application Insights connection string if needed
4. Run your function: `func start`

### Console Logging

When Application Insights is not available (e.g., no connection string), the system automatically falls back to console logging for local development.

## Production Deployment

### Infrastructure Requirements

Ensure your Terraform configuration includes Application Insights:

```hcl
resource "azurerm_application_insights" "functions" {
  name                = "appi-${var.workload}-functions-${var.environment}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}
```

### Function App Settings

The following settings are automatically configured in production:

- `APPLICATIONINSIGHTS_CONNECTION_STRING`
- `APPINSIGHTS_INSTRUMENTATIONKEY`

## Best Practices

### 1. Use Structured Logging

```python
logger.info("User action completed", extra={
    "user_id": user_id,
    "action": "purchase",
    "amount": 99.99,
    "currency": "USD"
})
```

### 2. Track Business Events

```python
track_custom_event("Purchase", properties={
    "product_id": "123",
    "category": "electronics",
    "payment_method": "credit_card"
})
```

### 3. Monitor Performance

```python
track_custom_metric("DatabaseQueryTime", query_duration, properties={
    "query_type": "SELECT",
    "table": "users"
})
```

### 4. Use Correlation IDs

```python
correlation_id = str(uuid.uuid4())
logger = get_logger(__name__, correlation_id=correlation_id)
```

### 5. Handle Exceptions Properly

```python
try:
    # Your code
    pass
except Exception as e:
    track_exception(e, properties={"operation": "data_processing"})
    logger.exception("Operation failed")
    raise
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure the `sys.path.append()` is correctly pointing to the parent directory
2. **Missing Dependencies**: Install required packages: `pip install opencensus-ext-azure`
3. **No Telemetry**: Check Application Insights connection string configuration
4. **Local Development**: Use the template connection string for local testing

### Debugging

Enable debug logging to troubleshoot issues:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Monitoring

Use Application Insights Live Metrics to monitor your functions in real-time:
- Function execution times
- Request rates
- Failure rates
- Custom events and metrics

## Examples

See the `functions/basic/function_app.py` file for complete examples of how to use the logging library in Azure Functions.
