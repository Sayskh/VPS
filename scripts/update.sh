#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "     \b\b\b\b\b"
}

# Welcome
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}            🔄 PTERODACTYL PANEL UPDATER          ${NC}"
echo -e "${CYAN}                     by Hio                      ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_header "STARTING UPDATE"

# Go to panel directory
print_status "Checking panel directory"
cd /var/www/pterodactyl || { print_error "Panel not found at /var/www/pterodactyl"; exit 1; }
print_success "Panel directory found"

# Maintenance mode
print_header "MAINTENANCE MODE"
print_status "Enabling maintenance mode"
php artisan down > /dev/null 2>&1 &
spinner $!
print_success "Maintenance mode enabled"

# Download update
print_header "DOWNLOADING UPDATE"
print_status "Downloading latest release"
curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv > /dev/null 2>&1 &
spinner $!
print_success "Update downloaded"

# Fix permissions
print_header "FIXING PERMISSIONS"
print_status "Setting permissions"
chmod -R 755 storage/* bootstrap/cache > /dev/null 2>&1 &
spinner $!
print_success "Permissions fixed"

# Composer install
print_header "INSTALLING DEPENDENCIES"
print_status "Running composer install"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader > /dev/null 2>&1 &
spinner $!
print_success "Dependencies installed"

# Clear caches
print_header "CLEARING CACHE"
print_status "Clearing view cache"
php artisan view:clear > /dev/null 2>&1 &
spinner $!
print_success "View cache cleared"

print_status "Clearing config cache"
php artisan config:clear > /dev/null 2>&1 &
spinner $!
print_success "Config cache cleared"

# Migrations
print_header "DATABASE MIGRATION"
print_status "Running migrations"
php artisan migrate --seed --force > /dev/null 2>&1 &
spinner $!
print_success "Migrations completed"

# Ownership
print_header "FIXING OWNERSHIP"
print_status "Setting ownership to www-data"
chown -R www-data:www-data /var/www/pterodactyl/* > /dev/null 2>&1 &
spinner $!
print_success "Ownership fixed"

# Restart queue
print_header "RESTARTING SERVICES"
print_status "Restarting queue workers"
php artisan queue:restart > /dev/null 2>&1 &
spinner $!
print_success "Queue workers restarted"

# Disable maintenance
print_header "FINISHING UP"
print_status "Disabling maintenance mode"
php artisan up > /dev/null 2>&1 &
spinner $!
print_success "Panel is back online"

# Complete
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}         🎉 UPDATE COMPLETED SUCCESSFULLY!        ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "${CYAN}📋 UPDATE SUMMARY:${NC}"
echo -e "  ${GREEN}•${NC} Downloaded latest panel version"
echo -e "  ${GREEN}•${NC} Updated file permissions"
echo -e "  ${GREEN}•${NC} Installed PHP dependencies"
echo -e "  ${GREEN}•${NC} Cleared application cache"
echo -e "  ${GREEN}•${NC} Ran database migrations"
echo -e "  ${GREEN}•${NC} Restarted queue workers"
echo -e ""
echo -e "${YELLOW}🔍 Verify your panel is working correctly!${NC}"
echo -e ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}              Thank you for using Hio's Tools!   ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
read -p "$(echo -e "${YELLOW}Press Enter to exit...${NC}")" -n 1
