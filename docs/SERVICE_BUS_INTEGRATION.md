# Service Bus Integration Guide for Azure Functions

This guide explains how to integrate Azure Functions with the newly deployed Service Bus infrastructure.

## 🚀 **Service Bus Deployment Summary**

**Deployed Resources:**
- **Namespace**: `sb-azpolicy-dev-eastus-001`
- **SKU**: Standard
- **Location**: East US
- **Authorization Rules**: FunctionAppAccess, ReadOnlyAccess

### **Queues Created:**
1. `policy-compliance-checks` - For compliance evaluation tasks
2. `policy-remediation-tasks` - For remediation workflows
3. `policy-audit-logs` - For audit logging and reporting
4. `policy-notifications` - For alert and notification processing
5. `policy-deployment-tasks` - For deployment automation
6. `policy-validation-queue` - For policy validation workflows

### **Topics and Subscriptions:**
1. `policy-events` → `all-policy-events` subscription
2. `compliance-reports` → `all-compliance-reports` subscription
3. `resource-changes` - For Azure resource change events
4. `security-alerts` - For security-related notifications

## 🔗 **Function App Integration Options**

### Option 1: Deploy Function App with Service Bus Integration

When you deploy the Function App again, you can add Service Bus settings:

```bash
# Deploy app-service infrastructure first
make terraform-app-service-apply

# Then deploy function app
make terraform-functions-app-apply
```

### Option 2: Manual Integration (Existing Function App)

If you have an existing Function App, add these application settings:

```json
{
  "ServiceBusConnectionString": "<from terraform output>",
  "PolicyComplianceQueue": "policy-compliance-checks",
  "PolicyRemediationQueue": "policy-remediation-tasks",
  "PolicyEventsTopic": "policy-events",
  "ComplianceReportsTopic": "compliance-reports"
}
```

## 📝 **Function App Code Examples**

### Service Bus Queue Trigger (Python)

```python
import azure.functions as func
import logging

app = func.FunctionApp()

@app.service_bus_queue_trigger(
    arg_name="msg",
    queue_name="policy-compliance-checks",
    connection="ServiceBusConnectionString"
)
def policy_compliance_processor(msg: func.ServiceBusMessage):
    logging.info(f'Processing compliance check: {msg.get_body().decode("utf-8")}')

    # Process compliance check logic
    message_body = msg.get_body().decode('utf-8')
    logging.info(f'Received message: {message_body}')

    # Add your compliance checking logic here
    return "Compliance check completed"
```

### Service Bus Topic Trigger (Python)

```python
@app.service_bus_topic_trigger(
    arg_name="msg",
    topic_name="policy-events",
    subscription_name="all-policy-events",
    connection="ServiceBusConnectionString"
)
def policy_events_handler(msg: func.ServiceBusMessage):
    logging.info(f'Processing policy event: {msg.get_body().decode("utf-8")}')

    # Process policy event
    event_data = msg.get_body().decode('utf-8')
    logging.info(f'Policy event received: {event_data}')

    # Add your event processing logic here
```

### Send Message to Service Bus (Python)

```python
from azure.servicebus import ServiceBusClient, ServiceBusMessage
import os

@app.http_trigger(route="send-remediation-task")
def send_remediation_task(req: func.HttpRequest) -> func.HttpResponse:

    # Get connection string from app settings
    connection_str = os.environ["ServiceBusConnectionString"]
    queue_name = "policy-remediation-tasks"

    # Create message
    message_data = req.get_json()
    message = ServiceBusMessage(json.dumps(message_data))

    # Send message
    with ServiceBusClient.from_connection_string(connection_str) as client:
        sender = client.get_queue_sender(queue_name)
        sender.send_messages(message)

    return func.HttpResponse("Remediation task queued successfully")
```

## 🛠️ **Getting Connection Strings**

### From Terraform Output:

```bash
cd infrastructure/service-bus
terraform output function_app_connection_string
```

### From Azure CLI:

```bash
az servicebus namespace authorization-rule keys list \
  --namespace-name "sb-azpolicy-dev-eastus-001" \
  --resource-group "rg-azpolicy-dev-eastus" \
  --name "FunctionAppAccess" \
  --query "primaryConnectionString" \
  --output tsv
```

## 🔒 **Security and Authorization**

### Authorization Rules Created:

1. **FunctionAppAccess** - For Function Apps
   - Listen: ✅ (Receive messages)
   - Send: ✅ (Send messages)
   - Manage: ❌

2. **ReadOnlyAccess** - For monitoring/reporting
   - Listen: ✅
   - Send: ❌
   - Manage: ❌

### Best Practices:

- Use **Managed Identity** in production instead of connection strings
- Implement **retry policies** for transient failures
- Use **dead letter queues** for failed message processing
- Monitor **message metrics** in Azure Portal

## 📊 **Monitoring and Troubleshooting**

### Azure Portal Monitoring:
- Navigate to Service Bus namespace
- View queue/topic metrics
- Monitor active/dead letter messages
- Check authorization rules

### Function App Logs:
```bash
# View Function App logs
az webapp log tail --name "func-azpolicy-dev-001" --resource-group "rg-azpolicy-dev-eastus"
```

### Application Insights:
- Custom telemetry for message processing
- Performance monitoring
- Error tracking and alerts

## 🎯 **Next Steps**

1. **Deploy Function App** (if not already deployed)
2. **Add Service Bus bindings** to function code
3. **Test message processing** with sample messages
4. **Set up monitoring** and alerts
5. **Implement error handling** and retry logic

## 📋 **Service Bus Configuration Details**

- **Message TTL**: 14 days
- **Max Delivery Count**: 10 attempts
- **Dead Lettering**: Enabled
- **Duplicate Detection**: Enabled (10 minutes window)
- **Partitioning**: Disabled (can be enabled for higher throughput)

The Service Bus is now ready for Azure Function integration! 🎉
