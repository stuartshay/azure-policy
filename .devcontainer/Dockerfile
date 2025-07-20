FROM mcr.microsoft.com/devcontainers/python:1-3.13-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Install Azure Functions Core Tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod bullseye main" > /etc/apt/sources.list.d/dotnetdev.list' \
    && apt-get update \
    && apt-get install -y azure-functions-core-tools-4 \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python tools globally
RUN pip install --upgrade pip \
    && pip install \
    azure-functions>=1.18.0 \
    azure-functions-worker>=1.0.0 \
    azure-storage-blob>=12.19.0 \
    azure-identity>=1.15.0 \
    black>=23.0.0 \
    pylint>=2.17.0 \
    flake8>=6.0.0 \
    pytest>=7.4.0 \
    pytest-asyncio>=0.21.0 \
    pytest-cov>=4.1.0 \
    isort>=5.12.0 \
    mypy>=1.0.0 \
    requests>=2.31.0

# Set up workspace
WORKDIR /workspace

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Switch to the non-root user
USER $USERNAME

# Ensure the user can access the Python installation
RUN echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
