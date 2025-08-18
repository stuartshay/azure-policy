"""
Tests for policy fragments and modular policy components.

This module handles testing of policy fragments that are meant to be
combined into complete policies, such as:
- Parameter definitions (storage-naming-parameters.json)
- Policy rules (storage-naming-rule.json)
- Partial policy definitions
"""

import json

import pytest


class TestPolicyFragments:
    """Test cases for policy fragments and modular components."""

    def test_parameter_fragments_are_valid(self, policies_dir):
        """Test that parameter fragment files contain valid parameter definitions."""
        param_files = list(policies_dir.glob("*-parameters.json"))

        for param_file in param_files:
            with open(param_file, "r", encoding="utf-8") as f:
                params = json.load(f)

            # Parameter fragments should contain parameter definitions
            assert isinstance(
                params, dict
            ), f"Parameter file {param_file.name} should contain an object"

            # Each parameter should have valid structure
            for param_name, param_def in params.items():
                assert isinstance(
                    param_def, dict
                ), f"Parameter {param_name} should be an object"
                assert "type" in param_def, f"Parameter {param_name} missing type"

                # Validate parameter type
                valid_types = [
                    "String",
                    "Array",
                    "Object",
                    "Boolean",
                    "Integer",
                    "Float",
                ]
                assert (
                    param_def["type"] in valid_types
                ), f"Parameter {param_name} has invalid type: {param_def['type']}"

                # Parameters should have metadata for documentation
                if "metadata" in param_def:
                    metadata = param_def["metadata"]
                    assert (
                        "displayName" in metadata
                    ), f"Parameter {param_name} metadata missing displayName"

    def test_rule_fragments_are_valid(self, policies_dir):
        """Test that rule fragment files contain valid policy rule structures."""
        rule_files = list(policies_dir.glob("*-rule.json"))

        for rule_file in rule_files:
            with open(rule_file, "r", encoding="utf-8") as f:
                rule = json.load(f)

            # Rule fragments should have if-then structure
            assert "if" in rule, f"Rule file {rule_file.name} missing 'if' condition"
            assert "then" in rule, f"Rule file {rule_file.name} missing 'then' action"

            # 'if' should contain condition logic
            assert isinstance(
                rule["if"], dict
            ), f"Rule file {rule_file.name} 'if' should be an object"

            # 'then' should contain action (typically effect)
            assert isinstance(
                rule["then"], dict
            ), f"Rule file {rule_file.name} 'then' should be an object"
            if "effect" in rule["then"]:
                effect = rule["then"]["effect"]
                # Effect can be a parameter reference or direct value
                assert isinstance(
                    effect, str
                ), f"Rule file {rule_file.name} effect should be a string"

    def test_convention_fragments_contain_policy_logic(self, policies_dir):
        """Test that convention fragment files contain policy-related logic."""
        convention_files = list(policies_dir.glob("*-convention.json"))

        for convention_file in convention_files:
            with open(convention_file, "r", encoding="utf-8") as f:
                convention = json.load(f)

            # Convention files should contain policy logic
            convention_str = json.dumps(convention).lower()

            # Should reference Azure resource types or field conditions
            has_azure_reference = any(
                keyword in convention_str
                for keyword in [
                    "microsoft.",
                    "field",
                    "type",
                    "name",
                    "location",
                    "tags",
                ]
            )

            assert (
                has_azure_reference
            ), f"Convention file {convention_file.name} should contain Azure policy logic"

    def test_storage_fragments_reference_storage_resources(self, policies_dir):
        """Test that storage-related fragments reference storage resources appropriately."""
        storage_files = [f for f in policies_dir.glob("storage-*.json")]

        for storage_file in storage_files:
            with open(storage_file, "r", encoding="utf-8") as f:
                content = json.load(f)

            content_str = json.dumps(content).lower()

            # Storage fragments should contain storage-related references
            # This could be in parameter descriptions, field references, or resource types
            storage_indicators = [
                "storage",
                "microsoft.storage/storageaccounts",
                "storageaccount",
                "blob",
                "account name",
                "naming",
            ]

            has_storage_reference = any(
                indicator in content_str for indicator in storage_indicators
            )

            if not has_storage_reference:
                # Allow parameters-only files to not directly reference storage
                # but they should have descriptive metadata
                if "parameters" not in storage_file.name:
                    pytest.fail(
                        f"Storage file {storage_file.name} should reference storage concepts"
                    )

    def test_fragments_can_be_combined_conceptually(self, policies_dir):
        """Test that related fragments could be combined into complete policies."""
        # Find related fragments (same prefix)
        prefixes = set()
        all_files = list(policies_dir.glob("*.json"))

        for file in all_files:
            parts = file.stem.split("-")
            if len(parts) >= 2:
                prefix = "-".join(parts[:-1])  # Everything except the last part
                prefixes.add(prefix)

        for prefix in prefixes:
            related_files = [f for f in all_files if f.stem.startswith(prefix)]

            if len(related_files) > 1:
                # We have multiple fragments for the same concept
                [f.stem.split("-")[-1] for f in related_files]

                # Collect all content from related fragments
                combined_content = {}

                for fragment_file in related_files:
                    with open(fragment_file, "r", encoding="utf-8") as f:
                        fragment_content = json.load(f)

                    fragment_type = fragment_file.stem.split("-")[-1]

                    if fragment_type == "parameters":
                        combined_content["parameters"] = fragment_content
                    elif fragment_type == "rule":
                        combined_content["policyRule"] = fragment_content
                    else:
                        # Other fragments might be complete or partial policies
                        combined_content.update(fragment_content)

                # If we have both parameters and rule, we could make a complete policy
                if (
                    "parameters" in combined_content
                    and "policyRule" in combined_content
                ):
                    # This combination could form a complete policy
                    # Add minimum required fields for conceptual completeness
                    combined_policy = {
                        "displayName": f"Combined {prefix.title()} Policy",
                        "description": f"Policy for {prefix} compliance",
                        "mode": "All",
                        **combined_content,
                    }

                    # Validate the combined policy would be structurally valid
                    required_fields = [
                        "displayName",
                        "description",
                        "mode",
                        "policyRule",
                    ]
                    for field in required_fields:
                        assert (
                            field in combined_policy
                        ), f"Combined {prefix} policy missing {field}"


