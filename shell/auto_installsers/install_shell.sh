#!/data/data/com.termux/files/usr/bin/env bash

# Installs Zsh (and related enhancements) in Termux on Android
# Installs dependencies and JetBrains Mono Nerd Font for Termux.
# Usage: bash install_shell

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Ensure we are running inside Termux
if ! command -v termux-info >/dev/null 2>&1; then
    log_error "This script is intended to be run inside Termux on Android."
fi

read -p "Install Zsh + dependencies + JetBrains Mono Nerd Font in Termux? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_error "Script execution cancelled"
fi

log_info "Updating Termux packages..."
pkg update -y || log_error "Failed to update packages"
pkg upgrade -y || log_error "Failed to upgrade packages"

log_info "Installing dependencies..."
pkg install -y zsh git curl wget unzip fontconfig || log_error "Failed to install dependencies"

log_info "Installing Zsh plugins (autosuggestions, syntax highlighting)..."
pkg install -y zsh-autosuggestions zsh-syntax-highlighting || log_warn "Failed to install zsh plugin packages"

log_info "Installing Oh My Zsh..."
if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log_info "Oh My Zsh already installed, skipping..."
else
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || log_error "Failed to install Oh My Zsh"
fi

log_info "Installing Powerlevel10k theme..."
if [[ -d "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
    log_info "Powerlevel10k already installed, skipping..."
else
    mkdir -p "${HOME}/.oh-my-zsh/custom/themes"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" || log_error "Failed to install Powerlevel10k"
fi

log_info "Configuring .zshrc..."
if [[ -f "${HOME}/.zshrc" ]]; then
    if ! grep -q "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" "${HOME}/.zshrc"; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' "${HOME}/.zshrc" || log_warn "Failed to set Powerlevel10k theme in .zshrc"
    fi
else
    echo "export ZSH=\"$HOME/.oh-my-zsh\"" > "${HOME}/.zshrc"
    echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> "${HOME}/.zshrc"
    echo "plugins=(git)" >> "${HOME}/.zshrc"
    echo "source \$ZSH/oh-my-zsh.sh" >> "${HOME}/.zshrc"
fi

# Enable plugins if not already enabled
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
TERMUX_ZSH_PLUGIN_DIR="${PREFIX}/share/zsh/plugins"

if ! grep -q "zsh-autosuggestions" "${HOME}/.zshrc"; then
    echo "source \"${TERMUX_ZSH_PLUGIN_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh\"" >> "${HOME}/.zshrc" || log_warn "Failed to enable zsh-autosuggestions"
fi
if ! grep -q "zsh-syntax-highlighting" "${HOME}/.zshrc"; then
    echo "source \"${TERMUX_ZSH_PLUGIN_DIR}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\"" >> "${HOME}/.zshrc" || log_warn "Failed to enable zsh-syntax-highlighting"
fi

log_info "Installing JetBrains Mono Nerd Font for Termux..."
TERMUX_FONT_DIR="${HOME}/.termux"
TERMUX_FONT_FILE="${TERMUX_FONT_DIR}/font.ttf"

mkdir -p "${TERMUX_FONT_DIR}"

# Try to install via Termux package, otherwise download from Nerd Fonts release
if pkg install -y fonts-jetbrains-mono-nerd >/dev/null 2>&1; then
    log_info "Installed fonts-jetbrains-mono-nerd package"
else
    log_info "Downloading JetBrains Mono Nerd Font from Nerd Fonts releases..."
    curl -fLo /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip || log_error "Failed to download JetBrains Mono Nerd Font"
    unzip -o /tmp/JetBrainsMono.zip -d /tmp/jetbrains-fonts || log_error "Failed to unzip JetBrains Mono Nerd Font"
    # Prefer the Regular font file if available
    FONT_PATH=$(find /tmp/jetbrains-fonts -type f -iname '*Regular*.ttf' | head -n1)
    if [[ -z "$FONT_PATH" ]]; then
        FONT_PATH=$(find /tmp/jetbrains-fonts -type f -iname '*.ttf' | head -n1)
    fi
    if [[ -z "$FONT_PATH" ]]; then
        log_error "Could not find a .ttf file in the downloaded archive"
    fi
    cp -f "$FONT_PATH" "$TERMUX_FONT_FILE" || log_error "Failed to copy font to ${TERMUX_FONT_FILE}"
    log_info "JetBrains Mono Nerd Font installed to ${TERMUX_FONT_FILE}"
fi

log_info "Installation complete!"
log_info "To use Zsh in Termux, run: zsh"
log_info "To make Zsh the default shell, add 'exec zsh' to the end of ~/.bashrc or your shell startup file."
log_info "If you changed the font, restart Termux and select the new font under Settings → Appearance → Font."