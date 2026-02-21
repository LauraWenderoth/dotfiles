#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Variables
# -----------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
CONDA_INIT_MARKER="# >>> conda initialize >>>"

# -----------------------------
# Logging helpers
# -----------------------------
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
ok()   { echo "[OK]   $*"; }

# -----------------------------
# Ensure Homebrew is installed
# -----------------------------
if ! command -v brew >/dev/null 2>&1; then
    info "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    ok "Homebrew is already installed"
fi

info "Updating Homebrew..."
brew update

# -----------------------------
# Install required packages
# -----------------------------
PACKAGES=(zsh git curl eza )
info "Installing required packages: ${PACKAGES[*]}"
brew install "${PACKAGES[@]}"
ok "Base packages installed"

# -----------------------------
# Install Oh My Zsh
# -----------------------------
if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    ok "Oh My Zsh already installed"
fi

# -----------------------------
# Set Zsh as default shell
# -----------------------------


CURRENT_SHELL="$(dscl . -read ~/ UserShell | awk '{print $2}')"
ZSH_PATH="$(which zsh)"

if ! grep -q "^$ZSH_PATH$" /etc/shells; then
    info "Adding $ZSH_PATH to /etc/shells"
    sudo sh -c "echo $ZSH_PATH >> /etc/shells"
fi

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    info "Changing default shell to Zsh"
    chsh -s "$ZSH_PATH"
else
    ok "Zsh is already default shell"
fi

# -----------------------------
# Link .zshrc from dotfiles
if [[ ! -f "$HOME/.zshrc" ]]; then
    if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
        warn "No ~/.zshrc found. Copying template from $DOTFILES_DIR/.zshrc..."
        cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
        ok "Copied .zshrc template to ~/.zshrc"
    else
        warn "No ~/.zshrc found and no template in dotfiles. Creating minimal template..."
        cat > "$HOME/.zshrc" <<'EOF'
# Suppress Powerlevel10k instant prompt warning
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-eza cmdtime history-substring-search zsh-peco-history)

source "$ZSH/oh-my-zsh.sh"

# User config
export EDITOR="code -w"
alias ll="ls -lah"
EOF
        ok "Template .zshrc created at ~/.zshrc"
    fi
fi

# -----------------------------
# Install Powerlevel10k theme
# -----------------------------
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    ok "Powerlevel10k theme already installed"
fi

# -----------------------------
# Install community plugins
# -----------------------------
PLUGINS=(
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-syntax-highlighting
    tom-auger/cmdtime
    z-shell/zsh-eza
    zsh-users/zsh-history-substring-search
    jimeh/zsh-peco-history
)

for plugin in "${PLUGINS[@]}"; do
    NAME=$(basename "$plugin")
    TARGET="$ZSH_CUSTOM/plugins/$NAME"
    if [[ ! -d "$TARGET" ]]; then
        info "Installing plugin $NAME..."
        git clone --depth=1 "https://github.com/$plugin.git" "$TARGET"
    else
        ok "Plugin $NAME already installed"
    fi
done

# -----------------------------
# Optional: Add conda init if not present
# -----------------------------
if ! grep -q "$CONDA_INIT_MARKER" "$HOME/.zshrc"; then
    if [[ ! -f "$HOME/.zshrc" ]]; then
        touch "$HOME/.zshrc"
    fi
    info "Appending conda initialization to .zshrc (edit path if needed)"
    cat <<'EOF' >> "$HOME/.zshrc"
# >>> conda initialize >>>
__conda_setup="$('/anaconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/anaconda/etc/profile.d/conda.sh" ]; then
        . "/anaconda/etc/profile.d/conda.sh"
    else
        export PATH="/anaconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
EOF
    ok "Conda initialization code appended to .zshrc"
fi

# -----------------------------
# Finish
# -----------------------------
echo
ok "Installation complete!"
echo "Restart your terminal or run 'exec zsh' to apply the new configuration."