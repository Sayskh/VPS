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
echo -e "${ORANGE}         System Benchmark (bench.sh)${NC}"
echo -e "${ORANGE}              by Teddysun${NC}"
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
