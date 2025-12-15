#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${MAGENTA}⚠️  $1${NC}"; }

confirm_action() {
    local message="$1"
    echo -e "${RED}$message${NC}"
    read -p "$(echo -e "${YELLOW}Are you sure? (y/N): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Operation cancelled.${NC}"
        return 1
    fi
    return 0
}

cleanup_nginx() {
    print_status "Removing Nginx configuration"
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf 2>/dev/null || true
    rm -f /etc/nginx/sites-available/pterodactyl.conf 2>/dev/null || true
    rm -f /etc/nginx/conf.d/pterodactyl.conf 2>/dev/null || true
    
    if command -v nginx >/dev/null 2>&1; then
        systemctl restart nginx 2>/dev/null || true
    fi
    print_success "Nginx configuration removed"
}

uninstall_panel() {
    print_header "UNINSTALLING PTERODACTYL PANEL"
    
    if ! confirm_action "This will PERMANENTLY delete the Panel and all its data!"; then
        return
    fi

    print_status "Stopping pteroq service"
    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload
    print_success "Panel service stopped"

    print_status "Removing cronjob"
    crontab -l 2>/dev/null | grep -v 'pterodactyl/artisan schedule:run' | crontab - 2>/dev/null || true
    print_success "Cronjob removed"

    print_status "Removing Panel files"
    rm -rf /var/www/pterodactyl
    print_success "Panel files removed"

    print_status "Removing database"
    mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    print_success "Database removed"

    print_status "Removing SSL certificates"
    rm -rf /etc/certs/panel 2>/dev/null || true
    print_success "SSL certificates removed"

    cleanup_nginx

    print_success "Panel uninstalled successfully!"
}

uninstall_wings() {
    print_header "UNINSTALLING PTERODACTYL WINGS"
    
    if ! confirm_action "This will PERMANENTLY delete Wings and all server data!"; then
        return
    fi

    print_status "Stopping Wings service"
    systemctl stop wings.service 2>/dev/null || true
    systemctl disable wings.service 2>/dev/null || true
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    print_success "Wings service stopped"

    print_status "Removing Wings files"
    rm -rf /etc/pterodactyl
    rm -rf /var/lib/pterodactyl
    rm -rf /var/log/pterodactyl
    rm -f /usr/local/bin/wings
    rm -f /usr/local/bin/wing
    print_success "Wings files removed"

    print_status "Removing SSL certificates"
    rm -rf /etc/certs/wings 2>/dev/null || true
    print_success "SSL certificates removed"

    print_success "Wings uninstalled successfully!"
}

uninstall_both() {
    print_header "UNINSTALLING PANEL AND WINGS"
    
    if ! confirm_action "This will PERMANENTLY delete BOTH Panel and Wings!"; then
        return
    fi

    uninstall_panel
    uninstall_wings
    
    print_success "Panel and Wings uninstalled!"
}

show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}            🗑️  PTERODACTYL UNINSTALLER          ${NC}"
    echo -e "${CYAN}                     by Hio                      ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║               📋 UNINSTALL OPTIONS            ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}1)${NC} ${CYAN}Uninstall Panel Only${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}2)${NC} ${CYAN}Uninstall Wings Only${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}3)${NC} ${CYAN}Uninstall Both (Panel + Wings)${NC}        ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}0)${NC} ${RED}Exit${NC}                                   ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${MAGENTA}⚠️  WARNING: These actions CANNOT be undone!${NC}"
    echo -e ""
}

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

while true; do
    show_menu
    
    read -p "$(echo -e "${YELLOW}Choose an option [0-3]: ${NC}")" choice

    case $choice in
        1) uninstall_panel ;;
        2) uninstall_wings ;;
        3) uninstall_both ;;
        0) 
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *) 
            print_error "Invalid option!"
            sleep 2
            ;;
    esac

    echo -e ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
done
