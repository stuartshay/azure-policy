"""
Integration tests for Azure Policy with Azure CLI commands.

This module provides integration tests that simulate Azure CLI operations
for policy management including creation, assignment, and compliance checking.

Note: These tests can run in "simulation mode" (default) for local testing
or "live mode" when Azure CLI is authenticated and available.
"""

import json
import os
import subprocess

import pytest


@pytest.fixture
def azure_cli_available():
    """Check if Azure CLI is available and authenticated."""
    try:
        result = subprocess.run(
            ["az", "account", "show"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


@pytest.fixture
def test_subscription_id():
    """Get test subscription ID from environment or use mock."""
    return os.getenv("AZURE_SUBSCRIPTION_ID", "00000000-0000-0000-0000-000000000000")


@pytest.fixture
def test_resource_group():
    """Get test resource group name."""
    return os.getenv("AZURE_TEST_RESOURCE_GROUP", "rg-policy-test-dev-eastus")


class TestAzurePolicyIntegration:
    """Integration tests for Azure Policy operations."""

    def test_policy_definition_creation_simulation(self, policies_dir):
        """Simulate Azure policy definition creation without actual Azure calls."""
        policy_files = list(policies_dir.glob("*.json"))

        if not policy_files:
            pytest.skip("No policy files found to test")

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            # Skip fragment files as they are not complete policy definitions
            if policy_file.name.endswith(
                "-parameters.json"
            ) or policy_file.name.endswith("-rule.json"):
                continue

            # Simulate az policy definition create command validation
            definition_name = f"test-{policy_file.stem}"

            # Check that policy has all required fields for Azure CLI
            required_fields = ["displayName", "description", "policyRule"]
            for field in required_fields:
                assert field in policy, (
                    f"Policy {policy_file.name} missing {field} "
                    f"required for 'az policy definition create'"
                )

            # Simulate CLI command structure
            cli_command = [
                "az",
                "policy",
                "definition",
                "create",
                "--name",
                definition_name,
                "--display-name",
                policy["displayName"],
                "--description",
                policy["description"],
                "--rules",
                json.dumps(policy["policyRule"]),
                "--mode",
                policy.get("mode", "Indexed"),
            ]

            # Add parameters if present
            if "parameters" in policy:
                cli_command.extend(["--params", json.dumps(policy["parameters"])])

            # Validate command structure (don't actually run)
            assert (
                len(cli_command) > 8
            ), f"CLI command for {policy_file.name} incomplete"
            assert "--name" in cli_command
            assert "--rules" in cli_command

    @pytest.mark.skipif(
        not os.getenv("AZURE_LIVE_TESTS", "").lower() == "true",
        reason="Live Azure tests disabled. Set AZURE_LIVE_TESTS=true to enable",
    )
    def test_policy_definition_creation_live(
        self, policies_dir, azure_cli_available_fixture, test_subscription_id_fixture
    ):
        """Live test: Create actual policy definitions in Azure (requires auth)."""
        if not azure_cli_available_fixture:
            pytest.skip("Azure CLI not available or not authenticated")

        policy_files = list(policies_dir.glob("*.json"))[:1]  # Test only first policy

        for policy_file in policy_files:
            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            definition_name = f"test-{policy_file.stem}-{os.getpid()}"

            try:
                # Create policy definition
                create_cmd = [
                    "az",
                    "policy",
                    "definition",
                    "create",
                    "--name",
                    definition_name,
                    "--display-name",
                    f"TEST: {policy['displayName']}",
                    "--description",
                    f"TEST: {policy['description']}",
                    "--rules",
                    json.dumps(policy["policyRule"]),
                    "--subscription",
                    test_subscription_id_fixture,
                ]

                if "parameters" in policy:
                    create_cmd.extend(["--params", json.dumps(policy["parameters"])])

                if "mode" in policy:
                    create_cmd.extend(["--mode", policy["mode"]])

                result = subprocess.run(
                    create_cmd, capture_output=True, text=True, timeout=30, check=False
                )
                assert (
                    result.returncode == 0
                ), f"Failed to create policy: {result.stderr}"

                # Verify policy was created
                show_cmd = [
                    "az",
                    "policy",
                    "definition",
                    "show",
                    "--name",
                    definition_name,
                    "--subscription",
                    test_subscription_id_fixture,
                ]

                result = subprocess.run(
                    show_cmd, capture_output=True, text=True, timeout=30, check=False
                )
                assert result.returncode == 0, f"Failed to show policy: {result.stderr}"

                created_policy = json.loads(result.stdout)
                assert created_policy["name"] == definition_name

            finally:
                # Cleanup: Delete the test policy
                delete_cmd = [
                    "az",
                    "policy",
                    "definition",
                    "delete",
                    "--name",
                    definition_name,
                    "--subscription",
                    test_subscription_id_fixture,
                    "--yes",
                ]
                subprocess.run(delete_cmd, capture_output=True, timeout=30, check=False)

    def test_policy_assignment_simulation(
        self, policies_dir, test_resource_group_fixture
    ):
        """Simulate policy assignment to a resource group."""
        policy_files = list(policies_dir.glob("*.json"))

        if not policy_files:
            pytest.skip("No policy files found to test")

        # Filter out fragment files
        complete_policy_files = [
            f
            for f in policy_files
            if not (
                f.name.endswith("-parameters.json") or f.name.endswith("-rule.json")
            )
        ]

        if not complete_policy_files:
            pytest.skip("No complete policy files found to test")

        # Test assignment simulation for first complete policy
        policy_file = complete_policy_files[0]
        with open(policy_file, "r", encoding="utf-8") as f:
            policy = json.load(f)

        # Simulate policy assignment command
        assignment_name = f"assign-{policy_file.stem}"
        definition_name = f"def-{policy_file.stem}"
        scope = f"/subscriptions/test-sub/resourceGroups/{test_resource_group_fixture}"

        cli_command = [
            "az",
            "policy",
            "assignment",
            "create",
            "--name",
            assignment_name,
            "--display-name",
            f"Assignment: {policy['displayName']}",
            "--policy",
            definition_name,
            "--scope",
            scope,
        ]

        # Add parameters if the policy has them
        if "parameters" in policy:
            # Create sample assignment parameters
            assignment_params = {}
            for param_name, param_def in policy["parameters"].items():
                if "defaultValue" in param_def:
                    assignment_params[param_name] = {"value": param_def["defaultValue"]}
                elif param_def.get("type") == "String":
                    assignment_params[param_name] = {"value": "test-value"}

            if assignment_params:
                cli_command.extend(["--params", json.dumps(assignment_params)])

        # Validate command structure
        assert "--name" in cli_command
        assert "--policy" in cli_command
        assert "--scope" in cli_command

    def test_policy_compliance_check_simulation(self, test_resource_group_fixture):
        """Simulate policy compliance checking."""
        # Simulate compliance check command
        cli_command = [
            "az",
            "policy",
            "state",
            "list",
            "--resource-group",
            test_resource_group_fixture,
            "--query",
            "[?complianceState=='NonCompliant']",
        ]

        assert "--resource-group" in cli_command
        assert "--query" in cli_command


class TestPolicyValidationWithAzureCLI:
    """Test policy validation using Azure CLI validation commands."""

    def test_policy_syntax_validation_with_cli_simulation(self, policies_dir):
        """Simulate Azure CLI policy syntax validation."""
        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            # Skip fragment files as they are not complete policy definitions
            if policy_file.name.endswith(
                "-parameters.json"
            ) or policy_file.name.endswith("-rule.json"):
                continue

            # Simulate what Azure CLI would validate
            with open(policy_file, "r", encoding="utf-8") as f:
                policy_content = f.read()

            # 1. Valid JSON
            try:
                policy = json.loads(policy_content)
            except json.JSONDecodeError as e:
                pytest.fail(f"Invalid JSON in {policy_file.name}: {e}")

            # 2. Required fields for Azure CLI
            required_fields = ["displayName", "description", "policyRule"]
            for field in required_fields:
                assert field in policy, (
                    f"Policy {policy_file.name} would fail Azure CLI validation: "
                    f"missing {field}"
                )

            # 3. PolicyRule structure
            assert (
                "if" in policy["policyRule"]
            ), f"Policy {policy_file.name} policyRule missing 'if' condition"
            assert (
                "then" in policy["policyRule"]
            ), f"Policy {policy_file.name} policyRule missing 'then' action"

    def test_policy_mode_validation(self, policies_dir):
        """Test that policy modes are valid for Azure."""
        valid_modes = [
            "All",
            "Indexed",
            "Microsoft.KeyVault.Data",
            "Microsoft.ContainerService.Data",
            "Microsoft.Kubernetes.Data",
        ]

        policy_files = list(policies_dir.glob("*.json"))

        for policy_file in policy_files:
            # Skip fragment files as they are not complete policy definitions
            if policy_file.name.endswith(
                "-parameters.json"
            ) or policy_file.name.endswith("-rule.json"):
                continue

            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            if "mode" in policy:
                assert policy["mode"] in valid_modes, (
                    f"Policy {policy_file.name} has invalid mode: {policy['mode']}. "
                    f"Valid modes: {valid_modes}"
                )


class TestPolicyDeploymentScenarios:
    """Test various policy deployment scenarios."""

    def test_storage_naming_policy_deployment_scenario(self, policies_dir):
        """Test storage naming policy deployment scenario."""
        storage_policies = list(policies_dir.glob("storage-naming-*.json"))

        if not storage_policies:
            pytest.skip("No storage naming policies found")

        for policy_file in storage_policies:
            # Skip fragment files as they are not complete policy definitions
            if policy_file.name.endswith(
                "-parameters.json"
            ) or policy_file.name.endswith("-rule.json"):
                continue

            with open(policy_file, "r", encoding="utf-8") as f:
                policy = json.load(f)

            # Simulate deployment scenario
            # Steps: Create policy definition, Assign to resource group, Test compliance
            # Verify policy supports this workflow
            assert "policyRule" in policy, "Policy must have rules for deployment"

            # Storage policies should target storage accounts
            policy_str = json.dumps(policy).lower()
            assert (
                "microsoft.storage" in policy_str or "storage" in policy_str
            ), f"Storage policy {policy_file.name} should reference storage resources"
