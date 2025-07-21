"""
Unit tests for Azure Functions HTTP triggers.

This module contains unit tests for the Azure Functions defined in
function_app.py. Tests cover the hello_world, health_check, and info functions.
"""

import json
import pytest
from unittest.mock import Mock
import azure.functions as func
from function_app import hello_world, health_check, info


class TestHelloWorldFunction:
    """Test cases for the hello_world function."""
    
    def test_hello_world_with_name_in_query(self):
        """Test hello_world function with name in query parameters."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.params = {"name": "Azure"}
        req.method = "GET"
        req.url = "http://localhost:7071/api/hello?name=Azure"
        req.get_json.return_value = None
        
        # Act
        response = hello_world(req)
        
        # Assert
        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["message"] == "Hello, Azure!"
        assert response_data["status"] == "success"
        assert response_data["function_name"] == "HelloWorld"
    
    def test_hello_world_with_name_in_body(self):
        """Test hello_world function with name in request body."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.params = {}
        req.method = "POST"
        req.url = "http://localhost:7071/api/hello"
        req.get_json.return_value = {"name": "Functions"}
        
        # Act
        response = hello_world(req)
        
        # Assert
        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["message"] == "Hello, Functions!"
        assert response_data["method"] == "POST"
    
    def test_hello_world_without_name(self):
        """Test hello_world function without name parameter."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.params = {}
        req.method = "GET"
        req.url = "http://localhost:7071/api/hello"
        req.get_json.return_value = None
        
        # Act
        response = hello_world(req)
        
        # Assert
        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["message"] == "Hello, World!"
    
    def test_hello_world_with_invalid_json(self):
        """Test hello_world function with invalid JSON in body."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.params = {}
        req.method = "POST"
        req.url = "http://localhost:7071/api/hello"
        req.get_json.side_effect = ValueError("Invalid JSON")
        
        # Act
        response = hello_world(req)
        
        # Assert
        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["message"] == "Hello, World!"


class TestHealthCheckFunction:
    """Test cases for the health_check function."""
    
    def test_health_check(self):
        """Test health_check function returns healthy status."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.method = "GET"
        req.url = "http://localhost:7071/api/health"
        
        # Act
        response = health_check(req)
        
        # Assert
        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["status"] == "healthy"
        assert response_data["service"] == "Azure Functions - Basic"
        assert "timestamp" in response_data


class TestInfoFunction:
    """Test cases for the info function."""
    
    def test_info(self):
        """Test info function returns application information."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.method = "GET"
        req.url = "http://localhost:7071/api/info"
        
        # Act
        response = info(req)
        
        # Assert
        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["name"] == "Azure Functions - Basic HTTP Triggers"
        assert response_data["runtime"] == "Python 3.13"
        assert response_data["framework"] == "Azure Functions v4"
        assert "endpoints" in response_data
        assert "hello" in response_data["endpoints"]
        assert "health" in response_data["endpoints"]
        assert "info" in response_data["endpoints"]


class TestResponseHeaders:
    """Test cases for response headers."""
    
    def test_hello_world_headers(self):
        """Test that hello_world function returns correct headers."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        req.params = {"name": "Test"}
        req.method = "GET"
        req.url = "http://localhost:7071/api/hello"
        req.get_json.return_value = None
        
        # Act
        response = hello_world(req)
        
        # Assert
        headers = response.headers
        assert headers["Content-Type"] == "application/json"
        assert headers["X-Function-Name"] == "HelloWorld"
        assert "X-Timestamp" in headers
    
    def test_health_check_headers(self):
        """Test that health_check function returns correct headers."""
        # Arrange
        req = Mock(spec=func.HttpRequest)
        
        # Act
        response = health_check(req)
        
        # Assert
        headers = response.headers
        assert headers["Content-Type"] == "application/json"


if __name__ == "__main__":
    pytest.main([__file__])
