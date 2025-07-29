# Azurite Data Directory

This directory contains the data files for the Azurite storage emulator.

## Contents

When Azurite is running, the following files will be created in this directory:

- `__azurite_db_blob__.json` - Blob service metadata database
- `__azurite_db_blob_extent__.json` - Blob service extent database
- `__blobstorage__/` - Directory containing actual blob data
- `debug.log` - Azurite debug log file

## Configuration

Azurite is configured to use this directory via the VS Code task "Start Azurite" which runs:

```bash
azurite --silent --location ${workspaceFolder}/azurite-data --debug ${workspaceFolder}/azurite-data/debug.log
```

## Git Ignore

This directory and its contents are ignored by Git (see .gitignore) since they contain local development data that should not be committed to the repository.

## Cleanup

To reset the Azurite storage state, simply delete the contents of this directory (but keep the directory itself).
