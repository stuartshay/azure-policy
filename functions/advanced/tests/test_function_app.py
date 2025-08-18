"""
Unit tests for Azure Functions Advanced Timer with Service Bus Integration

This module contains comprehensive tests for the advanced Azure Function
including timer triggers, Service Bus operations, and health checks.
"""

import json
import os
import sys
import unittest
from unittest.mock import Mock, patch

from azure.servicebus.exceptions import ServiceBusError

# Import the function app components
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from function_app import (  # noqa: E402
    ServiceBusManager,
    function_info,
    health_check,
    policy_notification_timer,
    send_test_message,
    service_bus_health,
)


class TestServiceBusManager(unittest.TestCase):
    """Test cases for ServiceBusManager class."""

    def setUp(self):
        """Set up test fixtures."""
        self.manager = ServiceBusManager()

    @patch.dict(
        os.environ,
        {
            "ServiceBusConnectionString": "Endpoint=sb://test.servicebus.windows.net/;SharedAccessKeyName=test;SharedAccessKey=test",
            "PolicyNotificationsQueue": "test-queue",
        },
    )
    def test_init_with_environment_variables(self):
        """Test ServiceBusManager initialization with environment variables."""
        manager = ServiceBusManager()
        self.assertEqual(
            manager.connection_string,
            "Endpoint=sb://test.servicebus.windows.net/;SharedAccessKeyName=test;SharedAccessKey=test",
        )
        self.assertEqual(manager.queue_name, "test-queue")

    @patch.dict(os.environ, {}, clear=True)
    def test_init_without_environment_variables(self):
        """Test ServiceBusManager initialization without environment variables."""
        manager = ServiceBusManager()
        self.assertIsNone(manager.connection_string)
        self.assertEqual(manager.queue_name, "policy-notifications")

    @patch.dict(os.environ, {"ServiceBusConnectionString": ""})
    def test_get_client_without_connection_string(self):
        """Test _get_client raises ValueError when connection string is not set."""
        manager = ServiceBusManager()
        with self.assertRaises(ValueError) as context:
            manager._get_client()
        self.assertIn(
            "ServiceBusConnectionString not configured", str(context.exception)
        )

    @patch("function_app.ServiceBusClient")
    @patch.dict(os.environ, {"ServiceBusConnectionString": "test-connection-string"})
    def test_get_client_creates_client(self, mock_service_bus_client):
        """Test _get_client creates and returns ServiceBusClient."""
        manager = ServiceBusManager()
        client = manager._get_client()

        mock_service_bus_client.from_connection_string.assert_called_once_with(
            "test-connection-string"
        )
        self.assertEqual(
            client, mock_service_bus_client.from_connection_string.return_value
        )

    @patch("function_app.ServiceBusClient")
    @patch.dict(os.environ, {"ServiceBusConnectionString": "test-connection-string"})
    def test_send_message_success(self, mock_service_bus_client):
        """Test successful message sending."""
        # Setup mocks
        mock_client = Mock()
        mock_sender = Mock()
        mock_client.get_queue_sender.return_value.__enter__.return_value = mock_sender
        mock_service_bus_client.from_connection_string.return_value = mock_client

        manager = ServiceBusManager()
        message_data = {"id": "test-id", "message": "test message"}

        result = manager.send_message(message_data)

        self.assertTrue(result)
        mock_sender.send_messages.assert_called_once()

    @patch("function_app.ServiceBusClient")
    @patch.dict(os.environ, {"ServiceBusConnectionString": "test-connection-string"})
    def test_send_message_service_bus_error(self, mock_service_bus_client):
        """Test message sending with ServiceBusError."""
        # Setup mocks to raise ServiceBusError
        mock_client = Mock()
        mock_sender = Mock()
        mock_sender.send_messages.side_effect = ServiceBusError("Service Bus error")
        mock_client.get_queue_sender.return_value.__enter__.return_value = mock_sender
        mock_service_bus_client.from_connection_string.return_value = mock_client

        manager = ServiceBusManager()
        message_data = {"id": "test-id", "message": "test message"}

        result = manager.send_message(message_data)

        self.assertFalse(result)

    @patch("function_app.ServiceBusClient")
    @patch.dict(os.environ, {"ServiceBusConnectionString": "test-connection-string"})
    def test_test_connection_success(self, mock_service_bus_client):
        """Test successful connection test."""
        # Setup mocks
        mock_client = Mock()
        mock_receiver = Mock()
        mock_client.get_queue_receiver.return_value.__enter__.return_value = (
            mock_receiver
        )
        mock_service_bus_client.from_connection_string.return_value = mock_client

        manager = ServiceBusManager()
        result = manager.test_connection()

        expected = {
            "status": "healthy",
            "queue_name": "policy-notifications",
            "connection": "successful",
        }
        self.assertEqual(result, expected)

    @patch("function_app.ServiceBusClient")
    @patch.dict(os.environ, {"ServiceBusConnectionString": "test-connection-string"})
    def test_test_connection_failure(self, mock_service_bus_client):
        """Test connection test failure."""
        # Setup mocks to raise exception
        mock_service_bus_client.from_connection_string.side_effect = Exception(
            "Connection failed"
        )

        manager = ServiceBusManager()
        result = manager.test_connection()

        self.assertEqual(result["status"], "unhealthy")
        self.assertEqual(result["connection"], "failed")
        self.assertIn("Connection failed", result["error"])


