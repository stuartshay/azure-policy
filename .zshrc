# Azure Policy & Functions Development - Zsh Configuration

# Oh My Zsh configuration (if installed)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(
    git
    azure
    python
    docker
    vscode
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Load Oh My Zsh if available
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source $ZSH/oh-my-zsh.sh

# Azure Functions development aliases
alias funcs='cd /workspace/functions/basic'
alias venv='source .venv/bin/activate'
alias start-func='cd /workspace/functions/basic && source .venv/bin/activate && func start'
alias install-deps='cd /workspace/functions/basic && source .venv/bin/activate && pip install -r requirements.txt'
alias test-func='cd /workspace/functions/basic && source .venv/bin/activate && python -m pytest tests/ -v'

# Azure CLI aliases
alias azlogin='az login'
alias azls='az account list --output table'
alias azset='az account set --subscription'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Python development
alias python='python3'
alias pip='pip3'
alias black-format='black .'
alias lint='pylint function_app.py'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -la'
alias la='ls -A'

# Azure Functions specific environment
export FUNCTIONS_WORKER_RUNTIME=python
export AZURE_FUNCTIONS_ENVIRONMENT=Development

# Python path for Azure Functions
export PYTHONPATH="/workspace/functions/basic:$PYTHONPATH"

# Auto-activate Python virtual environment when in functions directory
function cd() {
    builtin cd "$@"
    if [[ -f ".venv/bin/activate" ]]; then
        source .venv/bin/activate
    fi
}

# Display useful info when starting terminal
echo "🚀 Azure Policy & Functions Development Environment"
echo "📁 Workspace: /workspace"
echo "🐍 Python: $(python3 --version)"
echo "☁️  Azure CLI: $(az --version | head -n1)"
echo ""
echo "Quick commands:"
echo "  funcs     - Navigate to functions directory"
echo "  start-func - Start Azure Functions"
echo "  azlogin   - Login to Azure"
echo ""
