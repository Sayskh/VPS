#!/bin/bash

NEON='\033[38;5;118m'
ORANGE='\033[38;5;208m'
PURPLE='\033[0;35m'
RED='\033[0;91m'
YELLOW='\033[0;93m'
GREEN='\033[0;32m'
NC='\033[0m'

print_header() {
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

clear
print_header
echo -e "${ORANGE}           Tailscale VPN Installer${NC}"
echo -e "${ORANGE}                  by Hio${NC}"
print_header
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Check curl
if ! command -v curl &>/dev/null; then
    print_status "Installing curl"
    apt-get update && apt-get install -y curl
fi

print_status "Installing Tailscale"
if curl -fsSL https://tailscale.com/install.sh | sh; then
    print_success "Tailscale installed"
    
    if command -v systemctl &>/dev/null; then
        systemctl enable --now tailscaled || true
    fi
    
    echo -e "${ORANGE}Starting Tailscale...${NC}"
    
    if [ -n "${TS_AUTH_KEY:-}" ]; then
        tailscale up --auth-key="$TS_AUTH_KEY" && print_success "Connected via auth key"
    else
        tailscale up && print_success "Connected"
        echo -e "${YELLOW}💡 Tip: Set TS_AUTH_KEY for non-interactive auth${NC}"
    fi
else
    print_error "Installation failed"
    exit 1
fi

echo ""
print_header
echo -e "${ORANGE}           Thank you for using Hio Tools!${NC}"
print_header
