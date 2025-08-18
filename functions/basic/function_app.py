"""
Azure Functions HTTP Trigger - Hello World Example

This module contains a basic HTTP-triggered Azure Function that returns
a "Hello World" message. It demonstrates the Azure Functions Python v2
programming model with proper logging and error handling.
"""

import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict

import azure.functions as func

# Initialize the function app
app = func.FunctionApp()


@app.function_name(name="HelloWorld")
@app.route(route="hello", methods=["GET", "POST"])
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
    logging.info("Python HTTP trigger function processed a request.")

    try:
        # Get the name parameter from query string or request body
        name = req.params.get("name")

        if not name:
            try:
                req_body = req.get_json()
                if req_body:
                    name = req_body.get("name")
            except ValueError:
                logging.warning("Invalid JSON in request body")

        # Default name if none provided
        if not name:
            name = "World"

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

        # Log successful execution
        logging.info("Successfully processed request for name: %s", name)

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
        logging.error("Error processing request: %s", str(e))

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
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint for monitoring and diagnostics.

    Args:
        req (func.HttpRequest): The HTTP request object (unused)

    Returns:
        func.HttpResponse: JSON response with health status
    """
    logging.info("Health check endpoint accessed")

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
def info(req: func.HttpRequest) -> func.HttpResponse:
    """
    Information endpoint that returns details about the function app.

    Args:
        req (func.HttpRequest): The HTTP request object (unused)

    Returns:
        func.HttpResponse: JSON response with function app information
    """
    logging.info("Info endpoint accessed")

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
