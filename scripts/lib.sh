#!/bin/bash
# Shared helpers for the bootstrap scripts.
# Source this file; do not execute it.

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

# Check if a command exists on PATH
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Repo root, regardless of where this was sourced from
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
