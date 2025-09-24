#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew
if ! command_exists brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    log "Homebrew already installed"
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log "Oh My Zsh already installed"
fi

# Install Homebrew packages
log "Installing Homebrew packages..."
packages=(
    "starship"
    "neovim" 
    "ripgrep"
    "tmux"
    "eza"
    "zoxide"
    "fzf"
    "bat"
    "luarocks"
    "wget"
    "fd"
    "gnu-stow"
    "uv"
    "wezterm"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "font-fira-code-nerd-font"
    "font-meslo.lg-nerd-font"
)

for package in "${packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        log "$package already installed"
    else
        log "Installing $package..."
        brew install "$package"
    fi
done

# Remove ~/.zshrc if it's a file (not symlink)
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    log "Removing existing .zshrc file..."
    rm "$HOME/.zshrc"
fi

# Run stow from dotfiles directory
log "Configuring dotfiles with stow..."
cd "$HOME/dotfiles"
stow .

log "Bootstrap complete!"
echo ""
echo -e "${GREEN}🎉 Setup finished! Please close this terminal with ${YELLOW}CMD + Q${GREEN} and open WezTerm.${NC}"
