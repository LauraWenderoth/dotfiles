# Add conda initialization code directly to ~/.zshrc if not present
CONDA_INIT_MARKER="# >>> conda initialize >>>"
if ! grep -q "$CONDA_INIT_MARKER" "$HOME/.zshrc"; then
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
  ok "Appended conda initialization code to .zshrc"
fi
# Install Powerlevel10k theme for Oh My Zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

#!/usr/bin/env bash
# ensure_pkg: Installiert ein Paket nur, wenn es nicht vorhanden ist
ensure_pkg() {
  local pkg="$1"
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    sudo apt-get install -y "$pkg"
  fi
}
# shellcheck shell=bash

set -Eeuo



# Backup a file if it exists and is not the desired symlink
backup_if_needed() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    # If it's already the correct symlink, do nothing
    if [[ -L "$target" ]]; then
      return 0
    fi
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local backup="${target}.bak.${ts}"
    mv -f -- "$target" "$backup"
    warn "Existing $(basename "$target") moved to $(basename "$backup")"
  fi
}

# Set DOTFILES_DIR to the directory of this script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Simple logging functions
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
ok()   { echo "[OK]   $*"; }

# Link file: $1 = source, $2 = target
link_file() {
  local src="$1"
  local tgt="$2"
  if [[ -e "$tgt" || -L "$tgt" ]]; then
    if [[ -L "$tgt" && "$(readlink -- "$tgt")" == "$src" ]]; then
      ok "$tgt already links to $src"
      return 0
    fi
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local backup="${tgt}.bak.${ts}"
    mv -f -- "$tgt" "$backup"
    warn "Existing $(basename "$tgt") moved to $(basename "$backup")"
  fi
  ln -sf "$src" "$tgt"
  ok "Linked $tgt → $src"
}

#--- Checks ---------------------------------------------------------------
ok "Community plugins installed or updated"

echo "Start a new Zsh session or run 'exec zsh' to load your configuration."
echo
echo "==================================================="
echo "Installation complete! To activate your new shell:"
echo "  1. Start a new terminal session, OR"
echo "  2. Run: exec zsh"
echo "==================================================="

# Basic OS guard (Debian/Ubuntu-like)
if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script supports Debian/Ubuntu (apt-get). Aborting." >&2
  exit 1
fi

# --- Install Zsh & deps ---------------------------------------------------

info "Updating package index"
sudo apt-get update -y

info "Installing required packages: zsh, curl, git"
ensure_pkg zsh
ensure_pkg curl
ensure_pkg git
ok "Base packages ready"


# --- Set Zsh as default shell --------------------------------------------

CURRENT_SHELL="${SHELL:-}"
ZSH_PATH="$(command -v zsh)"

if [[ -z "$ZSH_PATH" ]]; then
  echo "zsh not found after install. Aborting." >&2
  exit 1
fi

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  info "Setting Zsh as the default shell (will apply on next login)"
  chsh -s "$ZSH_PATH" || warn "Could not change shell automatically (non-interactive session?). You can run: chsh -s $ZSH_PATH"
else
  ok "Zsh is already the default shell"
fi
# --- Install Oh My Zsh (non-interactive) ---------------------------------

echo "==> Installing Zsh and Oh My Zsh"

# Dependencies
sudo apt update
sudo apt install -y zsh curl git

# Set Zsh as default shell (takes effect on next login)
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  echo "==> Setting Zsh as default shell"
  chsh -s "$(command -v zsh)"
fi

# Install Oh My Zsh (non-interactive)

# Always ensure Oh My Zsh is fully installed (not just the directory)
if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  echo "==> Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "==> Oh My Zsh installation complete (restart shell)"

#--- Link .zshrc from repo -----------------------------------------------

# Expected location in your repo:
#   $DOTFILES_DIR/zsh/.zshrc
# Create the folder if you haven’t yet, and put your .zshrc there.
if [[ ! -f "$DOTFILES_DIR/zsh/.zshrc" ]]; then
  warn "No zsh/.zshrc found in repo. Creating a minimal template."
  mkdir -p "$DOTFILES_DIR/zsh"
  cat > "$DOTFILES_DIR/zsh/.zshrc" <<'EOF'
# === Minimal .zshrc (edit in your repo: zsh/.zshrc) ===
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"   # change to "agnoster" or any theme you like
plugins=(git)

source "$ZSH/oh-my-zsh.sh"

# User config
export EDITOR="code -w"
alias ll="ls -lah"
# Add your customizations below
EOF
  ok "Template .zshrc created at zsh/.zshrc"
fi

info "Linking ~/.zshrc to repo version"
link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"


# --- Oh My Zsh community plugins --------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

info "Installing community plugins (autosuggestions, syntax-highlighting, cmdtime, zsh-eza, history-substring-search, peco-history)"

# 1) zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --depth=1 || {
  rm -rf "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --depth=1
}

# 2) zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --depth=1 || {
  rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --depth=1
}

# 3) cmdtime (command duration in prompt)
git clone https://github.com/tom-auger/cmdtime "$ZSH_CUSTOM/plugins/cmdtime" --depth=1 || {
  rm -rf "$ZSH_CUSTOM/plugins/cmdtime" && \
  git clone https://github.com/tom-auger/cmdtime "$ZSH_CUSTOM/plugins/cmdtime" --depth=1
}

# 4) zsh-eza (replaces `ls` with modern `eza`)
# ensure eza exists (Ubuntu 24.04+ has 'eza' in apt; older may need cargo)
if ! command -v eza >/dev/null 2>&1; then
  info "Installing eza (modern replacement for ls)"
  if ! sudo apt-get install -y eza; then
    warn "apt 'eza' not available; installing manually from GitHub release."
    wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz || {
      warn "Failed to download or extract eza binary."; 
    }
    if [ -f eza ]; then
      sudo chmod +x eza
      sudo chown root:root eza
      sudo mv eza /usr/local/bin/eza
      ok "eza installed to /usr/local/bin/eza"
    else
      warn "eza binary not found after extraction."
    fi
  fi
fi
git clone https://github.com/z-shell/zsh-eza "$ZSH_CUSTOM/plugins/zsh-eza" --depth=1 || {
  rm -rf "$ZSH_CUSTOM/plugins/zsh-eza" && \
  git clone https://github.com/z-shell/zsh-eza "$ZSH_CUSTOM/plugins/zsh-eza" --depth=1
}

# 5) zsh-history-substring-search (Fish-like history search with arrows)
git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search" --depth=1 || {
  rm -rf "$ZSH_CUSTOM/plugins/zsh-history-substring-search" && \
  git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search" --depth=1
}

# 6) zsh-peco-history (Ctrl-r fuzzy history with peco)
# peco dependency
if ! command -v peco >/dev/null 2>&1; then
  info "Installing peco dependency for zsh-peco-history"
  sudo apt-get install -y peco || warn "Could not install peco; plugin may not work"
fi
git clone https://github.com/jimeh/zsh-peco-history "$ZSH_CUSTOM/plugins/zsh-peco-history" --depth=1 || {
  rm -rf "$ZSH_CUSTOM/plugins/zsh-peco-history" && \
  git clone https://github.com/jimeh/zsh-peco-history "$ZSH_CUSTOM/plugins/zsh-peco-history" --depth=1
}

ok "Community plugins installed or updated"
echo "Restart your terminal: Run: exec zsh"