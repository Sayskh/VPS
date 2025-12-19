#!/bin/bash

# ============================================
# HIO'S PTERODACTYL HOSTING MANAGER
# ============================================

# Color Scheme: Neon Green, Red, Yellow
NEON='\033[38;5;118m'
RED='\033[0;91m'
YELLOW='\033[0;93m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/Sayskh/VPS/main/scripts"

# Animated text function
animate_text() {
    local text="$1"
    local delay="${2:-0.02}"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

print_header() {
    echo -e "${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check and install curl
check_curl() {
    if ! command -v curl &>/dev/null; then
        print_status "Installing curl"
        apt-get update && apt-get install -y curl >/dev/null 2>&1
        print_success "curl installed"
    fi
}

# Run remote script
run_script() {
    local url=$1
    local name=$2
    
    print_header
    echo -e "${NEON}Running: ${BOLD}${name}${NC}"
    print_header
    
    check_curl
    local temp=$(mktemp)
    print_status "Downloading"
    
    if curl -fsSL "$url" -o "$temp"; then
        print_success "Downloaded"
        chmod +x "$temp"
        bash "$temp"
        rm -f "$temp"
    else
        print_error "Download failed"
    fi
    
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

# Animated header
header=(
"========================="
" __   __  ___   _______ "
"|  | |  ||   | |       |"
"|  |_|  ||   | |   _   |"
"|       ||   | |  | |  |"
"|       ||   | |  |_|  |"
"|   _   ||   | |       |"
"|__| |__||___| |_______|"
"     POWERED BY HIO     "
"========================="
)

# Menu options
menu=(
"  ${WHITE}1)${NC} ${YELLOW}Panel Installation${NC}"
"  ${WHITE}2)${NC} ${YELLOW}Wings Installation${NC}"
"  ${WHITE}3)${NC} ${YELLOW}Panel Update${NC}"
"  ${WHITE}4)${NC} ${YELLOW}Uninstall Tools${NC}"
"  ${WHITE}5)${NC} ${YELLOW}Blueprint Setup${NC}"
"  ${WHITE}6)${NC} ${YELLOW}Cloudflare Tunnel${NC}"
"  ${WHITE}7)${NC} ${YELLOW}Theme Manager${NC}"
"  ${WHITE}8)${NC} ${YELLOW}System Information${NC}"
"  ${WHITE}9)${NC} ${YELLOW}Tailscale VPN${NC}"
" ${WHITE}10)${NC} ${YELLOW}Database Setup${NC}"
" ${WHITE}11)${NC} ${YELLOW}Blueprint Extensions${NC}"
" ${WHITE}12)${NC} ${YELLOW}DDoS Protection${NC}"
"  ${WHITE}0)${NC} ${RED}Exit${NC}"
)

show_menu() {
    clear
    
    # Animated header
    for line in "${header[@]}"; do
        echo -e "${NEON}${BOLD}$line${NC}"
        sleep 0.04
    done
    
    echo ""
    print_header
    echo ""
    
    # Menu options
    for option in "${menu[@]}"; do
        echo -e "$option"
        sleep 0.02
    done
    
    echo ""
    print_header
    echo -e "${RED}${BOLD}📝 Select option [0-12]: ${NC}"
}

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)  run_script "${BASE_URL}/panel.sh" "Panel Installation" ;;
        2)  run_script "${BASE_URL}/wings.sh" "Wings Installation" ;;
        3)  run_script "${BASE_URL}/update.sh" "Panel Update" ;;
        4)  run_script "${BASE_URL}/uninstall.sh" "Uninstall Tools" ;;
        5)  run_script "${BASE_URL}/blueprint.sh" "Blueprint Setup" ;;
        6)  run_script "${BASE_URL}/cloudflare.sh" "Cloudflare Tunnel" ;;
        7)  run_script "${BASE_URL}/theme.sh" "Theme Manager" ;;
        8)  run_script "${BASE_URL}/sysinfo.sh" "System Information" ;;
        9)  run_script "${BASE_URL}/tailscale.sh" "Tailscale VPN" ;;
        10) run_script "${BASE_URL}/database.sh" "Database Setup" ;;
        11) run_script "${BASE_URL}/extensions.sh" "Blueprint Extensions" ;;
        12) run_script "${BASE_URL}/ddosProtection.sh" "DDoS Protection" ;;
        0)
            echo -e "${GREEN}Exiting Hio Hosting Manager...${NC}"
            print_header
            animate_text "         Thank you for using Hio Tools!" 0.02
            print_header
            sleep 1
            exit 0
            ;;
        *)
            print_error "Invalid option! Choose 0-12"
            sleep 1
            ;;
    esac
done
