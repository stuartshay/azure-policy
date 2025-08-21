"""
Azure Functions HTTP Trigger - Hello World Example

This module contains a basic HTTP-triggered Azure Function that returns
a "Hello World" message. It demonstrates the Azure Functions Python v2
programming model with Application Insights logging and telemetry.
"""

from datetime import datetime, timezone
import json
import os
import sys
from typing import Any, Dict

import azure.functions as func

# Add the parent directory to the path to import common modules
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from functions.common.decorators import log_function_execution
from functions.common.logging_config import get_logger, setup_application_insights
from functions.common.telemetry import track_custom_event, track_custom_metric

# Initialize Application Insights
setup_application_insights()

# Initialize the function app
app = func.FunctionApp()

# Get logger for this module
logger = get_logger(__name__)


@app.function_name(name="HelloWorld")
@app.route(route="hello", methods=["GET", "POST"])
@log_function_execution(
    function_name="HelloWorld", track_performance=True, track_events=True
)
def hello_world(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP-triggered Azure Function that returns a Hello World message.

    This function accepts both GET and POST requests and returns a JSON
    response with a greeting message, timestamp, and request information.

    Args:
        req (func.HttpRequest): The HTTP request object

    Returns:
        func.HttpResponse: JSON response with greeting and metadata
    """
    # Get function-specific logger
    func_logger = get_logger(__name__, function_name="HelloWorld")
    func_logger.info("Python HTTP trigger function processed a request.")

    try:
        # Get the name parameter from query string or request body
        name = req.params.get("name")

        if not name:
            try:
                req_body = req.get_json()
                if req_body:
                    name = req_body.get("name")
            except ValueError:
                func_logger.warning("Invalid JSON in request body")

        # Default name if none provided
        if not name:
            name = "World"

        # Track custom event for name parameter
        track_custom_event(
            "HelloWorldRequest",
            properties={
                "name_provided": str(name != "World"),
                "method": req.method,
                "has_custom_name": str(name != "World"),
            },
        )

        # Create response data
        response_data: Dict[str, Any] = {
            "message": f"Hello, {name}!",
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "method": req.method,
            "url": req.url,
            "function_name": "HelloWorld",
            "version": "1.0.0",
            "status": "success",
        }

        # Track custom metric for response size
        response_size = len(json.dumps(response_data))
        track_custom_metric(
            "ResponseSize",
            float(response_size),
            properties={"function_name": "HelloWorld", "name": name},
        )

        # Log successful execution
        func_logger.info("Successfully processed request for name: %s", name)

        # Return JSON response
        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=200,
            headers={
                "Content-Type": "application/json",
                "X-Function-Name": "HelloWorld",
                "X-Timestamp": response_data["timestamp"],
            },
        )

    except (ValueError, TypeError, KeyError) as e:
        # Log error
        func_logger.error("Error processing request: %s", str(e))

        # Return error response
        error_response = {
            "error": "Internal server error",
            "message": "An error occurred while processing your request",
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "status": "error",
        }

        return func.HttpResponse(
            json.dumps(error_response, indent=2),
            status_code=500,
            headers={"Content-Type": "application/json"},
        )


@app.function_name(name="HealthCheck")
@app.route(route="health", methods=["GET"])
@log_function_execution(
    function_name="HealthCheck", track_performance=True, track_events=True
)
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint for monitoring and diagnostics.

    Args:
        req (func.HttpRequest): The HTTP request object (unused)

    Returns:
        func.HttpResponse: JSON response with health status
    """
    # Get function-specific logger
    func_logger = get_logger(__name__, function_name="HealthCheck")
    func_logger.info("Health check endpoint accessed")

    # Track health check event
    track_custom_event(
        "HealthCheckAccessed", properties={"endpoint": "health", "status": "healthy"}
    )

    health_data = {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "service": "Azure Functions - Basic",
        "version": "1.0.0",
        "uptime": "Available",
    }

    return func.HttpResponse(
        json.dumps(health_data, indent=2),
        status_code=200,
        headers={"Content-Type": "application/json"},
    )


@app.function_name(name="Info")
@app.route(route="info", methods=["GET"])
@log_function_execution(function_name="Info", track_performance=True, track_events=True)
def info(req: func.HttpRequest) -> func.HttpResponse:
    """
    Information endpoint that returns details about the function app.

    Args:
        req (func.HttpRequest): The HTTP request object (unused)

    Returns:
        func.HttpResponse: JSON response with function app information
    """
    # Get function-specific logger
    func_logger = get_logger(__name__, function_name="Info")
    func_logger.info("Info endpoint accessed")

    # Track info endpoint access
    track_custom_event(
        "InfoEndpointAccessed", properties={"endpoint": "info", "version": "1.0.0"}
    )

    info_data = {
        "name": "Azure Functions - Basic HTTP Triggers",
        "description": "A basic Azure Functions app with HTTP triggers",
        "version": "1.0.0",
        "runtime": "Python 3.13",
        "framework": "Azure Functions v4",
        "endpoints": {
            "hello": {
                "path": "/api/hello",
                "methods": ["GET", "POST"],
                "description": "Returns a Hello World message",
            },
            "health": {
                "path": "/api/health",
                "methods": ["GET"],
                "description": "Health check endpoint",
            },
            "info": {
                "path": "/api/info",
                "methods": ["GET"],
                "description": "Function app information",
            },
        },
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }

    return func.HttpResponse(
        json.dumps(info_data, indent=2),
        status_code=200,
        headers={"Content-Type": "application/json"},
    )
