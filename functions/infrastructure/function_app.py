"""
Azure Functions Infrastructure Management - Service Bus Secret Rotation

This module contains an Azure Function with a timer trigger that rotates
Service Bus authorization rule keys every 24 hours and updates Key Vault secrets.
It includes comprehensive error handling, audit logging, and monitoring capabilities.
"""

from datetime import datetime, timedelta, timezone
import json
import logging
import os
from typing import Any, Dict, List, Tuple, TypedDict
import uuid

import azure.functions as func


# Type definitions for better type checking
class RotationRuleResult(TypedDict):
    """Type definition for individual rule rotation result."""

    rule_name: str
    secret_name: str
    rotated_at: str
    status: str


class RotationResults(TypedDict):
    """Type definition for complete rotation results."""

    rotation_id: str
    start_time: str
    namespace: str
    resource_group: str
    rules_rotated: List[RotationRuleResult]
    errors: List[str]
    success: bool
    end_time: str
    duration_seconds: float


# Initialize the function app
app = func.FunctionApp()

# Global rotation counter for tracking
rotation_counter = 0

# Lazy imports for Azure services to avoid import errors during cold start
ServiceBusManagementClient = None
KeyVaultSecret = None
SecretClient = None
DefaultAzureCredential = None
ResourceManagementClient = None
ServiceBusError = None


def _ensure_azure_imports() -> None:
    """Ensure Azure SDK modules are imported when needed."""
    global ServiceBusManagementClient, KeyVaultSecret, SecretClient
    global DefaultAzureCredential, ResourceManagementClient, ServiceBusError

    if ServiceBusManagementClient is None:
        try:
            from azure.identity import (
                DefaultAzureCredential as _DefaultAzureCredential,  # pyright: ignore
            )
            from azure.keyvault.secrets import (
                KeyVaultSecret as _KeyVaultSecret,  # pyright: ignore
            )
            from azure.keyvault.secrets import (
                SecretClient as _SecretClient,  # pyright: ignore
            )
            from azure.mgmt.resource import (
                ResourceManagementClient as _ResourceManagementClient,  # pyright: ignore
            )
            from azure.mgmt.servicebus import (
                ServiceBusManagementClient as _ServiceBusManagementClient,  # pyright: ignore
            )
            from azure.servicebus.exceptions import (
                ServiceBusError as _ServiceBusError,  # pyright: ignore
            )

            ServiceBusManagementClient = _ServiceBusManagementClient
            KeyVaultSecret = _KeyVaultSecret
            SecretClient = _SecretClient
            DefaultAzureCredential = _DefaultAzureCredential
            ResourceManagementClient = _ResourceManagementClient
            ServiceBusError = _ServiceBusError
        except ImportError as e:
            logging.error(f"Failed to import Azure SDK modules: {e}")
            raise


