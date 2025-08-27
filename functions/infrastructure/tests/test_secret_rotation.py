"""
Unit tests for the Service Bus secret rotation function.
"""

import json
import os
import unittest
from unittest.mock import Mock, patch

# Import from the correct absolute path
from function_app import (
    SecretRotationManager,
    manual_rotation,
    rotation_health,
    rotation_info,
)
import pytest


class TestableSecretRotationManager(SecretRotationManager):
    """Subclass to expose protected methods for testing."""

    def get_credential_public(self):
        return self._get_credential()

    def get_servicebus_client_public(self):
        return self._get_servicebus_client()

    def get_keyvault_client_public(self):
        return self._get_keyvault_client()


class TestSecretRotationManager(unittest.TestCase):
    """Test cases for SecretRotationManager class."""

    def setUp(self):
        """Set up test fixtures."""
        self.manager = TestableSecretRotationManager()
        # Initialize attributes that may be set in tests
        self.manager.key_vault_uri = None
        self.manager.rotation_enabled = None

    @patch.dict(
        os.environ,
        {
            "AZURE_SUBSCRIPTION_ID": "test-subscription-id",
            "SERVICE_BUS_RESOURCE_GROUP": "test-rg",
            "SERVICE_BUS_NAMESPACE": "test-namespace",
            "KEY_VAULT_URI": "https://test-kv.vault.azure.net/",
            "ROTATION_ENABLED": "true",
        },
    )
    def test_init_with_environment_variables(self):
        """Test initialization with environment variables."""
        manager = SecretRotationManager()
        assert manager.subscription_id == "test-subscription-id"
        assert manager.resource_group_name == "test-rg"
        assert manager.namespace_name == "test-namespace"
        assert manager.key_vault_uri == "https://test-kv.vault.azure.net/"
        assert manager.rotation_enabled is True

    def test_init_with_defaults(self):
        """Test initialization with default values."""
        with patch.dict(os.environ, {}, clear=True):
            manager = SecretRotationManager()
            assert manager.resource_group_name == "rg-azpolicy-dev-eastus"
            assert manager.namespace_name == "sb-azpolicy-dev-eastus-001"
            assert manager.rotation_enabled is True

    @patch("function_app._ensure_azure_imports")
    @patch("function_app.DefaultAzureCredential")
    def test_get_credential(self, mock_credential_class, mock_imports):
        """Test credential initialization."""
        mock_credential = Mock()
        mock_credential_class.return_value = mock_credential
        credential = self.manager.get_credential_public()
        mock_imports.assert_called_once()
        mock_credential_class.assert_called_once()
        assert credential == mock_credential

    @patch("function_app._ensure_azure_imports")
    @patch("function_app.ServiceBusManagementClient")
    def test_get_servicebus_client(self, mock_client_class, mock_imports):
        """Test Service Bus client initialization."""
        mock_client = Mock()
        mock_client_class.return_value = mock_client

        with patch.dict(os.environ, {"AZURE_SUBSCRIPTION_ID": "test-sub"}):
            # Create a new manager instance with the environment variable set
            manager = TestableSecretRotationManager()

            with patch.object(manager, "_get_credential") as mock_get_cred:
                mock_credential = Mock()
                mock_get_cred.return_value = mock_credential

                client = manager.get_servicebus_client_public()

                mock_imports.assert_called_once()
                mock_get_cred.assert_called_once()
                mock_client_class.assert_called_once_with(mock_credential, "test-sub")
                assert client == mock_client

    @patch("function_app._ensure_azure_imports")
    @patch("function_app.SecretClient")
    def test_get_keyvault_client(self, mock_client_class, mock_imports):
        """Test Key Vault client initialization."""
        mock_client = Mock()
        mock_client_class.return_value = mock_client

        with patch.object(self.manager, "_get_credential") as mock_get_cred:
            mock_credential = Mock()
            mock_get_cred.return_value = mock_credential

            self.manager.key_vault_uri = "https://test-kv.vault.azure.net/"
            client = self.manager.get_keyvault_client_public()

            mock_imports.assert_called_once()
            mock_get_cred.assert_called_once()
            mock_client_class.assert_called_once_with(
                vault_url="https://test-kv.vault.azure.net/", credential=mock_credential
            )
            assert client == mock_client

    @patch("time.sleep")
    def test_rotate_authorization_rule_keys(self, mock_sleep):
        """Test authorization rule key rotation."""
        mock_client = Mock()
        mock_keys = Mock()
        mock_keys.primary_connection_string = "primary-conn-str"
        mock_keys.secondary_connection_string = "secondary-conn-str"

        mock_final_keys = Mock()
        mock_final_keys.primary_connection_string = "new-primary-conn-str"
        mock_final_keys.secondary_connection_string = "new-secondary-conn-str"

        mock_client.namespaces.list_keys.side_effect = [mock_keys, mock_final_keys]

        with patch.object(
            self.manager, "_get_servicebus_client", return_value=mock_client
        ):
            primary, secondary = self.manager.rotate_authorization_rule_keys("TestRule")

            # Verify regenerate_keys was called twice (primary and secondary)
            assert mock_client.namespaces.regenerate_keys.call_count == 2

            # Verify list_keys was called twice
            assert mock_client.namespaces.list_keys.call_count == 2

            # Verify sleep was called for propagation delays
            assert mock_sleep.call_count == 3  # 30s, 300s, 30s

            assert primary == "new-primary-conn-str"
            assert secondary == "new-secondary-conn-str"

    def test_update_keyvault_secret(self):
        """Test Key Vault secret update."""
        mock_client = Mock()

        with patch.object(
            self.manager, "_get_keyvault_client", return_value=mock_client
        ):
            result = self.manager.update_keyvault_secret(
                "test-secret", "test-connection-string"
            )

            mock_client.set_secret.assert_called_once()
            call_args = mock_client.set_secret.call_args

            assert call_args[1]["name"] == "test-secret"
            assert call_args[1]["value"] == "test-connection-string"
            assert call_args[1]["content_type"] == "text/plain"
            assert "SecretType" in call_args[1]["tags"]
            assert result is True

    def test_perform_rotation_disabled(self):
        """Test rotation when disabled."""
        self.manager.rotation_enabled = False

        result = self.manager.perform_rotation()

        assert result["success"] is False
        assert "Secret rotation is disabled" in result["errors"]

    @patch("time.sleep")
    def test_perform_rotation_success(self, mock_sleep):
        """Test successful rotation."""
        self.manager.rotation_enabled = True

        with patch.object(
            self.manager, "rotate_authorization_rule_keys"
        ) as mock_rotate:
            with patch.object(self.manager, "update_keyvault_secret") as mock_update:
                mock_rotate.return_value = ("primary-conn", "secondary-conn")
                mock_update.return_value = True

                result = self.manager.perform_rotation()

                assert result["success"] is True
                assert (
                    len(result["rules_rotated"]) == 2
                )  # FunctionAppAccess and ReadOnlyAccess
                assert len(result["errors"]) == 0

    def test_test_connections(self):
        """Test connection testing."""
        mock_sb_client = Mock()
        mock_kv_client = Mock()
        mock_namespace = Mock()
        mock_namespace.status = "Active"

        mock_sb_client.namespaces.get.return_value = mock_namespace
        mock_kv_client.list_properties_of_secrets.return_value = iter([])

        with patch.object(
            self.manager, "_get_servicebus_client", return_value=mock_sb_client
        ):
            with patch.object(
                self.manager, "_get_keyvault_client", return_value=mock_kv_client
            ):
                result = self.manager.test_connections()

                assert result["service_bus"]["status"] == "healthy"
                assert result["key_vault"]["status"] == "healthy"