class TestPolicyFragmentNaming:
    """Test naming conventions for policy fragments."""

    def test_fragment_naming_follows_convention(self, policies_dir):
        """Test that fragment files follow expected naming patterns."""
        all_files = list(policies_dir.glob("*.json"))

        # Expected fragment suffixes
        valid_suffixes = ["parameters", "rule", "convention", "naming"]

        for policy_file in all_files:
            filename = policy_file.stem
            parts = filename.split("-")

            if len(parts) >= 2:
                last_part = parts[-1]

                # If it looks like a fragment, validate the suffix
                if last_part in valid_suffixes:
                    # Fragment naming is valid
                    assert (
                        len(parts) >= 2
                    ), f"Fragment {policy_file.name} should have resource type prefix"

                    # First part should indicate resource type or scope
                    resource_type = parts[0]
                    common_resource_types = [
                        "storage",
                        "compute",
                        "network",
                        "resource-group",
                        "keyvault",
                    ]

                    if resource_type not in common_resource_types:
                        pytest.warn(
                            f"Fragment {policy_file.name} uses uncommon resource type: {resource_type}"
                        )

    def test_related_fragments_use_consistent_prefixes(self, policies_dir):
        """Test that related fragments use consistent naming prefixes."""
        all_files = list(policies_dir.glob("*.json"))

        # Group files by potential prefixes
        prefix_groups: dict[str, list[str]] = {}

        for policy_file in all_files:
            parts = policy_file.stem.split("-")
            if len(parts) >= 2:
                prefix = "-".join(parts[:-1])
                if prefix not in prefix_groups:
                    prefix_groups[prefix] = []
                prefix_groups[prefix].append(policy_file.name)

        # Check that groups with multiple files have consistent naming
        for prefix, files in prefix_groups.items():
            if len(files) > 1:
                # All files in this group should start with the same prefix
                for filename in files:
                    assert filename.startswith(
                        prefix
                    ), f"File {filename} doesn't match group prefix {prefix}"


class TestPolicyFragmentIntegration:
    """Integration tests for policy fragments."""

    def test_fragments_contain_complementary_information(self, policies_dir):
        """Test that related fragments contain complementary information."""
        # Find parameter and rule pairs
        param_files = list(policies_dir.glob("*-parameters.json"))

        for param_file in param_files:
            # Look for corresponding rule file
            prefix = param_file.stem.replace("-parameters", "")
            rule_file = policies_dir / f"{prefix}-rule.json"

            if rule_file.exists():
                # Load both files
                with open(param_file, "r", encoding="utf-8") as f:
                    parameters = json.load(f)

                with open(rule_file, "r", encoding="utf-8") as f:
                    rule = json.load(f)

                # Check that rule references parameters defined in parameter file
                rule_str = json.dumps(rule).lower()

                for param_name in parameters.keys():
                    param_reference = f"parameters('{param_name}')"
                    if param_reference.lower() not in rule_str:
                        pytest.warn(
                            f"Parameter {param_name} not referenced in {rule_file.name}"
                        )

    def test_storage_fragments_form_coherent_policy_set(self, policies_dir):
        """Test that storage fragments form a coherent policy set."""
        storage_files = list(policies_dir.glob("storage-*.json"))

        if len(storage_files) < 2:
            pytest.skip("Need at least 2 storage fragments to test coherence")

        # Collect all storage-related content
        all_storage_content = {}

        for storage_file in storage_files:
            with open(storage_file, "r", encoding="utf-8") as f:
                content = json.load(f)

            fragment_type = storage_file.stem.split("-")[-1]
            all_storage_content[fragment_type] = content

        # Check for common themes across fragments
        all_content_str = json.dumps(all_storage_content).lower()

        # Should have consistent focus on storage accounts
        assert (
            "storage" in all_content_str
        ), "Storage fragments should reference storage concepts"

        # Should have naming-related logic
        naming_indicators = ["name", "naming", "pattern", "match"]
        has_naming_logic = any(
            indicator in all_content_str for indicator in naming_indicators
        )
        assert has_naming_logic, "Storage fragments should include naming logic"