class TestTimerFunction(unittest.TestCase):
    """Test cases for timer trigger function."""

    @patch("function_app.service_bus_manager")
    def test_policy_notification_timer_success(self, mock_service_bus_manager):
        """Test successful timer trigger execution."""
        # Setup mocks
        mock_timer = Mock()
        mock_timer.past_due = False
        mock_timer.schedule_status.next = "2025-01-18T02:00:00Z"
        mock_service_bus_manager.send_message.return_value = True

        # Execute function
        policy_notification_timer(mock_timer)

        # Verify message was sent
        mock_service_bus_manager.send_message.assert_called_once()
        call_args = mock_service_bus_manager.send_message.call_args[0][0]

        self.assertEqual(call_args["type"], "policy-notification")
        self.assertEqual(call_args["source"], "timer-trigger")
        self.assertIn("id", call_args)
        self.assertIn("timestamp", call_args)

    @patch("function_app.service_bus_manager")
    def test_policy_notification_timer_past_due(self, mock_service_bus_manager):
        """Test timer trigger when past due."""
        # Setup mocks
        mock_timer = Mock()
        mock_timer.past_due = True
        mock_timer.schedule_status.next = None
        mock_service_bus_manager.send_message.return_value = True

        # Execute function
        policy_notification_timer(mock_timer)

        # Verify message was sent with past_due flag
        mock_service_bus_manager.send_message.assert_called_once()
        call_args = mock_service_bus_manager.send_message.call_args[0][0]

        self.assertTrue(call_args["data"]["past_due"])

    @patch("function_app.service_bus_manager")
    def test_policy_notification_timer_send_failure(self, mock_service_bus_manager):
        """Test timer trigger when message sending fails."""
        # Setup mocks
        mock_timer = Mock()
        mock_timer.past_due = False
        mock_service_bus_manager.send_message.return_value = False

        # Execute function (should not raise exception)
        policy_notification_timer(mock_timer)

        # Verify message send was attempted
        mock_service_bus_manager.send_message.assert_called_once()