class TestFunctionEndpoints:
    """Test cases for Azure Function endpoints."""

    @patch("function_app.rotation_manager")
    def test_rotation_health_healthy(self, mock_manager):
        """Test health endpoint when all services are healthy."""
        mock_manager.test_connections.return_value = {
            "service_bus": {"status": "healthy"},
            "key_vault": {"status": "healthy"},
        }
        mock_manager.rotation_enabled = True
        mock_manager.namespace_name = "test-namespace"
        mock_manager.resource_group_name = "test-rg"
        mock_manager.key_vault_uri = "https://test-kv.vault.azure.net/"
        mock_manager.auth_rules = [{"name": "TestRule"}]

        mock_req = Mock()
        response = rotation_health(mock_req)

        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["status"] == "healthy"

    @patch("function_app.rotation_manager")
    def test_manual_rotation_success(self, mock_manager):
        """Test manual rotation endpoint."""
        mock_manager.perform_rotation.return_value = {
            "success": True,
            "rotation_id": "test-id",
            "rules_rotated": [],
        }

        mock_req = Mock()
        response = manual_rotation(mock_req)

        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["success"] is True

    def test_rotation_info(self):
        """Test info endpoint."""
        mock_req = Mock()
        response = rotation_info(mock_req)

        assert response.status_code == 200
        response_data = json.loads(response.get_body().decode())
        assert response_data["name"] == "Azure Functions - Service Bus Secret Rotation"
        assert "functions" in response_data
        assert "endpoints" in response_data


if __name__ == "__main__":
    pytest.main([__file__])
