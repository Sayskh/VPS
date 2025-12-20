#!/bin/bash
NEON='\033[38;2;43;233;138m'
MAGENTA='\033[38;2;249;38;114m'
BLUE='\033[38;2;50;142;255m'
RED='\033[38;2;230;42;25m'
YELLOW='\033[38;2;230;219;116m'
GREEN='\033[38;2;43;233;138m'
CYAN='\033[38;2;73;224;253m'
NC='\033[0m'

print_header() {
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
