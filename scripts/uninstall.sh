#!/bin/bash
set -e

# Color Scheme: Neon Green, Red, Yellow
NEON='\033[38;5;118m'       # Hijau stabilo/neon green
RED='\033[0;91m'            # Merah terang
YELLOW='\033[0;93m'         # Kuning terang
GREEN='\033[0;32m'
WHITE='\033[1;37m'
NC='\033[0m'

# Paths
PANEL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/root/pterodactyl-backups"

print_header() {
    echo -e "\n${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${NEON} $1 ${NC}"
    echo -e "${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
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

# ═══════════════════════════════════════════════════════════════════════════════
# BACKUP FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

backup_panel() {
    print_header "BACKUP PANEL DATA"
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/panel_backup_${timestamp}.tar.gz"
    
    print_status "Creating backup"
    
    if [ -d "$PANEL_DIR" ]; then
        # Backup .env and database
        print_status "Backing up configuration"
        cp "$PANEL_DIR/.env" "${BACKUP_DIR}/.env_${timestamp}" 2>/dev/null || true
        
        print_status "Backing up database"
        mysqldump -u root panel > "${BACKUP_DIR}/database_${timestamp}.sql" 2>/dev/null || true
        
        print_status "Compressing files"
        tar -czf "$backup_file" -C /var/www pterodactyl 2>/dev/null || true
        
        print_success "Backup created: $backup_file"
        echo -e "${CYAN}Backup location: ${BACKUP_DIR}${NC}"
    else
        print_error "Panel not found at $PANEL_DIR"
    fi
}

backup_wings() {
    print_header "BACKUP WINGS DATA"
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    print_status "Backing up Wings configuration"
    
    if [ -f "/etc/pterodactyl/config.yml" ]; then
        cp /etc/pterodactyl/config.yml "${BACKUP_DIR}/wings_config_${timestamp}.yml"
        print_success "Wings config backed up"
    fi
    
    if [ -d "/var/lib/pterodactyl" ]; then
        print_status "Backing up server data (this may take a while)"
        tar -czf "${BACKUP_DIR}/wings_data_${timestamp}.tar.gz" -C /var/lib pterodactyl 2>/dev/null || true
        print_success "Server data backed up"
    fi
    
    echo -e "${CYAN}Backup location: ${BACKUP_DIR}${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# UNINSTALL FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

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
    
    # Offer backup
    read -p "$(echo -e "${YELLOW}Create backup before uninstalling? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        backup_panel
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
    
    # Offer backup
    read -p "$(echo -e "${YELLOW}Create backup before uninstalling? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        backup_wings
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

uninstall_blueprint() {
    print_header "UNINSTALLING BLUEPRINT"
    
    if [ ! -d "$PANEL_DIR" ]; then
        print_error "Panel not found!"
        return
    fi
    
    if [ ! -f "$PANEL_DIR/blueprint.sh" ]; then
        print_error "Blueprint is not installed!"
        return
    fi
    
    if ! confirm_action "This will remove Blueprint and all extensions!"; then
        return
    fi
    
    cd "$PANEL_DIR"
    
    print_status "Removing Blueprint"
    
    # Remove blueprint files
    rm -f blueprint.sh 2>/dev/null || true
    rm -rf .blueprint 2>/dev/null || true
    rm -rf resources/views/blueprint 2>/dev/null || true
    
    # Rebuild panel assets
    print_status "Rebuilding panel assets"
    php artisan view:clear 2>/dev/null || true
    php artisan config:clear 2>/dev/null || true
    
    if [ -f "package.json" ]; then
        yarn install --production 2>/dev/null || npm install --production 2>/dev/null || true
        yarn build:production 2>/dev/null || npm run build:production 2>/dev/null || true
    fi
    
    print_success "Blueprint removed!"
    print_warning "You may need to reinstall the panel to fully restore defaults"
}

uninstall_ddos_protection() {
    print_header "REMOVING DDoS PROTECTION"
    
    if ! confirm_action "This will remove all DDoS protection rules!"; then
        return
    fi
    
    print_status "Flushing iptables rules"
    iptables -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    iptables -t mangle -F 2>/dev/null || true
    iptables -t mangle -X 2>/dev/null || true
    
    # Reset to default accept
    iptables -P INPUT ACCEPT 2>/dev/null || true
    iptables -P FORWARD ACCEPT 2>/dev/null || true
    iptables -P OUTPUT ACCEPT 2>/dev/null || true
    
    print_status "Removing sysctl configuration"
    rm -f /etc/sysctl.d/99-ddos-protect.conf 2>/dev/null || true
    sysctl --system > /dev/null 2>&1 || true
    
    print_status "Removing management commands"
    rm -f /usr/local/bin/ddos-status 2>/dev/null || true
    rm -f /usr/local/bin/ddos-whitelist 2>/dev/null || true
    rm -f /usr/local/bin/ddos-disable 2>/dev/null || true
    
    print_status "Saving clean iptables state"
    netfilter-persistent save 2>/dev/null || true
    
    print_success "DDoS protection removed!"
}

restore_theme() {
    print_header "RESTORE DEFAULT THEME"
    
    if [ ! -d "$PANEL_DIR" ]; then
        print_error "Panel not found!"
        return
    fi
    
    if ! confirm_action "This will restore the default Pterodactyl theme!"; then
        return
    fi
    
    cd "$PANEL_DIR"
    
    print_status "Clearing cached views"
    php artisan view:clear 2>/dev/null || true
    php artisan config:clear 2>/dev/null || true
    php artisan cache:clear 2>/dev/null || true
    
    print_status "Rebuilding assets"
    if [ -f "package.json" ]; then
        yarn install --production 2>/dev/null || npm install --production 2>/dev/null || true
        yarn build:production 2>/dev/null || npm run build:production 2>/dev/null || true
    fi
    
    # Fix permissions
    chown -R www-data:www-data "$PANEL_DIR" 2>/dev/null || true
    
    print_success "Default theme restored!"
}

show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}           Pterodactyl Uninstaller${NC}"
    echo -e "${CYAN}                  by Hio${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║            🗑️  UNINSTALL OPTIONS              ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}1)${NC} ${CYAN}Uninstall Panel Only${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}2)${NC} ${CYAN}Uninstall Wings Only${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}3)${NC} ${CYAN}Uninstall Both (Panel + Wings)${NC}        ${WHITE}║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║            🔧 REMOVE EXTRAS                   ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}4)${NC} ${CYAN}Uninstall Blueprint${NC}                   ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}5)${NC} ${CYAN}Remove DDoS Protection${NC}                ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}6)${NC} ${CYAN}Restore Default Theme${NC}                 ${WHITE}║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║            💾 BACKUP OPTIONS                  ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}7)${NC} ${CYAN}Backup Panel Data${NC}                     ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}8)${NC} ${CYAN}Backup Wings Data${NC}                     ${WHITE}║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}0)${NC} ${RED}Exit${NC}                                   ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${MAGENTA}⚠️  WARNING: Uninstall actions CANNOT be undone!${NC}"
    echo -e "${CYAN}💡 TIP: Always backup before uninstalling!${NC}"
    echo -e ""
}

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

while true; do
    show_menu
    
    read -p "$(echo -e "${YELLOW}Choose an option [0-8]: ${NC}")" choice

    case $choice in
        1) uninstall_panel ;;
        2) uninstall_wings ;;
        3) uninstall_both ;;
        4) uninstall_blueprint ;;
        5) uninstall_ddos_protection ;;
        6) restore_theme ;;
        7) backup_panel ;;
        8) backup_wings ;;
        0) 
            echo -e "${GREEN}Exiting...${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}           Thank you for using Hio Tools!    ${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
