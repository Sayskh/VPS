#!/bin/bash

# ============================================
# SYSTEM BENCHMARK (bench.sh by Teddysun)
# Wrapper by Hio
# ============================================

# Color Scheme: Neon Green, Red, Yellow
NEON='\033[38;5;118m'
RED='\033[0;91m'
YELLOW='\033[0;93m'
GREEN='\033[0;32m'
NC='\033[0m'

print_header() {
    echo -e "${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

# Check dependencies
if ! command -v curl &>/dev/null; then
    print_status "Installing curl"
    apt-get update && apt-get install -y curl >/dev/null 2>&1
    print_success "curl installed"
fi

print_status "Running bench.sh"
echo ""

# Run bench.sh by Teddysun
curl -Lso- bench.sh | bash

echo ""
print_header
echo -e "${NEON}           Thank you for using Hio Tools!${NC}"
print_header