class SecretRotationManager:
    """Manages Service Bus secret rotation with Key Vault integration."""

    def __init__(self) -> None:
        self.subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
        self.resource_group_name = os.environ.get(
            "SERVICE_BUS_RESOURCE_GROUP", "rg-azpolicy-dev-eastus"
        )
        self.namespace_name = os.environ.get(
            "SERVICE_BUS_NAMESPACE", "sb-azpolicy-dev-eastus-001"
        )
        self.key_vault_uri = os.environ.get("KEY_VAULT_URI")
        self.rotation_enabled = (
            os.environ.get("ROTATION_ENABLED", "true").lower() == "true"
        )

        # Authorization rules to rotate
        self.auth_rules = [
            {
                "name": "FunctionAppAccess",
                "secret_name": "servicebus-function-app-connection-string",  # pragma: allowlist secret
            },
            {
                "name": "ReadOnlyAccess",
                "secret_name": "servicebus-read-only-connection-string",  # pragma: allowlist secret
            },
        ]

        # Add admin access if configured
        if os.environ.get("ROTATE_ADMIN_ACCESS", "false").lower() == "true":
            self.auth_rules.append(
                {
                    "name": "AdminAccess",
                    "secret_name": "servicebus-admin-connection-string",  # pragma: allowlist secret
                }
            )

        self.credential = None
        self.servicebus_client = None
        self.keyvault_client = None

    def _get_credential(self) -> Any:
        """Get Azure credential using Managed Identity."""
        if not self.credential:
            _ensure_azure_imports()
            if DefaultAzureCredential is not None:
                self.credential = DefaultAzureCredential()
            else:
                raise RuntimeError("DefaultAzureCredential not available")
        return self.credential

    def _get_servicebus_client(self) -> Any:
        """Get or create Service Bus management client."""
        if not self.servicebus_client:
            if not self.subscription_id:
                raise ValueError("AZURE_SUBSCRIPTION_ID not configured")

            _ensure_azure_imports()
            credential = self._get_credential()

            if ServiceBusManagementClient is not None:
                self.servicebus_client = ServiceBusManagementClient(
                    credential, self.subscription_id
                )
            else:
                raise RuntimeError("ServiceBusManagementClient not available")

        return self.servicebus_client

    def _get_keyvault_client(self) -> Any:
        """Get or create Key Vault secret client."""
        if not self.keyvault_client:
            if not self.key_vault_uri:
                raise ValueError("KEY_VAULT_URI not configured")

            _ensure_azure_imports()
            credential = self._get_credential()

            if SecretClient is not None:
                self.keyvault_client = SecretClient(
                    vault_url=self.key_vault_uri, credential=credential
                )
            else:
                raise RuntimeError("SecretClient not available")

        return self.keyvault_client

    def rotate_authorization_rule_keys(self, rule_name: str) -> Tuple[str, str]:
        """
        Rotate keys for a Service Bus authorization rule.

        Args:
            rule_name: Name of the authorization rule

        Returns:
            Tuple of (primary_connection_string, secondary_connection_string)
        """
        try:
            client = self._get_servicebus_client()

            # Regenerate primary key
            logging.info(f"Regenerating primary key for rule: {rule_name}")
            client.namespaces.regenerate_keys(
                resource_group_name=self.resource_group_name,
                namespace_name=self.namespace_name,
                authorization_rule_name=rule_name,
                parameters={"key_type": "PrimaryKey"},
            )

            # Wait for key propagation
            import time

            time.sleep(30)

            # Get updated keys
            keys = client.namespaces.list_keys(
                resource_group_name=self.resource_group_name,
                namespace_name=self.namespace_name,
                authorization_rule_name=rule_name,
            )

            keys.primary_connection_string
            keys.secondary_connection_string

            logging.info(f"Successfully rotated primary key for rule: {rule_name}")

            # Wait before rotating secondary key
            time.sleep(300)  # 5 minutes grace period

            # Regenerate secondary key
            logging.info(f"Regenerating secondary key for rule: {rule_name}")
            client.namespaces.regenerate_keys(
                resource_group_name=self.resource_group_name,
                namespace_name=self.namespace_name,
                authorization_rule_name=rule_name,
                parameters={"key_type": "SecondaryKey"},
            )

            # Wait for secondary key propagation
            time.sleep(30)

            # Get final keys
            final_keys = client.namespaces.list_keys(
                resource_group_name=self.resource_group_name,
                namespace_name=self.namespace_name,
                authorization_rule_name=rule_name,
            )

            logging.info(f"Successfully rotated secondary key for rule: {rule_name}")

            return (
                final_keys.primary_connection_string,
                final_keys.secondary_connection_string,
            )

        except Exception as e:
            logging.error(f"Error rotating keys for rule {rule_name}: {str(e)}")
            raise

    def update_keyvault_secret(self, secret_name: str, connection_string: str) -> bool:
        """
        Update a Key Vault secret with new connection string.

        Args:
            secret_name: Name of the secret in Key Vault
            connection_string: New connection string value

        Returns:
            bool: True if successful, False otherwise
        """
        try:
            client = self._get_keyvault_client()

            # Set expiration date for 30 days from now
            expires_on = datetime.now(timezone.utc) + timedelta(days=30)

            # Update the secret
            client.set_secret(
                name=secret_name,
                value=connection_string,
                expires_on=expires_on,
                content_type="text/plain",
                tags={
                    "SecretType": "servicebus-connection-string",  # pragma: allowlist secret
                    "RotatedBy": "infrastructure-function",
                    "RotatedAt": datetime.now(timezone.utc).isoformat(),
                    "Namespace": self.namespace_name,
                },
            )

            logging.info(f"Successfully updated Key Vault secret: {secret_name}")
            return True

        except Exception as e:
            logging.error(f"Error updating Key Vault secret {secret_name}: {str(e)}")
            return False

    def perform_rotation(self) -> RotationResults:
        """
        Perform complete secret rotation for all configured authorization rules.

        Returns:
            Dict containing rotation results
        """
        rotation_id = str(uuid.uuid4())
        start_time = datetime.now(timezone.utc)
        results: RotationResults = {
            "rotation_id": rotation_id,
            "start_time": start_time.isoformat(),
            "namespace": self.namespace_name,
            "resource_group": self.resource_group_name,
            "rules_rotated": [],
            "errors": [],
            "success": False,
            "end_time": "",
            "duration_seconds": 0.0,
        }

        if not self.rotation_enabled:
            results["errors"].append("Secret rotation is disabled")
            results["end_time"] = datetime.now(timezone.utc).isoformat()
            results["duration_seconds"] = (
                datetime.now(timezone.utc) - start_time
            ).total_seconds()
            return results

        try:
            for rule_config in self.auth_rules:
                rule_name = rule_config["name"]
                secret_name = rule_config["secret_name"]

                try:
                    logging.info(f"Starting rotation for rule: {rule_name}")

                    # Rotate the authorization rule keys
                    primary_conn_str, secondary_conn_str = (
                        self.rotate_authorization_rule_keys(rule_name)
                    )

                    # Update Key Vault secret with new primary connection string
                    secret_updated = self.update_keyvault_secret(
                        secret_name, primary_conn_str
                    )

                    if secret_updated:
                        results["rules_rotated"].append(
                            {
                                "rule_name": rule_name,
                                "secret_name": secret_name,
                                "rotated_at": datetime.now(timezone.utc).isoformat(),
                                "status": "success",
                            }
                        )
                        logging.info(
                            f"Successfully completed rotation for rule: {rule_name}"
                        )
                    else:
                        results["errors"].append(
                            f"Failed to update Key Vault secret for rule: {rule_name}"
                        )

                except Exception as e:
                    error_msg = f"Failed to rotate rule {rule_name}: {str(e)}"
                    results["errors"].append(error_msg)
                    logging.error(error_msg)

            # Determine overall success
            results["success"] = (
                len(results["rules_rotated"]) > 0 and len(results["errors"]) == 0
            )
            results["end_time"] = datetime.now(timezone.utc).isoformat()
            results["duration_seconds"] = (
                datetime.now(timezone.utc) - start_time
            ).total_seconds()

            return results

        except Exception as e:
            results["errors"].append(f"Critical error during rotation: {str(e)}")
            results["end_time"] = datetime.now(timezone.utc).isoformat()
            results["duration_seconds"] = (
                datetime.now(timezone.utc) - start_time
            ).total_seconds()
            logging.error(f"Critical error during secret rotation: {str(e)}")
            return results

    def test_connections(self) -> Dict[str, Any]:
        """
        Test connections to Azure services.

        Returns:
            Dict containing connection test results
        """
        results = {
            "service_bus": {"status": "unknown", "error": None},
            "key_vault": {"status": "unknown", "error": None},
        }

        # Test Service Bus connection
        try:
            client = self._get_servicebus_client()
            # Try to get namespace info
            namespace = client.namespaces.get(
                resource_group_name=self.resource_group_name,
                namespace_name=self.namespace_name,
            )
            results["service_bus"]["status"] = "healthy"
            results["service_bus"]["namespace_status"] = namespace.status
        except Exception as e:
            results["service_bus"]["status"] = "unhealthy"
            results["service_bus"]["error"] = str(e)

        # Test Key Vault connection
        try:
            client = self._get_keyvault_client()
            # Try to list secrets (just to test connection)
            list(client.list_properties_of_secrets(max_page_size=1))
            results["key_vault"]["status"] = "healthy"
        except Exception as e:
            results["key_vault"]["status"] = "unhealthy"
            results["key_vault"]["error"] = str(e)

        return results


