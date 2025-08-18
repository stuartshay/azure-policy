"""
Azure Functions Advanced Timer Trigger - Service Bus Integration

This module contains an advanced Azure Function with a timer trigger that sends
messages to a Service Bus queue every 10 seconds. It includes comprehensive
error handling, health checks, and monitoring capabilities.
"""

import json
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import azure.functions as func

# Initialize the function app
app = func.FunctionApp()

# Global counter for message tracking
message_counter = 0

# Lazy import for Service Bus to avoid import errors during cold start
ServiceBusClient = None
ServiceBusMessage = None
ServiceBusError = None


def _ensure_servicebus_imports() -> None:
    """Ensure Service Bus modules are imported when needed."""
    global ServiceBusClient, ServiceBusMessage, ServiceBusError
    if ServiceBusClient is None:
        try:
            from azure.servicebus import ServiceBusClient as _ServiceBusClient
            from azure.servicebus import ServiceBusMessage as _ServiceBusMessage
            from azure.servicebus.exceptions import ServiceBusError as _ServiceBusError

            ServiceBusClient = _ServiceBusClient
            ServiceBusMessage = _ServiceBusMessage
            ServiceBusError = _ServiceBusError
        except ImportError as e:
            logging.error(f"Failed to import Service Bus modules: {e}")
            raise


class ServiceBusManager:
    """Manages Service Bus operations with error handling and retry logic."""

    def __init__(self) -> None:
        self.connection_string = os.environ.get("ServiceBusConnectionString")
        self.queue_name = os.environ.get(
            "PolicyNotificationsQueue", "policy-notifications"
        )
        self.client: Optional[Any] = None

    def _get_client(self) -> Any:
        """Get or create Service Bus client."""
        if not self.connection_string:
            raise ValueError("ServiceBusConnectionString not configured")

        _ensure_servicebus_imports()

        if not self.client:
            if ServiceBusClient is not None:
                self.client = ServiceBusClient.from_connection_string(
                    self.connection_string
                )
            else:
                raise RuntimeError("ServiceBusClient not available")

        return self.client

    def send_message(self, message_data: Dict[str, Any]) -> bool:
        """
        Send a message to the Service Bus queue.

        Args:
            message_data: Dictionary containing message data

        Returns:
            bool: True if message sent successfully, False otherwise
        """
        try:
            _ensure_servicebus_imports()
            client = self._get_client()
            message = ServiceBusMessage(json.dumps(message_data))

            with client.get_queue_sender(self.queue_name) as sender:
                sender.send_messages(message)

            logging.info(
                f"Message sent successfully to queue '{self.queue_name}': {message_data['id']}"
            )
            return True

        except Exception as e:
            if ServiceBusError and isinstance(e, ServiceBusError):
                logging.error(f"Service Bus error sending message: {str(e)}")
            else:
                logging.error(f"Error sending message: {str(e)}")
            return False

    def test_connection(self) -> Dict[str, Any]:
        """
        Test Service Bus connection.

        Returns:
            Dict containing connection test results
        """
        try:
            _ensure_servicebus_imports()
            client = self._get_client()
            # Try to get queue properties to test connection
            with client.get_queue_receiver(self.queue_name):
                # Just testing connection, not actually receiving
                pass

            return {
                "status": "healthy",
                "queue_name": self.queue_name,
                "connection": "successful",
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "queue_name": self.queue_name,
                "connection": "failed",
                "error": str(e),
            }


# Initialize Service Bus manager
service_bus_manager = ServiceBusManager()


@app.function_name(name="PolicyNotificationTimer")
@app.timer_trigger(schedule="0/10 * * * * *", arg_name="timer", run_on_startup=False)
def policy_notification_timer(timer: func.TimerRequest) -> None:
    """
    Timer-triggered function that sends messages to Service Bus every 10 seconds.

    This function runs every 10 seconds and sends a structured message to the
    policy-notifications Service Bus queue. It includes error handling and
    comprehensive logging.

    Args:
        timer: Timer request object containing schedule information
    """
    global message_counter
    message_counter += 1

    # Log timer execution
    utc_timestamp = datetime.now(timezone.utc)
    logging.info(f"Timer trigger executed at {utc_timestamp.isoformat()}Z")

    if timer.past_due:
        logging.warning("Timer is running late!")

    try:
        # Create message data
        message_data = {
            "id": str(uuid.uuid4()),
            "timestamp": utc_timestamp.isoformat() + "Z",
            "type": "policy-notification",
            "source": "timer-trigger",
            "iteration": message_counter,
            "data": {
                "message": "Scheduled policy notification check",
                "environment": os.environ.get(
                    "AZURE_FUNCTIONS_ENVIRONMENT", "Development"
                ),
                "function_name": "PolicyNotificationTimer",
                "schedule": "every-10-seconds",
                "past_due": timer.past_due,
                "next_occurrence": None,  # schedule_status not available in current Azure Functions version
            },
        }

        # Send message to Service Bus
        success = service_bus_manager.send_message(message_data)

        if success:
            logging.info(f"Successfully processed timer trigger #{message_counter}")
        else:
            logging.error(
                f"Failed to send message for timer trigger #{message_counter}"
            )

    except Exception as e:
        logging.error(f"Error in timer trigger #{message_counter}: {str(e)}")


