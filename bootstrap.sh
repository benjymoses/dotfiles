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

# Pre-flight checks and user confirmation
preflight_check() {
    echo -e "${GREEN}Bootstrap Script - Pre-flight Check${NC}"
    echo "=================================="
    echo ""
    echo "This script will perform the following activities:"
    echo "• Install Homebrew (if not present)"
    echo "• Install Oh My Zsh (if not present)"
    echo "• Install development packages via Homebrew"
    echo "• Configure dotfiles using GNU stow"
    echo "• Set up TMUX plugin manager"
    echo ""
    
    # Check for existing configs that would be overwritten
    local conflicts=()
    
    # Check dotfiles in root
    for file in "$HOME/dotfiles"/.*; do
        [ -f "$file" ] || continue
        local basename=$(basename "$file")
        [ "$basename" = "." ] || [ "$basename" = ".." ] && continue
        [ -e "$HOME/$basename" ] && conflicts+=("$basename")
    done
    
    # Check .config subdirectories
    if [ -d "$HOME/dotfiles/.config" ]; then
        while IFS= read -r -d '' file; do
            local rel_path="${file#$HOME/dotfiles/.config/}"
            local target="$HOME/.config/$rel_path"
            [ -e "$target" ] && conflicts+=("~/.config/$rel_path")
        done < <(find "$HOME/dotfiles/.config" -type f -print0)
    fi
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        warn "Existing configuration files will be backed up:"
        printf "  %s\n" "${conflicts[@]}"
        echo ""
    fi
    
    echo -e "${YELLOW}Warning:${NC} If existing configs exist, they'll be backed up to:"
    echo "  ~/.config/backups/$(date -u +%Y-%m-%d-%H%M%S)/"
    echo ""
    echo "NVIM and TMUX plugins will be purged (you can re-install them afterwards)"
    echo ""
    
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
}

# Backup existing configs
backup_configs() {
    local backup_dir="$HOME/.config/backups/$(date -u +%Y-%m-%d-%H%M%S)"
    local needs_backup=false
    
    # Create backup directory structure
    mkdir -p "$backup_dir"
    
    # Backup dotfiles in root
    cd "$HOME/dotfiles"
    for file in .*; do
        [ "$file" = "." ] || [ "$file" = ".." ] && continue
        [ -f "$file" ] || continue
        
        local target="$HOME/$file"
        if [ -e "$target" ]; then
            log "Backing up $file"
            cp -r "$target" "$backup_dir/"
            rm -rf "$target"
            needs_backup=true
        fi
    done
    
    # Backup .config files
    if [ -d "$HOME/dotfiles/.config" ]; then
        while IFS= read -r -d '' file; do
            local rel_path="${file#$HOME/dotfiles/.config/}"
            local target="$HOME/.config/$rel_path"
            if [ -e "$target" ]; then
                log "Backing up ~/.config/$rel_path"
                mkdir -p "$backup_dir/.config/$(dirname "$rel_path")"
                cp -r "$target" "$backup_dir/.config/$rel_path"
                rm -rf "$target"
                needs_backup=true
            fi
        done < <(find "$HOME/dotfiles/.config" -type f -print0)
    fi
    
    # Clean plugin directories
    for plugin_dir in "$HOME/.config/nvim/plugins" "$HOME/.config/tmux/plugins"; do
        if [ -d "$plugin_dir" ]; then
            log "Cleaning $plugin_dir"
            rm -rf "$plugin_dir"/*
            mkdir -p "$plugin_dir"
        fi
    done
    
    if [ "$needs_backup" = true ]; then
        log "Configs backed up to: $backup_dir"
    else
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Run pre-flight checks
preflight_check

# Backup existing configurations
backup_configs

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
    "stow"
    "uv"
    "pyenv"
    "wezterm"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "font-fira-code-nerd-font"
    "font-meslo-lg-nerd-font"
)

for package in "${packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        log "$package already installed"
    else
        log "Installing $package..."
        brew install "$package"
    fi
done

# Archive old NVIM cache if exists
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

# Run stow from dotfiles directory
log "Configuring dotfiles with stow..."
cd "$HOME/dotfiles"
stow .

# Clone TPM for TMUX (only if not already exists)
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    log "Installing TMUX Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
else
    log "TMUX Plugin Manager already installed"
fi

log "Bootstrap complete!"
echo ""
echo -e "${GREEN}🎉 Setup finished! Please close this terminal with ${YELLOW}CMD + Q${GREEN} and open WezTerm.${NC}"