# Initialize rotation manager
rotation_manager = SecretRotationManager()


@app.function_name(name="ServiceBusSecretRotation")
@app.timer_trigger(schedule="0 0 0 * * *", arg_name="timer", run_on_startup=False)
def service_bus_secret_rotation(timer: func.TimerRequest) -> None:
    """
    Timer-triggered function that rotates Service Bus secrets every 24 hours.

    This function runs daily at midnight UTC and rotates Service Bus authorization
    rule keys, then updates the corresponding Key Vault secrets.

    Args:
        timer: Timer request object containing schedule information
    """
    global rotation_counter
    rotation_counter += 1

    # Log timer execution
    utc_timestamp = datetime.now(timezone.utc)
    logging.info(f"Secret rotation timer triggered at {utc_timestamp.isoformat()}Z")

    if timer.past_due:
        logging.warning("Secret rotation timer is running late!")

    try:
        # Perform the rotation
        rotation_results = rotation_manager.perform_rotation()

        # Log results
        if rotation_results["success"]:
            logging.info(
                f"Secret rotation completed successfully. Rotation ID: {rotation_results['rotation_id']}"
            )
            logging.info(
                f"Rotated {len(rotation_results['rules_rotated'])} authorization rules"
            )
        else:
            logging.error(
                f"Secret rotation failed. Rotation ID: {rotation_results['rotation_id']}"
            )
            logging.error(f"Errors: {rotation_results['errors']}")

        # Log detailed results for audit trail
        logging.info(f"Rotation results: {json.dumps(rotation_results, indent=2)}")

    except Exception as e:
        logging.error(
            f"Critical error in secret rotation timer #{rotation_counter}: {str(e)}"
        )


