#!/bin/bash

# ============================================
# HIO'S PTERODACTYL HOSTING MANAGER
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Base URL for scripts (change this to your GitHub raw URL)
BASE_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts"

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

check_curl() {
    if ! command -v curl &>/dev/null; then
        print_error "curl not installed"
        print_status "Installing curl"
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y curl
        elif command -v yum &>/dev/null; then
            yum install -y curl
        elif command -v dnf &>/dev/null; then
            dnf install -y curl
        else
            print_error "Cannot install curl automatically"
            exit 1
        fi
        print_success "curl installed"
    fi
}

run_script() {
    local url=$1
    local name=$2
    
    print_header
    echo -e "${CYAN}Running: ${BOLD}${name}${NC}"
    print_header
    
    check_curl
    local temp=$(mktemp)
    print_status "Downloading script"
    
    if curl -fsSL "$url" -o "$temp"; then
        print_success "Downloaded"
        chmod +x "$temp"
        bash "$temp"
        local code=$?
        rm -f "$temp"
        if [ $code -eq 0 ]; then
            print_success "Completed"
        else
            print_error "Failed with code: $code"
        fi
    else
        print_error "Download failed"
    fi
    
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

system_info() {
    print_header
    echo -e "${CYAN}               📊 SYSTEM INFORMATION              ${NC}"
    print_header
    echo -e ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║ ${CYAN}Hostname:${NC}  $(hostname)"
    echo -e "${WHITE}║ ${CYAN}User:${NC}      $(whoami)"
    echo -e "${WHITE}║ ${CYAN}System:${NC}    $(uname -srm)"
    echo -e "${WHITE}║ ${CYAN}Uptime:${NC}    $(uptime -p 2>/dev/null || echo 'N/A')"
    echo -e "${WHITE}║ ${CYAN}Memory:${NC}    $(free -h 2>/dev/null | awk '/Mem:/ {print $3"/"$2}' || echo 'N/A')"
    echo -e "${WHITE}║ ${CYAN}Disk:${NC}      $(df -h / 2>/dev/null | awk 'NR==2 {print $3"/"$2" ("$5")"}' || echo 'N/A')"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

tailscale_setup() {
    print_header
    echo -e "${CYAN}Running: ${BOLD}Tailscale Installer${NC}"
    print_header
    
    check_curl
    if curl -fsSL https://tailscale.com/install.sh | sh; then
        print_success "Tailscale installed"
        if command -v systemctl &>/dev/null; then
            systemctl enable --now tailscaled || true
        fi
        echo -e "${CYAN}Starting Tailscale...${NC}"
        if [ -n "${TS_AUTH_KEY:-}" ]; then
            tailscale up --auth-key="$TS_AUTH_KEY" && print_success "Connected via auth key"
        else
            tailscale up && print_success "Connected"
            echo -e "${YELLOW}Tip: Set TS_AUTH_KEY for non-interactive auth${NC}"
        fi
    else
        print_error "Installation failed"
    fi
    
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

database_setup() {
    print_header
    echo -e "${CYAN}           🗄️  DATABASE REMOTE ACCESS SETUP       ${NC}"
    print_header
    
    read -p "Enter new database username: " DB_USER
    read -sp "Enter password: " DB_PASS
    echo ""
    
    echo -e "${YELLOW}Creating user '$DB_USER'...${NC}"
    
    mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
    if [ -f "$CONF" ]; then
        echo -e "${YELLOW}Updating bind-address...${NC}"
        sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF"
    fi
    
    echo -e "${YELLOW}Restarting services...${NC}"
    systemctl restart mysql 2>/dev/null || true
    systemctl restart mariadb 2>/dev/null || true
    
    if command -v ufw &>/dev/null; then
        ufw allow 3306/tcp >/dev/null 2>&1
        echo -e "${GREEN}Port 3306 opened${NC}"
    fi
    
    print_success "User '$DB_USER' created with remote access!"
    
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
}

show_menu() {
    clear
    print_header
    echo -e "${CYAN}            🚀 HIO'S HOSTING MANAGER              ${NC}"
    echo -e "${CYAN}                  Pterodactyl Tools               ${NC}"
    print_header
    echo -e "${CYAN}"
    echo "     _              _ _  _        _____           _     "
    echo "    / \   __ _ (_) | |( )___   |_   _|___   ___ | |___ "
    echo "   / _ \ / _\` || | | |// __|    | | / _ \ / _ \| / __|"
    echo "  / ___ \ (_| || | | | \__ \    | || (_) | (_) | \__ \\"
    echo " /_/   \_\__, ||_| |_| |___/    |_| \___/ \___/|_|___/"
    echo "            |_|                                        "
    echo -e "${NC}"
    print_header
    echo -e ""
    echo -e "${WHITE}${BOLD}  1)${NC} ${CYAN}Panel Installation${NC}"
    echo -e "${WHITE}${BOLD}  2)${NC} ${CYAN}Wings Installation${NC}"
    echo -e "${WHITE}${BOLD}  3)${NC} ${CYAN}Panel Update${NC}"
    echo -e "${WHITE}${BOLD}  4)${NC} ${CYAN}Uninstall Tools${NC}"
    echo -e "${WHITE}${BOLD}  5)${NC} ${CYAN}Blueprint Setup${NC}"
    echo -e "${WHITE}${BOLD}  6)${NC} ${CYAN}Cloudflare Setup${NC}"
    echo -e "${WHITE}${BOLD}  7)${NC} ${CYAN}Theme Manager${NC}"
    echo -e "${WHITE}${BOLD}  8)${NC} ${CYAN}System Information${NC}"
    echo -e "${WHITE}${BOLD}  9)${NC} ${CYAN}Tailscale (VPN)${NC}"
    echo -e "${WHITE}${BOLD} 10)${NC} ${CYAN}Database Setup${NC}"
    echo -e "${WHITE}${BOLD} 11)${NC} ${CYAN}Blueprint Extensions${NC}"
    echo -e "${WHITE}${BOLD}  0)${NC} ${RED}Exit${NC}"
    echo -e ""
    print_header
    echo -e "${YELLOW}${BOLD}📝 Select option [0-11]: ${NC}"
}

welcome() {
    clear
    print_header
    echo -e "${CYAN}"
    echo "     _              _ _  _        _____           _     "
    echo "    / \   __ _ (_) | |( )___   |_   _|___   ___ | |___ "
    echo "   / _ \ / _\` || | | |// __|    | | / _ \ / _ \| / __|"
    echo "  / ___ \ (_| || | | | \__ \    | || (_) | (_) | \__ \\"
    echo " /_/   \_\__, ||_| |_| |___/    |_| \___/ \___/|_|___/"
    echo "            |_|                                        "
    echo -e "${NC}"
    echo -e "${CYAN}                 Hosting Manager${NC}"
    print_header
    sleep 1
}

# Main
welcome

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) run_script "${BASE_URL}/panel.sh" "Panel Installation" ;;
        2) run_script "${BASE_URL}/wings.sh" "Wings Installation" ;;
        3) run_script "${BASE_URL}/update.sh" "Panel Update" ;;
        4) run_script "${BASE_URL}/uninstall.sh" "Uninstall Tools" ;;
        5) run_script "${BASE_URL}/blueprint.sh" "Blueprint Setup" ;;
        6) run_script "${BASE_URL}/cloudflare.sh" "Cloudflare Setup" ;;
        7) run_script "${BASE_URL}/theme.sh" "Theme Manager" ;;
        8) system_info ;;
        9) tailscale_setup ;;
        10) database_setup ;;
        11) run_script "${BASE_URL}/extensions.sh" "Blueprint Extensions" ;;
        0)
            echo -e "${GREEN}Exiting Hio's Hosting Manager...${NC}"
            print_header
            echo -e "${CYAN}         Thank you for using Hio's Tools!      ${NC}"
            print_header
            sleep 1
            exit 0
            ;;
        *)
            print_error "Invalid option! Choose 0-11"
            sleep 1
            ;;
    esac
done
