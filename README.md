# benjymoses dotfiles
This repo helps to bootstrap the shell, terminal, prompt, and assorted plugins when keeping config in sync between machines or setting up a new one.

## Instructions for use

1. Clone this repo to the home folder of a macOS machine.
2. `./dotfiles/bootstrap.sh`

This will install Wezterm, Homebrew, and all necessary packages and configs. More info on each below.

> [!NOTE]
> This repo uses GNU Stow to symlink config files from ~/dotfiles to the right path in the home directory.

## Configs

**Starship** - Custom prompt with Catppuccin theme, Git integration, and language-specific modules  
**Tmux** - Terminal multiplexer with custom prefix (Ctrl+A), intuitive split bindings, and plugin support  
**Neovim** - Modern Vim setup with Lazy plugin manager, LSP, Telescope, Treesitter, and Catppuccin theme  
**Zsh + Oh My Zsh** - Enhanced shell with Git plugin, custom functions, and Homebrew integration  
**WezTerm** - GPU-accelerated terminal with Lua configuration  

## Packages

**Core Tools**  
- Homebrew - Package manager  
- Oh My Zsh - Zsh framework  
- GNU Stow - Dotfile symlink management  

**Terminal & Shell**  
- WezTerm - Terminal emulator  
- Starship - Cross-shell prompt  
- Zsh plugins: autosuggestions, syntax highlighting  

**Development**  
- Neovim - Text editor  
- Tmux - Terminal multiplexer  
- UV - Python package installer  
- Luarocks - Lua package manager  

**CLI Utilities**  
- Ripgrep - Fast text search  
- Eza - Modern ls replacement  
- Bat - Cat with syntax highlighting  
- Fzf - Fuzzy finder  
- Fd - Find alternative  
- Zoxide - Smart cd command  
- Wget - File downloader  

**Font**  
- MesloLGS NF - Nerd Font for terminal icons
