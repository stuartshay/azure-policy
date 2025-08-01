"""
Tests for Azure Policy JSON validation and structure.

This module tests the validity of Azure Policy definitions including:
- JSON syntax validation
- Policy structure validation
- Parameter validation
- Policy rule validation
- Naming convention compliance
"""

import json
from pathlib import Path
from typing import Any, Dict

import pytest

from tests.conftest import PolicyTestHelper


class TestPolicyJSONValidation:
    """Test cases for policy JSON syntax and structure validation."""

    def test_all_policy_files_are_valid_json(self, policies_dir):
        """Test that all policy files contain valid JSON."""
        policy_files = list(policies_dir.glob("*.json"))
        assert len(policy_files) > 0, "No policy files found to test"

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                try:
                    json.load(f)
                except json.JSONDecodeError as e:
                    pytest.fail(f"Invalid JSON in {policy_file.name}: {e}")

    def test_policy_structure_validation(self, policies_dir, policy_helper):
        """Test that all policies have required structure."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            errors = policy_helper.validate_policy_structure(policy)
            assert (
                not errors
            ), f"Policy {policy_file.name} has validation errors: {errors}"

    def test_policy_naming_conventions(self, policies_dir):
        """Test that policy files follow naming conventions."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            # Policy files should use kebab-case
            filename = policy_file.stem
            assert (
                "-" in filename
            ), f"Policy file {policy_file.name} should use kebab-case naming"
            assert (
                filename.islower()
            ), f"Policy file {policy_file.name} should be lowercase"
            assert not filename.startswith(
                "-"
            ), f"Policy file {policy_file.name} should not start with hyphen"
            assert not filename.endswith(
                "-"
            ), f"Policy file {policy_file.name} should not end with hyphen"

    def test_policy_display_names_are_descriptive(self, policies_dir):
        """Test that policies have descriptive display names."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            if "displayName" in policy:
                display_name = policy["displayName"]
                assert (
                    len(display_name) >= 10
                ), f"Policy {policy_file.name} displayName too short: '{display_name}'"
                assert (
                    display_name != policy_file.stem
                ), f"Policy {policy_file.name} displayName should differ from filename"

    def test_policy_descriptions_are_present(self, policies_dir):
        """Test that all policies have descriptions."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            assert (
                "description" in policy
            ), f"Policy {policy_file.name} missing description"
            description = policy["description"]
            assert (
                len(description) >= 20
            ), f"Policy {policy_file.name} description too short: '{description}'"


class TestPolicyParameters:
    """Test cases for policy parameter validation."""

    def test_policy_parameters_have_valid_types(self, policies_dir, policy_helper):
        """Test that policy parameters use valid types."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            errors = policy_helper.validate_policy_parameters(policy)
            assert (
                not errors
            ), f"Policy {policy_file.name} has parameter validation errors: {errors}"

    def test_effect_parameters_have_allowed_values(self, policies_dir):
        """Test that effect parameters define allowedValues."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            if "parameters" in policy:
                for param_name, param_def in policy["parameters"].items():
                    if "effect" in param_name.lower():
                        assert (
                            "allowedValues" in param_def
                        ), f"Effect parameter in {policy_file.name} should have allowedValues"
                        allowed_values = param_def["allowedValues"]
                        valid_effects = [
                            "Audit",
                            "Deny",
                            "Disabled",
                            "AuditIfNotExists",
                            "DeployIfNotExists",
                            "Append",
                            "Modify",
                        ]
                        for value in allowed_values:
                            assert (
                                value in valid_effects
                            ), f"Invalid effect value '{value}' in {policy_file.name}"


class TestPolicyRules:
    """Test cases for policy rule validation."""

    def test_policy_rules_have_if_then_structure(self, policies_dir):
        """Test that policy rules have proper if-then structure."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            if "policyRule" in policy:
                policy_rule = policy["policyRule"]
                assert (
                    "if" in policy_rule
                ), f"Policy {policy_file.name} missing 'if' condition"
                assert (
                    "then" in policy_rule
                ), f"Policy {policy_file.name} missing 'then' action"

    def test_policy_effects_are_valid(self, policies_dir, policy_helper):
        """Test that policies use valid effect values."""
        policy_files = list(policies_dir.glob("*.json"))
        valid_effects = [
            "Audit",
            "Deny",
            "Disabled",
            "AuditIfNotExists",
            "DeployIfNotExists",
            "Append",
            "Modify",
        ]

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            effects = policy_helper.extract_policy_effects(policy)
            for effect in effects:
                # Handle parameter references like "[parameters('effect')]"
                if not (effect.startswith("[") and effect.endswith("]")):
                    assert (
                        effect in valid_effects
                    ), f"Invalid effect '{effect}' in {policy_file.name}"


class TestPolicyCompliance:
    """Test cases for policy compliance and best practices."""

    def test_storage_policies_target_correct_resource_types(self, policies_dir):
        """Test that storage policies target storage resource types."""
        storage_policy_files = [f for f in policies_dir.glob("storage-*.json")]

        for policy_file in storage_policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            policy_content = json.dumps(policy).lower()
            assert (
                "microsoft.storage" in policy_content
            ), f"Storage policy {policy_file.name} should target Microsoft.Storage resources"

    def test_resource_group_policies_have_appropriate_mode(self, policies_dir):
        """Test that resource group policies use appropriate mode."""
        rg_policy_files = [f for f in policies_dir.glob("resource-group-*.json")]

        for policy_file in rg_policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            if "mode" in policy:
                # Resource group policies typically use "All" mode
                assert policy["mode"] in [
                    "All",
                    "Indexed",
                ], f"Resource group policy {policy_file.name} should use 'All' or 'Indexed' mode"


class TestSamplePolicyValidation:
    """Test cases using sample policy data for validation logic."""

    def test_valid_policy_passes_validation(self, sample_policy_json, policy_helper):
        """Test that a valid policy passes all validation checks."""
        errors = policy_helper.validate_policy_structure(sample_policy_json)
        assert not errors, f"Valid policy should pass validation: {errors}"

    def test_invalid_policy_fails_validation(self, invalid_policy_json, policy_helper):
        """Test that an invalid policy fails validation appropriately."""
        errors = policy_helper.validate_policy_structure(invalid_policy_json)
        assert errors, "Invalid policy should fail validation"
        assert "Missing required field: description" in errors
        assert "Missing required field: mode" in errors
        assert "Missing required field: policyRule" in errors

    def test_policy_parameter_validation_logic(self, policy_helper):
        """Test parameter validation with various scenarios."""
        # Valid parameters
        valid_policy = {
            "displayName": "Test Policy",
            "description": "Test policy description",
            "mode": "All",
            "parameters": {
                "effect": {
                    "type": "String",
                    "defaultValue": "Audit",
                    "allowedValues": ["Audit", "Deny"],
                }
            },
            "policyRule": {"if": {}, "then": {}},
        }

        errors = policy_helper.validate_policy_parameters(valid_policy)
        assert not errors, f"Valid parameters should pass validation: {errors}"

        # Invalid parameters
        invalid_policy = {
            "displayName": "Test Policy",
            "description": "Test policy description",
            "mode": "All",
            "parameters": {
                "badParam": {"type": "InvalidType"},
                "missingType": {"defaultValue": "test"},
            },
            "policyRule": {"if": {}, "then": {}},
        }

        errors = policy_helper.validate_policy_parameters(invalid_policy)
        assert errors, "Invalid parameters should fail validation"
        assert any("invalid type" in error.lower() for error in errors)
        assert any("missing required 'type' field" in error for error in errors)