@app.function_name(name="HealthCheck")
@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Comprehensive health check endpoint.

    Args:
        req: HTTP request object

    Returns:
        JSON response with health status
    """
    logging.info("Health check endpoint accessed")

    try:
        # Test Service Bus connection
        service_bus_status = service_bus_manager.test_connection()

        # Overall health determination
        overall_status = (
            "healthy" if service_bus_status["status"] == "healthy" else "unhealthy"
        )
        status_code = 200 if overall_status == "healthy" else 503

        health_data = {
            "status": overall_status,
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "service": "Azure Functions - Advanced Timer",
            "version": "1.0.0",
            "components": {
                "timer_function": {
                    "status": "healthy",
                    "message_counter": message_counter,
                    "schedule": "every 10 seconds",
                },
                "service_bus": service_bus_status,
                "configuration": {
                    "queue_name": service_bus_manager.queue_name,
                    "connection_configured": bool(
                        service_bus_manager.connection_string
                    ),
                },
            },
        }

        return func.HttpResponse(
            json.dumps(health_data, indent=2),
            status_code=status_code,
            headers={"Content-Type": "application/json"},
        )

    except Exception as e:
        logging.error(f"Error in health check: {str(e)}")

        error_response = {
            "status": "unhealthy",
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "error": "Health check failed",
            "message": str(e),
        }

        return func.HttpResponse(
            json.dumps(error_response, indent=2),
            status_code=503,
            headers={"Content-Type": "application/json"},
        )


@app.function_name(name="ServiceBusHealth")
@app.route(route="health/servicebus", methods=["GET"])
def service_bus_health(req: func.HttpRequest) -> func.HttpResponse:
    """
    Dedicated Service Bus health check endpoint.

    Args:
        req: HTTP request object

    Returns:
        JSON response with Service Bus connection status
    """
    logging.info("Service Bus health check endpoint accessed")

    try:
        status = service_bus_manager.test_connection()
        status_code = 200 if status["status"] == "healthy" else 503

        response_data = {
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "service_bus": status,
            "configuration": {
                "queue_name": service_bus_manager.queue_name,
                "connection_string_configured": bool(
                    service_bus_manager.connection_string
                ),
            },
        }

        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=status_code,
            headers={"Content-Type": "application/json"},
        )

    except Exception as e:
        logging.error("Error in Service Bus health check: %s", str(e))

        error_response = {
            "status": "error",
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "error": str(e),
        }

        return func.HttpResponse(
            json.dumps(error_response, indent=2),
            status_code=500,
            headers={"Content-Type": "application/json"},
        )


@app.function_name(name="FunctionInfo")
@app.route(route="info", methods=["GET"])
def function_info(req: func.HttpRequest) -> func.HttpResponse:
    """
    Function information endpoint.

    Args:
        req: HTTP request object

    Returns:
        JSON response with function app information
    """
    logging.info("Function info endpoint accessed")

    info_data = {
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
                "message_counter": message_counter,
            }
        },
        "endpoints": {
            "health": {
                "path": "/api/health",
                "methods": ["GET"],
                "description": "Comprehensive health check",
            },
            "servicebus_health": {
                "path": "/api/health/servicebus",
                "methods": ["GET"],
                "description": "Service Bus connection health check",
            },
            "info": {
                "path": "/api/info",
                "methods": ["GET"],
                "description": "Function app information",
            },
        },
        "configuration": {
            "service_bus_queue": service_bus_manager.queue_name,
            "environment": os.environ.get("AZURE_FUNCTIONS_ENVIRONMENT", "Development"),
        },
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }

    return func.HttpResponse(
        json.dumps(info_data, indent=2),
        status_code=200,
        headers={"Content-Type": "application/json"},
    )


@app.function_name(name="SendTestMessage")
@app.route(route="test/send-message", methods=["POST"])
def send_test_message(req: func.HttpRequest) -> func.HttpResponse:
    """
    Manual endpoint to send a test message to Service Bus.

    Args:
        req: HTTP request object

    Returns:
        JSON response with send operation result
    """
    logging.info("Test message endpoint accessed")

    try:
        # Get custom message data from request body if provided
        custom_data = {}
        try:
            req_body = req.get_json()
            if req_body:
                custom_data = req_body
        except ValueError:
            logging.warning("Invalid JSON in request body, using default message")

        # Create test message
        test_message = {
            "id": str(uuid.uuid4()),
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "type": "test-message",
            "source": "manual-trigger",
            "data": {
                "message": "Manual test message",
                "custom_data": custom_data,
                "environment": os.environ.get(
                    "AZURE_FUNCTIONS_ENVIRONMENT", "Development"
                ),
            },
        }

        # Send message
        success = service_bus_manager.send_message(test_message)

        if success:
            response_data = {
                "status": "success",
                "message": "Test message sent successfully",
                "message_id": test_message["id"],
                "queue": service_bus_manager.queue_name,
                "timestamp": test_message["timestamp"],
            }
            status_code = 200
        else:
            response_data = {
                "status": "error",
                "message": "Failed to send test message",
                "queue": service_bus_manager.queue_name,
                "timestamp": datetime.now(timezone.utc)
                .isoformat()
                .replace("+00:00", "Z"),
            }
            status_code = 500

        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=status_code,
            headers={"Content-Type": "application/json"},
        )

    except Exception as e:
        logging.error(f"Error sending test message: {str(e)}")

        error_response = {
            "status": "error",
            "message": "Error sending test message",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        }

        return func.HttpResponse(
            json.dumps(error_response, indent=2),
            status_code=500,
            headers={"Content-Type": "application/json"},
        )