class TestHealthCheckEndpoints(unittest.TestCase):
    """Test cases for health check endpoints."""

    @patch("function_app.service_bus_manager")
    def test_health_check_healthy(self, mock_service_bus_manager):
        """Test health check endpoint when all components are healthy."""
        # Setup mocks
        mock_service_bus_manager.test_connection.return_value = {
            "status": "healthy",
            "queue_name": "policy-notifications",
            "connection": "successful",
        }
        mock_service_bus_manager.queue_name = "policy-notifications"
        mock_service_bus_manager.connection_string = "test-connection"

        mock_req = Mock()

        # Execute function
        response = health_check(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.get_body())
        self.assertEqual(response_data["status"], "healthy")
        self.assertEqual(
            response_data["components"]["service_bus"]["status"], "healthy"
        )

    @patch("function_app.service_bus_manager")
    def test_health_check_unhealthy(self, mock_service_bus_manager):
        """Test health check endpoint when Service Bus is unhealthy."""
        # Setup mocks
        mock_service_bus_manager.test_connection.return_value = {
            "status": "unhealthy",
            "queue_name": "policy-notifications",
            "connection": "failed",
            "error": "Connection timeout",
        }
        mock_service_bus_manager.queue_name = "policy-notifications"
        mock_service_bus_manager.connection_string = "test-connection"

        mock_req = Mock()

        # Execute function
        response = health_check(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 503)
        response_data = json.loads(response.get_body())
        self.assertEqual(response_data["status"], "unhealthy")

    @patch("function_app.service_bus_manager")
    def test_service_bus_health_check(self, mock_service_bus_manager):
        """Test dedicated Service Bus health check endpoint."""
        # Setup mocks
        mock_service_bus_manager.test_connection.return_value = {
            "status": "healthy",
            "queue_name": "policy-notifications",
            "connection": "successful",
        }
        mock_service_bus_manager.queue_name = "policy-notifications"
        mock_service_bus_manager.connection_string = "test-connection"

        mock_req = Mock()

        # Execute function
        response = service_bus_health(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.get_body())
        self.assertEqual(response_data["service_bus"]["status"], "healthy")

    def test_function_info_endpoint(self):
        """Test function info endpoint."""
        mock_req = Mock()

        # Execute function
        response = function_info(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.get_body())
        self.assertEqual(
            response_data["name"], "Azure Functions - Advanced Timer with Service Bus"
        )
        self.assertIn("PolicyNotificationTimer", response_data["functions"])


class TestSendTestMessage(unittest.TestCase):
    """Test cases for send test message endpoint."""

    @patch("function_app.service_bus_manager")
    def test_send_test_message_success(self, mock_service_bus_manager):
        """Test successful test message sending."""
        # Setup mocks
        mock_service_bus_manager.send_message.return_value = True
        mock_service_bus_manager.queue_name = "policy-notifications"

        mock_req = Mock()
        mock_req.get_json.return_value = {"custom": "data"}

        # Execute function
        response = send_test_message(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.get_body())
        self.assertEqual(response_data["status"], "success")
        self.assertIn("message_id", response_data)

    @patch("function_app.service_bus_manager")
    def test_send_test_message_failure(self, mock_service_bus_manager):
        """Test test message sending failure."""
        # Setup mocks
        mock_service_bus_manager.send_message.return_value = False
        mock_service_bus_manager.queue_name = "policy-notifications"

        mock_req = Mock()
        mock_req.get_json.return_value = None

        # Execute function
        response = send_test_message(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 500)
        response_data = json.loads(response.get_body())
        self.assertEqual(response_data["status"], "error")

    @patch("function_app.service_bus_manager")
    def test_send_test_message_invalid_json(self, mock_service_bus_manager):
        """Test test message sending with invalid JSON."""
        # Setup mocks
        mock_service_bus_manager.send_message.return_value = True
        mock_service_bus_manager.queue_name = "policy-notifications"

        mock_req = Mock()
        mock_req.get_json.side_effect = ValueError("Invalid JSON")

        # Execute function
        response = send_test_message(mock_req)

        # Verify response
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.get_body())
        self.assertEqual(response_data["status"], "success")


if __name__ == "__main__":
    unittest.main()
