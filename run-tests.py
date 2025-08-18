#!/usr/bin/env python3
"""
Test runner for Azure Policy project.

This script runs tests from both function directories with proper environment setup.
"""

import os
import subprocess
import sys
from pathlib import Path


def run_tests_in_directory(test_dir: Path, venv_path: Path) -> bool:
    """Run tests in a specific directory with its virtual environment."""
    print(f"\n{'='*60}")
    print(f"Running tests in: {test_dir}")
    print(f"Using virtual environment: {venv_path}")
    print(f"{'='*60}")

    # Change to the test directory
    original_cwd = os.getcwd()
    parent_dir = test_dir.parent
    os.chdir(parent_dir)

    try:
        # Run pytest with the specific virtual environment
        cmd = [
            str(venv_path / "bin" / "python"),
            "-m",
            "pytest",
            "tests/",
            "-v",
            "--tb=short",
        ]

        result = subprocess.run(cmd, capture_output=False, check=False)
        return result.returncode == 0

    except (subprocess.SubprocessError, OSError) as e:
        print(f"Error running tests in {test_dir}: {e}")
        return False
    finally:
        os.chdir(original_cwd)


def main() -> None:
    """Main test runner function."""
    project_root = Path(__file__).parent

    # Define test configurations
    test_configs = [
        {
            "name": "Basic Functions",
            "test_dir": project_root / "functions" / "basic" / "tests",
            "venv_path": project_root / "functions" / "basic" / ".venv",
        },
        {
            "name": "Advanced Functions",
            "test_dir": project_root / "functions" / "advanced" / "tests",
            "venv_path": project_root / "functions" / "advanced" / ".venv",
        },
        {
            "name": "Workspace Tests",
            "test_dir": project_root / "tests",
            "venv_path": project_root / "functions" / "basic" / ".venv",
        },
    ]

    # Initialize results dictionary
    results = {}

    # Run tests for each configuration
    for config in test_configs:
        name = str(config["name"])
        test_dir = Path(str(config["test_dir"]))  # Explicit cast to ensure Path type
        venv_path = Path(str(config["venv_path"]))  # Explicit cast to ensure Path type

        if not test_dir.exists():
            print(f"Skipping {name}: test directory {test_dir} does not exist")
            continue

        if not (venv_path / "bin" / "python").exists():
            print(f"Skipping {name}: virtual environment {venv_path} does not exist")
            continue

        success = run_tests_in_directory(test_dir, venv_path)
        results[name] = success

    # Print summary
    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print(f"{'='*60}")

    all_passed = True
    for name, success in results.items():
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"{name}: {status}")
        if not success:
            all_passed = False

    print(f"{'='*60}")

    if all_passed:
        print("🎉 All tests passed!")
        sys.exit(0)
    else:
        print("💥 Some tests failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