@app.function_name(name="RotationHealth")
@app.route(route="health", methods=["GET"])
def rotation_health(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint for the secret rotation function.

    Args:
        req: HTTP request object

    Returns:
        JSON response with health status
    """
    logging.info("Rotation health check endpoint accessed")

    try:
        # Test connections to Azure services
        connection_tests = rotation_manager.test_connections()

        # Overall health determination
        service_bus_healthy = connection_tests["service_bus"]["status"] == "healthy"
        key_vault_healthy = connection_tests["key_vault"]["status"] == "healthy"
        overall_healthy = service_bus_healthy and key_vault_healthy

        status_code = 200 if overall_healthy else 503

        health_data = {
            "status": "healthy" if overall_healthy else "unhealthy",
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "service": "Azure Functions - Infrastructure Secret Rotation",
            "version": "1.0.0",
            "components": {
                "rotation_function": {
                    "status": "healthy",
                    "rotation_counter": rotation_counter,
                    "schedule": "daily at midnight UTC",
                    "enabled": rotation_manager.rotation_enabled,
                },
                "service_bus": connection_tests["service_bus"],
                "key_vault": connection_tests["key_vault"],
            },
            "configuration": {
                "namespace": rotation_manager.namespace_name,
                "resource_group": rotation_manager.resource_group_name,
                "key_vault_uri": rotation_manager.key_vault_uri,
                "auth_rules_count": len(rotation_manager.auth_rules),
            },
        }

        return func.HttpResponse(
            json.dumps(health_data, indent=2),
            status_code=status_code,
            headers={"Content-Type": "application/json"},
        )

    except Exception as e:
        logging.error(f"Error in rotation health check: {str(e)}")

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


@app.function_name(name="ManualRotation")
@app.route(route="rotate", methods=["POST"])
def manual_rotation(req: func.HttpRequest) -> func.HttpResponse:
    """
    Manual endpoint to trigger secret rotation.

    Args:
        req: HTTP request object

    Returns:
        JSON response with rotation results
    """
    logging.info("Manual rotation endpoint accessed")

    try:
        # Perform the rotation
        rotation_results = rotation_manager.perform_rotation()

        status_code = 200 if rotation_results["success"] else 500

        return func.HttpResponse(
            json.dumps(rotation_results, indent=2),
            status_code=status_code,
            headers={"Content-Type": "application/json"},
        )

    except Exception as e:
        logging.error(f"Error in manual rotation: {str(e)}")

        error_response = {
            "status": "error",
            "message": "Manual rotation failed",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        }

        return func.HttpResponse(
            json.dumps(error_response, indent=2),
            status_code=500,
            headers={"Content-Type": "application/json"},
        )


@app.function_name(name="RotationInfo")
@app.route(route="info", methods=["GET"])
def rotation_info(req: func.HttpRequest) -> func.HttpResponse:
    """
    Information endpoint for the secret rotation function.

    Args:
        req: HTTP request object

    Returns:
        JSON response with function information
    """
    logging.info("Rotation info endpoint accessed")

    info_data = {
        "name": "Azure Functions - Service Bus Secret Rotation",
        "description": "Timer-triggered function that rotates Service Bus authorization rule keys every 24 hours",
        "version": "1.0.0",
        "runtime": "Python 3.13",
        "framework": "Azure Functions v4",
        "functions": {
            "ServiceBusSecretRotation": {
                "type": "timer",
                "schedule": "daily at midnight UTC",
                "description": "Rotates Service Bus authorization rule keys and updates Key Vault secrets",
                "rotation_counter": rotation_counter,
                "enabled": rotation_manager.rotation_enabled,
            }
        },
        "endpoints": {
            "health": {
                "path": "/api/health",
                "methods": ["GET"],
                "description": "Health check for rotation services",
            },
            "rotate": {
                "path": "/api/rotate",
                "methods": ["POST"],
                "description": "Manual trigger for secret rotation",
            },
            "info": {
                "path": "/api/info",
                "methods": ["GET"],
                "description": "Function app information",
            },
        },
        "configuration": {
            "service_bus_namespace": rotation_manager.namespace_name,
            "resource_group": rotation_manager.resource_group_name,
            "key_vault_uri": rotation_manager.key_vault_uri,
            "authorization_rules": [
                rule["name"] for rule in rotation_manager.auth_rules
            ],
            "rotation_enabled": rotation_manager.rotation_enabled,
        },
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }

    return func.HttpResponse(
        json.dumps(info_data, indent=2),
        status_code=200,
        headers={"Content-Type": "application/json"},
    )
