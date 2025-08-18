"""
Tests for existing Azure Policy files in the policies directory.

This module tests the specific policy files that exist in the project:
- resource-group-naming.json
- storage-naming-convention.json
- storage-naming-parameters.json
- storage-naming-rule.json
"""

import json

import pytest


class TestExistingPolicyFiles:
    """Test cases for the existing policy files in the project."""

    def test_resource_group_naming_policy(self, policies_dir):
        """Test the resource group naming policy."""
        policy_file = policies_dir / "resource-group-naming.json"
        if not policy_file.exists():
            pytest.skip("Resource group naming policy file not found")

        with open(policy_file, "r", encoding="utf-8") as f:
            policy = json.load(f)

        # Basic structure validation
        assert "displayName" in policy
        assert "description" in policy
        assert "mode" in policy
        assert "policyRule" in policy

        # Specific validations for resource group naming
        assert (
            "resource" in policy["displayName"].lower()
            or "group" in policy["displayName"].lower()
        )
        assert policy["mode"] == "All"  # Resource group policies should use All mode

    def test_storage_naming_convention_policy(self, policies_dir):
        """Test the storage naming convention policy."""
        policy_file = policies_dir / "storage-naming-convention.json"
        if not policy_file.exists():
            pytest.skip("Storage naming convention policy file not found")

        with open(policy_file, "r", encoding="utf-8") as f:
            policy = json.load(f)

        # Basic structure validation
        assert "displayName" in policy
        assert "description" in policy
        assert "policyRule" in policy

        # Specific validations for storage naming
        policy_str = json.dumps(policy).lower()
        assert "storage" in policy_str
        assert "microsoft.storage" in policy_str

    def test_storage_naming_parameters_policy(self, policies_dir):
        """Test the storage naming parameters policy."""
        policy_file = policies_dir / "storage-naming-parameters.json"
        if not policy_file.exists():
            pytest.skip("Storage naming parameters policy file not found")

        with open(policy_file, "r", encoding="utf-8") as f:
            policy = json.load(f)

        # Should have parameters since it's a parameters policy
        assert "parameters" in policy
        assert len(policy["parameters"]) > 0

    def test_storage_naming_rule_policy(self, policies_dir):
        """Test the storage naming rule policy."""
        policy_file = policies_dir / "storage-naming-rule.json"
        if not policy_file.exists():
            pytest.skip("Storage naming rule policy file not found")

        with open(policy_file, "r", encoding="utf-8") as f:
            policy = json.load(f)

        # Basic structure validation
        assert "policyRule" in policy
        assert "if" in policy["policyRule"]
        assert "then" in policy["policyRule"]

    def test_all_existing_policies_have_consistent_structure(self, policies_dir):
        """Test that all existing policies follow consistent structure."""
        policy_files = list(policies_dir.glob("*.json"))

        if not policy_files:
            pytest.skip("No policy files found to test")

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            # All policies should have these basic fields
            required_fields = ["displayName", "description"]
            for field in required_fields:
                assert field in policy, f"Policy {policy_file.name} missing {field}"

            # displayName should be descriptive
            assert (
                len(policy["displayName"]) > 5
            ), f"Policy {policy_file.name} displayName too short"

            # description should be meaningful
            assert (
                len(policy["description"]) > 10
            ), f"Policy {policy_file.name} description too short"


class TestPolicyIntegration:
    """Integration tests for policy files with Azure CLI simulation."""

    def test_policy_files_can_be_created_as_definitions(self, policies_dir):
        """Test that policy files have the structure needed for Azure CLI."""
        policy_files = list(policies_dir.glob("*.json"))

        if not policy_files:
            pytest.skip("No policy files found to test")

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            # Simulate what Azure CLI would expect
            required_for_cli = ["displayName", "description", "policyRule"]
            for field in required_for_cli:
                assert (
                    field in policy
                ), f"Policy {policy_file.name} missing {field} required for Azure CLI"

            # Mode is required for policy definitions
            if "mode" not in policy:
                # Default mode should be assumed as "Indexed"
                pytest.warn(
                    f"Policy {policy_file.name} missing mode field, will default to 'Indexed'"
                )

    def test_policy_rules_reference_valid_azure_resource_types(self, policies_dir):
        """Test that policy rules reference valid Azure resource types."""
        policy_files = list(policies_dir.glob("*.json"))

        # Common Azure resource type patterns
        valid_resource_patterns = [
            "Microsoft.Storage/storageAccounts",
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Network/virtualNetworks",
            "Microsoft.Resources/resourceGroups",
            "Microsoft.KeyVault/vaults",
            "Microsoft.Web/sites",
        ]

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            policy_str = json.dumps(policy)

            # If the policy references resource types, they should be valid
            if "Microsoft." in policy_str:
                # Extract resource type references (simplified check)
                found_valid_pattern = False
                for pattern in valid_resource_patterns:
                    if pattern in policy_str:
                        found_valid_pattern = True
                        break

                # This is a warning rather than failure since there might be newer resource types
                if not found_valid_pattern:
                    pytest.warn(
                        f"Policy {policy_file.name} references Microsoft resources but no common patterns found"
                    )


class TestPolicyNamingStandards:
    """Test cases for policy naming standards and conventions."""

    def test_policy_files_follow_naming_convention(self, policies_dir):
        """Test that policy files follow the expected naming convention."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            filename = policy_file.stem

            # Should be kebab-case
            assert (
                "-" in filename
            ), f"Policy file {policy_file.name} should use kebab-case"
            assert (
                filename.islower()
            ), f"Policy file {policy_file.name} should be lowercase"

            # Should indicate resource type and purpose
            # Examples: storage-naming-convention, resource-group-naming
            parts = filename.split("-")
            assert (
                len(parts) >= 2
            ), f"Policy file {policy_file.name} should have resource-type and purpose"

    def test_storage_policies_have_consistent_naming(self, policies_dir):
        """Test that storage-related policies have consistent naming."""
        storage_files = list(policies_dir.glob("storage-*.json"))

        if not storage_files:
            pytest.skip("No storage policy files found")

        for policy_file in storage_files:
            filename = policy_file.stem
            assert filename.startswith(
                "storage-"
            ), f"Storage policy {policy_file.name} should start with 'storage-'"

            # Common storage policy purposes
            valid_purposes = [
                "naming",
                "convention",
                "parameters",
                "rule",
                "compliance",
                "security",
            ]
            filename_parts = filename.split("-")[1:]  # Remove 'storage' prefix

            # At least one part should indicate the purpose
            purpose_found = any(
                purpose in "-".join(filename_parts) for purpose in valid_purposes
            )
            if not purpose_found:
                pytest.warn(
                    f"Storage policy {policy_file.name} purpose not clear from filename"
                )
