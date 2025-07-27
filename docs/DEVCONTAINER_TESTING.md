# DevContainer Testing and Debugging Guide

This document provides comprehensive guidance for building, testing, and debugging the Azure Policy DevContainer environment.

## Overview

The Azure Policy project includes a sophisticated DevContainer setup with:
- Python 3.13 development environment
- Azure Functions Core Tools
- Azure CLI and PowerShell
- Azurite (Azure Storage Emulator)
- Pre-configured VS Code extensions and settings

## Testing Scripts

### 1. Main Test Script: `test-devcontainer.sh`

The primary script for building and testing the complete DevContainer environment.

#### Usage
```bash
# Full build and test
./scripts/test-devcontainer.sh

# Test existing containers without rebuilding
./scripts/test-devcontainer.sh --no-build

# Build only, skip tests
./scripts/test-devcontainer.sh --build-only

# Keep containers running after tests
./scripts/test-devcontainer.sh --keep

# Clean up existing containers only
./scripts/test-devcontainer.sh --cleanup-only
```

#### What it tests
- ✅ Docker and Docker Compose availability
- ✅ Container build and startup
- ✅ Network connectivity between services
- ✅ Python environment and virtual environment setup
- ✅ Azure Functions Core Tools installation
- ✅ Azure CLI installation
- ✅ PowerShell installation
- ✅ Azure Functions execution (hello endpoint)

#### Output
- Colored status messages for easy reading
- Detailed log file: `devcontainer-test.log`
- Container status summary
- Cleanup options

### 2. Quick Rebuild Script: `quick-rebuild-devcontainer.sh`

Faster rebuild option for iterative development and testing.

#### Usage
```bash
# Standard quick rebuild
./scripts/quick-rebuild-devcontainer.sh

# Fastest rebuild (uses cache)
./scripts/quick-rebuild-devcontainer.sh --fast

# Test existing containers only
./scripts/quick-rebuild-devcontainer.sh --test-only

# Complete clean rebuild
./scripts/quick-rebuild-devcontainer.sh --clean
```

#### Features
- Faster than full test script
- Basic connectivity tests
- Suitable for development iteration
- Quick validation of core functionality

### 3. Debug Script: `debug-devcontainer.sh`

Comprehensive diagnostic tool for troubleshooting DevContainer issues.

#### Usage
```bash
# Show all diagnostic information
./scripts/debug-devcontainer.sh --all

# Show container logs
./scripts/debug-devcontainer.sh --logs

# Show container status
./scripts/debug-devcontainer.sh --status

# Debug network connectivity
./scripts/debug-devcontainer.sh --network

# Check file permissions and mounts
./scripts/debug-devcontainer.sh --files

# Execute interactive shell in container
./scripts/debug-devcontainer.sh --exec
```

#### Diagnostic Features
- Container status and resource usage
- Detailed logs from all services
- Network connectivity diagnostics
- File system and permission checks
- System information
- Interactive shell access

## Common Issues and Solutions

### Build Failures

**Issue**: Container build fails with dependency errors
```bash
# Solution: Clean rebuild
./scripts/quick-rebuild-devcontainer.sh --clean
```

**Issue**: Python package conflicts
```bash
# Solution: Check requirements and rebuild
./scripts/validate-requirements.sh
./scripts/test-devcontainer.sh --cleanup-only
./scripts/test-devcontainer.sh
```

### Network Issues

**Issue**: Azurite not reachable from app container
```bash
# Diagnosis
./scripts/debug-devcontainer.sh --network

# Solution: Restart containers
cd .devcontainer
docker-compose down
docker-compose up -d
```

**Issue**: Azure Functions cannot start
```bash
# Diagnosis
./scripts/debug-devcontainer.sh --logs

# Check function logs specifically
docker exec azure-policy-devcontainer-app-1 cat /tmp/func.log
```

### File System Issues

**Issue**: Virtual environment not created
```bash
# Diagnosis
./scripts/debug-devcontainer.sh --files

# Solution: Check post-create script execution
docker exec azure-policy-devcontainer-app-1 bash /workspace/.devcontainer/post-create.sh
```

**Issue**: Permission denied errors
```bash
# Check file permissions
./scripts/debug-devcontainer.sh --files

# Fix script permissions
chmod +x scripts/*.sh
```

### Performance Issues

