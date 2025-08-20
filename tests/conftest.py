"""
Shared test configuration and fixtures for Azure Policy testing.

This module provides common test fixtures, utilities, and configuration
that can be used across different test modules.
"""

import json
import os
from pathlib import Path
import sys
import tempfile
from typing import Any, Dict, List

import pytest

# Add function app directories to Python path for test discovery
root_path = Path(__file__).parent.parent
sys.path.insert(0, str(root_path / "functions" / "basic"))
sys.path.insert(0, str(root_path / "functions" / "advanced"))


@pytest.fixture
def project_root() -> Path:
    """Get the project root directory."""
    return Path(__file__).parent.parent


@pytest.fixture
def policies_dir(project_root_fixture: Path) -> Path:
    """Get the policies directory."""
    return project_root_fixture / "policies"


@pytest.fixture
def sample_policy_json():
    """Sample policy JSON for testing."""
    return {
        "displayName": "Test Policy",
        "description": "A test policy for validation",
        "mode": "All",
        "parameters": {
            "effect": {
                "type": "String",
                "defaultValue": "Audit",
                "allowedValues": ["Audit", "Deny", "Disabled"],
            }
        },
        "policyRule": {
            "if": {"field": "type", "equals": "Microsoft.Storage/storageAccounts"},
            "then": {"effect": "[parameters('effect')]"},
        },
    }


@pytest.fixture
def invalid_policy_json():
    """Invalid policy JSON for testing error handling."""
    return {
        "displayName": "Invalid Policy",
        # Missing required fields: description, mode, policyRule
        "parameters": {},
    }


@pytest.fixture
def temp_policy_file(sample_policy_json_fixture):
    """Create a temporary policy file for testing."""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump(sample_policy_json_fixture, f, indent=2)
        temp_file = f.name

    yield temp_file

    # Cleanup
    if os.path.exists(temp_file):
        os.unlink(temp_file)


@pytest.fixture
def mock_azure_resource():
    """Mock Azure resource for testing policy evaluation."""
    return {
        "id": (
            "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/"
            "providers/Microsoft.Storage/storageAccounts/teststorage"
        ),
        "name": "teststorage",
        "type": "Microsoft.Storage/storageAccounts",
        "location": "eastus",
        "tags": {"Environment": "test", "CostCenter": "IT"},
        "properties": {
            "provisioningState": "Succeeded",
            "primaryEndpoints": {"blob": "https://teststorage.blob.core.windows.net/"},
        },
    }


class PolicyTestHelper:
    """Helper class for policy testing operations."""

    @staticmethod
    def validate_policy_structure(policy: Dict[str, Any]) -> List[str]:
        """
        Validate basic policy structure and return list of errors.

        Args:
            policy: Policy JSON to validate

        Returns:
            List of validation errors (empty if valid)
        """
        errors: list[str] = []
        required_fields = ["displayName", "description", "mode", "policyRule"]

        for field in required_fields:
            if field not in policy:
                errors.append(f"Missing required field: {field}")

        # Validate mode values
        if "mode" in policy:
            valid_modes = [
                "All",
                "Indexed",
                "Microsoft.KeyVault.Data",
                "Microsoft.ContainerService.Data",
                "Microsoft.Kubernetes.Data",
            ]
            if policy["mode"] not in valid_modes:
                errors.append(
                    f"Invalid mode: {policy['mode']}. Must be one of {valid_modes}"
                )

        # Validate policyRule structure
        if "policyRule" in policy:
            policy_rule = policy["policyRule"]
            if not isinstance(policy_rule, dict):
                errors.append("policyRule must be an object")
            elif "if" not in policy_rule or "then" not in policy_rule:
                errors.append("policyRule must contain 'if' and 'then' properties")

        return errors

    @staticmethod
    def validate_policy_parameters(policy: Dict[str, Any]) -> List[str]:
        """
        Validate policy parameters structure.

        Args:
            policy: Policy JSON to validate

        Returns:
            List of parameter validation errors
        """
        errors: list[str] = []

        if "parameters" not in policy:
            return errors  # Parameters are optional

        parameters = policy["parameters"]
        if not isinstance(parameters, dict):
            errors.append("Parameters must be an object")
            return errors

        for param_name, param_def in parameters.items():
            if not isinstance(param_def, dict):
                errors.append(f"Parameter '{param_name}' definition must be an object")
                continue

            if "type" not in param_def:
                errors.append(f"Parameter '{param_name}' missing required 'type' field")

            # Validate parameter type
            valid_types = ["String", "Array", "Object", "Boolean", "Integer", "Float"]
            if "type" in param_def and param_def["type"] not in valid_types:
                errors.append(
                    f"Parameter '{param_name}' has invalid type: {param_def['type']}"
                )

        return errors

    @staticmethod
    def extract_policy_effects(policy: Dict[str, Any]) -> List[str]:
        """
        Extract all possible effects from a policy.

        Args:
            policy: Policy JSON to analyze

        Returns:
            List of effects found in the policy
        """
        effects = []

        def find_effects(obj):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    if key == "effect":
                        if isinstance(value, str):
                            effects.append(value)
                        elif isinstance(value, list):
                            effects.extend(value)
                    else:
                        find_effects(value)
            elif isinstance(obj, list):
                for item in obj:
                    find_effects(item)

        find_effects(policy)
        return list(set(effects))  # Remove duplicates


@pytest.fixture
def policy_helper():
    """Provide PolicyTestHelper instance."""
    return PolicyTestHelper()
