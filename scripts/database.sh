#!/bin/bash

# ============================================
# DATABASE REMOTE ACCESS SETUP
# by Hio
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
echo -e "${NEON}        Database Remote Access Setup${NC}"
echo -e "${NEON}                  by Hio${NC}"
print_header
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Get user input
read -p "$(echo -e "${YELLOW}Enter new database username: ${NC}")" DB_USER
read -sp "$(echo -e "${YELLOW}Enter password: ${NC}")" DB_PASS
echo ""

if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
    print_error "Username and password cannot be empty!"
    exit 1
fi

print_status "Creating database user '$DB_USER'"

mysql -u root -p <<MYSQL_SCRIPT
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

if [ $? -ne 0 ]; then
    print_error "Failed to create database user"
    exit 1
fi

print_success "User '$DB_USER' created"

# Update bind-address
CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
if [ -f "$CONF" ]; then
    print_status "Updating bind-address"
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF"
    print_success "Bind-address updated"
fi

# Restart services
print_status "Restarting database services"
systemctl restart mysql 2>/dev/null || true
systemctl restart mariadb 2>/dev/null || true
print_success "Services restarted"

# Open firewall port
if command -v ufw &>/dev/null; then
    ufw allow 3306/tcp >/dev/null 2>&1
    print_success "Port 3306 opened in firewall"
fi

echo ""
print_header
echo -e "${GREEN}✅ Database remote access configured!${NC}"
print_header
echo ""
echo -e "${NEON}Connection Details:${NC}"
echo -e "  • Username: ${GREEN}${DB_USER}${NC}"
echo -e "  • Host: ${GREEN}YOUR_SERVER_IP${NC}"
echo -e "  • Port: ${GREEN}3306${NC}"
echo ""
print_header
echo -e "${NEON}           Thank you for using Hio Tools!${NC}"
print_header