**Issue**: Slow container startup
```bash
# Use faster rebuild options
./scripts/quick-rebuild-devcontainer.sh --fast

# Check resource usage
./scripts/debug-devcontainer.sh --status
```

## Development Workflow

### Initial Setup
1. Clone the repository
2. Ensure Docker and Docker Compose are installed
3. Run the full test: `./scripts/test-devcontainer.sh`

### Iterative Development
1. Make changes to DevContainer configuration
2. Quick rebuild: `./scripts/quick-rebuild-devcontainer.sh`
3. Test specific functionality: `./scripts/quick-rebuild-devcontainer.sh --test-only`

### Debugging Issues
1. Run diagnostics: `./scripts/debug-devcontainer.sh --all`
2. Check specific areas: `--logs`, `--network`, `--files`
3. Interactive debugging: `./scripts/debug-devcontainer.sh --exec`

### Clean Environment
1. Full cleanup: `./scripts/test-devcontainer.sh --cleanup-only`
2. Clean rebuild: `./scripts/quick-rebuild-devcontainer.sh --clean`

## Container Architecture

### Services
- **app**: Main development container with Python, Azure tools
- **azurite**: Azure Storage Emulator for local development

### Networks
- **functions-net**: Bridge network connecting app and azurite

### Volumes
- **azurite-data**: Persistent storage for Azurite
- **Workspace mount**: `../..:/workspace:cached`

### Ports
- **7071**: Azure Functions runtime
- **10000**: Azurite Blob service
- **10001**: Azurite Queue service
- **10002**: Azurite Table service

## Environment Variables

Key environment variables configured in the containers:

```bash
# Azurite connection
AZURITE_ACCOUNT_NAME=devstoreaccount1
AZURITE_ACCOUNT_KEY=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==

# Azure Functions
FUNCTIONS_WORKER_RUNTIME=python
AzureWebJobsFeatureFlags=EnableWorkerIndexing
```

## Log Files

### Test Logs
- `devcontainer-test.log`: Complete test execution log
- Container logs: Accessible via `docker logs` or debug script

### Function Logs
- `/tmp/func.log`: Azure Functions runtime logs (inside container)
- VS Code terminal: Real-time function output

## Troubleshooting Checklist

Before reporting issues, run through this checklist:

1. **Prerequisites**
   - [ ] Docker is installed and running
   - [ ] Docker Compose is available
   - [ ] Sufficient disk space (>2GB free)
   - [ ] No conflicting containers running

2. **Basic Tests**
   - [ ] `./scripts/test-devcontainer.sh --cleanup-only`
   - [ ] `./scripts/test-devcontainer.sh`
   - [ ] Check exit code and log file

3. **Specific Diagnostics**
   - [ ] `./scripts/debug-devcontainer.sh --status`
   - [ ] `./scripts/debug-devcontainer.sh --network`
   - [ ] `./scripts/debug-devcontainer.sh --files`

4. **Clean Environment Test**
   - [ ] `./scripts/quick-rebuild-devcontainer.sh --clean`
   - [ ] `./scripts/test-devcontainer.sh`

## Advanced Usage

### Custom Container Names
If you need to test with different container names, modify the scripts:
```bash
# Edit the container name variables in the scripts
CONTAINER_NAME="your-custom-name"
AZURITE_CONTAINER_NAME="your-azurite-name"
```

### Integration with CI/CD
The test script can be used in CI/CD pipelines:
```bash
# Non-interactive mode
./scripts/test-devcontainer.sh --cleanup-only
if ./scripts/test-devcontainer.sh; then
    echo "DevContainer tests passed"
else
    echo "DevContainer tests failed"
    exit 1
fi
```

### Performance Monitoring
Monitor container performance during development:
```bash
# Continuous monitoring
watch -n 5 './scripts/debug-devcontainer.sh --status'

# Resource usage
docker stats azure-policy-devcontainer-app-1
```

## Contributing

When modifying the DevContainer configuration:

1. Test your changes with the full test suite
2. Update this documentation if needed
3. Ensure all tests pass before committing
4. Consider backward compatibility

## Support

If you encounter issues not covered in this guide:

1. Run the full diagnostic: `./scripts/debug-devcontainer.sh --all`
2. Check the log file: `devcontainer-test.log`
3. Include both outputs when reporting issues
4. Specify your Docker and Docker Compose versions

---

*This guide is part of the Azure Policy DevContainer testing framework. Keep it updated as the container configuration evolves.*
