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
echo -e "${ORANGE}        Database Remote Access Setup${NC}"
echo -e "${ORANGE}                  by Hio${NC}"
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
echo -e "${ORANGE}Connection Details:${NC}"
echo -e "  • Username: ${GREEN}${DB_USER}${NC}"
echo -e "  • Host: ${GREEN}YOUR_SERVER_IP${NC}"
echo -e "  • Port: ${GREEN}3306${NC}"
echo ""
print_header
echo -e "${ORANGE}           Thank you for using Hio Tools!${NC}"
print_header
