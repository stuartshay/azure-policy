# Requirements Management

This directory contains centralized Python package requirements for the Azure Policy project.

## Structure

- **`base.txt`** - Core dependencies needed across the project (Azure SDK, utilities)
- **`dev.txt`** - Development and testing tools (includes base.txt)
- **`functions.txt`** - Minimal requirements for Azure Functions deployment
- **`../requirements.txt`** - Main development requirements file (includes dev.txt)

## Usage

### For Development
Install all development dependencies:
```bash
pip install -r requirements.txt
```

### For Azure Functions
The Azure Functions use a minimal set of dependencies for deployment:
```bash
cd functions/basic
pip install -r requirements.txt  # This references ../../requirements/functions.txt
```

### Adding New Dependencies

1. **Core dependencies** (needed by functions and development): Add to `base.txt`
2. **Development tools** (testing, linting, etc.): Add to `dev.txt`
3. **Function-specific runtime dependencies**: Add to `functions.txt`

## Benefits

- **No version conflicts**: Single source of truth for package versions
- **Faster builds**: Dockerfile doesn't install packages globally
- **Clear separation**: Development vs. production dependencies
- **Easy maintenance**: Update versions in one place
