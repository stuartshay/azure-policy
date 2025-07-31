# Azure Functions DevContainer Troubleshooting Guide

## Common Issues and Solutions

### 1. Container Build Issues

**Problem**: DevContainer fails to build
**Solutions**:

```bash
# Rebuild container without cache
Ctrl+Shift+P → "Dev Containers: Rebuild Container"

# Or from command line
docker system prune -f
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
```

### 2. Azure Functions Not Starting

**Problem**: `func start` fails
**Solutions**:

1. **Check virtual environment**:

   ```bash
   cd functions/basic
   source .venv/bin/activate
   pip list | grep azure-functions
   ```

2. **Recreate virtual environment**:

   ```bash
   cd functions/basic
   rm -rf .venv
   python3 -m venv .venv
   source .venv/bin/activate
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. **Check local.settings.json**:

   ```bash
   cd functions/basic
   cp local.settings.json.template local.settings.json
   ```

### 3. Azurite Connection Issues

**Problem**: Functions can't connect to Azurite
**Solutions**:

1. **Check Azurite is running**:

   ```bash
   docker ps | grep azurite
   nc -z azurite 10000
   ```

2. **Update connection string in local.settings.json**:

   ```json
   {
     "Values": {
       "AzureWebJobsStorage": "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;QueueEndpoint=http://azurite:10001/devstoreaccount1;TableEndpoint=http://azurite:10002/devstoreaccount1;"  # pragma: allowlist secret
     }
   }
   ```

3. **Restart Azurite container**:

   ```bash
   docker-compose -f .devcontainer/docker-compose.yml restart azurite
   ```

### 4. Python Path Issues

**Problem**: Python interpreter not found
**Solutions**:

1. **Set correct interpreter in VS Code**:
   - `Ctrl+Shift+P` → "Python: Select Interpreter"
   - Choose: `functions/basic/.venv/bin/python`

2. **Update VS Code settings**:

   ```json
   {
     "python.defaultInterpreterPath": "./functions/basic/.venv/bin/python"
   }
   ```

### 5. Port Conflicts

**Problem**: Ports 7071, 10000-10002 already in use
**Solutions**:

1. **Stop conflicting services**:

   ```bash
   # Find process using port
   lsof -i :7071
   lsof -i :10000

   # Kill process (replace PID)
   kill -9 <PID>
   ```

2. **Use different ports** (update in docker-compose.yml and local.settings.json)

### 6. Permission Issues

**Problem**: Permission denied errors
**Solutions**:

1. **Fix file permissions**:

   ```bash
   sudo chown -R $USER:$USER .
   chmod +x scripts/*.sh
   chmod +x start-functions.sh
   ```

2. **Run as correct user**:

   ```bash
   # Check current user in container
   whoami
   # Should be 'vscode'
   ```

### 7. Extension Loading Issues

**Problem**: VS Code extensions not working
**Solutions**:

1. **Reload window**:
   - `Ctrl+Shift+P` → "Developer: Reload Window"

2. **Install extensions manually**:
   - `Ctrl+Shift+P` → "Extensions: Install Extensions"
   - Install: Azure Functions, Python, Python Debugger

### 8. Function Runtime Issues

**Problem**: Functions runtime errors
**Solutions**:

1. **Check Azure Functions version**:

   ```bash
   func --version
   # Should be 4.x
   ```

2. **Clear function cache**:

   ```bash
   cd functions/basic
   rm -rf __pycache__/
   rm -rf .azure-functions-core-tools/
   ```

3. **Update host.json**:

   ```json
   {
     "version": "2.0",
     "extensionBundle": {
       "id": "Microsoft.Azure.Functions.ExtensionBundle",
       "version": "[4.*, 5.0.0)"
     }
   }
   ```

## Quick Verification Commands

```bash
# Run the verification script
./start-functions.sh

# Manual verification
cd functions/basic
source .venv/bin/activate
func start

# Test endpoints (in another terminal)
curl http://localhost:7071/api/hello
curl http://localhost:7071/api/health
curl http://localhost:7071/api/info

# Run tests
python -m pytest tests/ -v
```

## Development Workflow

1. **Start development**:

   ```bash
   # Open in DevContainer
   code .
   # Wait for container to start
   # Run verification
   ./start-functions.sh
   ```

2. **Start Azure Functions**:

   ```bash
   cd functions/basic
   source .venv/bin/activate
   func start
   ```

3. **Run tests**:

   ```bash
   python -m pytest tests/ -v --cov=.
   ```

4. **Debug in VS Code**:
   - Set breakpoints in function_app.py
   - Use "Azure Functions: Debug" launch configuration

## Getting Help

1. **Check container logs**:

   ```bash
   docker-compose -f .devcontainer/docker-compose.yml logs
   ```

2. **Check Azure Functions logs**:
   - Enable detailed logging in local.settings.json
   - Check terminal output when running `func start`

3. **VS Code output panels**:
   - View → Output → Select "Azure Functions" or "Python"
