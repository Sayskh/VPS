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
echo -e "${NEON}         System Benchmark (bench.sh)${NC}"
echo -e "${NEON}              by Teddysun${NC}"
print_header
echo ""

echo -e "${YELLOW}⚠️  This benchmark includes network speed tests and may take 5-10 minutes.${NC}"
echo ""
read -p "$(echo -e "${PURPLE}Run benchmark? [y/N]: ${NC}")" confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cancelled.${NC}"
    exit 0
fi

# Check dependencies
if ! command -v curl &>/dev/null; then
    print_status "Installing curl"
    apt-get update && apt-get install -y curl >/dev/null 2>&1
    print_success "curl installed"
fi

echo ""
print_status "Running bench.sh (Press Ctrl+C to cancel)"
echo ""

# Run bench.sh by Teddysun
curl -Lso- bench.sh | bash

echo ""
print_header
echo -e "${ORANGE}           Thank you for using Hio Tools!${NC}"
print_header
