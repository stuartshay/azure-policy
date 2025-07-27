FROM mcr.microsoft.com/devcontainers/python:1-3.13-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Install Azure Functions Core Tools, Azure CLI, and PowerShell
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod bullseye main" > /etc/apt/sources.list.d/dotnetdev.list' \
    && apt-get update \
    && apt-get install -y azure-functions-core-tools-4 azure-cli powershell \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip globally but don't install packages here
# Packages will be installed in virtual environment via post-create script
RUN pip install --upgrade pip

# Set up workspace
WORKDIR /azure-policy

# The base image already has a vscode user, so we just need to ensure sudo access
ARG USERNAME=vscode
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Switch to the non-root user
USER $USERNAME

# Ensure the user can access the Python installation
RUN echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
