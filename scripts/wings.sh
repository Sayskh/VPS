#!/bin/bash
set -e

# Colors for output
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

check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
        return 0
    else
        print_error "$2"
        return 1
    fi
}

# Welcome
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}            🚀 PTERODACTYL WINGS INSTALLER        ${NC}"
echo -e "${CYAN}                     by Hio                      ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_header "INSTALLING DOCKER"
print_status "Installing Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash > /dev/null 2>&1
check_success "Docker installed" "Failed to install Docker"

print_status "Enabling Docker service"
systemctl enable --now docker > /dev/null 2>&1
check_success "Docker service started" "Failed to start Docker"

print_header "UPDATING GRUB CONFIGURATION"
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    print_status "Enabling swap accounting"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' $GRUB_FILE
    update-grub > /dev/null 2>&1
    check_success "GRUB updated" "Failed to update GRUB"
else
    print_status "GRUB not found, skipping"
fi

print_header "INSTALLING WINGS"
print_status "Creating Pterodactyl directory"
mkdir -p /etc/pterodactyl
check_success "Directory created" "Failed to create directory"

print_status "Detecting system architecture"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then 
    ARCH="amd64"
    print_success "Detected AMD64 architecture"
else 
    ARCH="arm64"
    print_success "Detected ARM64 architecture"
fi

print_status "Downloading Wings binary"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH" > /dev/null 2>&1
check_success "Wings downloaded" "Failed to download Wings"

print_status "Setting permissions"
chmod u+x /usr/local/bin/wings
check_success "Permissions set" "Failed to set permissions"

print_header "CREATING WINGS SERVICE"
print_status "Creating systemd service"
tee /etc/systemd/system/wings.service > /dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
check_success "Service created" "Failed to create service"

print_status "Reloading systemd"
systemctl daemon-reload > /dev/null 2>&1
systemctl enable wings > /dev/null 2>&1
check_success "Wings service enabled" "Failed to enable service"

print_header "GENERATING SSL CERTIFICATE"
print_status "Creating certificate directory"
mkdir -p /etc/certs/wings
cd /etc/certs/wings

print_status "Generating self-signed certificate"
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Indonesia/L=Jakarta/O=Hio/CN=Wings Node" \
    -keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
check_success "SSL certificate generated" "Failed to generate certificate"

print_header "CREATING HELPER COMMAND"
print_status "Creating wing helper"
tee /usr/local/bin/wing > /dev/null <<'EOF'
#!/bin/bash
echo -e "\033[1;33m📖 Wings Helper Command\033[0m"
echo ""
echo -e "\033[1;36mStart Wings:\033[0m"
echo -e "    \033[1;32msudo systemctl start wings\033[0m"
echo ""
echo -e "\033[1;36mCheck Status:\033[0m"
echo -e "    \033[1;32msudo systemctl status wings\033[0m"
echo ""
echo -e "\033[1;36mView Logs:\033[0m"
echo -e "    \033[1;32msudo journalctl -u wings -f\033[0m"
echo ""
echo -e "\033[1;36mRestart Wings:\033[0m"
echo -e "    \033[1;32msudo systemctl restart wings\033[0m"
echo ""
echo -e "\033[1;33m⚠️  Make sure port 8080 is accessible\033[0m"
EOF
chmod +x /usr/local/bin/wing
check_success "Helper created" "Failed to create helper"

print_header "INSTALLATION COMPLETE"
echo -e "${GREEN}🎉 Wings has been successfully installed!${NC}"
echo -e ""
echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║              📋 NEXT STEPS                    ║${NC}"
echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
echo -e "${WHITE}║ ${CYAN}1.${NC} Add node in your Panel dashboard"
echo -e "${WHITE}║ ${CYAN}2.${NC} Copy the configuration to this server"
echo -e "${WHITE}║ ${CYAN}3.${NC} Start Wings: ${GREEN}sudo systemctl start wings${NC}"
echo -e "${WHITE}║ ${CYAN}4.${NC} Use helper: ${GREEN}wing${NC}"
echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
echo -e ""

# Auto-configure option
echo -e "${YELLOW}🔧 AUTO-CONFIGURATION${NC}"
read -p "$(echo -e "${YELLOW}Configure Wings now? (y/N): ${NC}")" AUTO_CONFIG

if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    print_header "CONFIGURING WINGS"
    
    echo -e "${CYAN}Enter details from your Pterodactyl Panel:${NC}\n"
    
    read -p "$(echo -e "${WHITE}UUID: ${NC}")" UUID
    read -p "$(echo -e "${WHITE}Token ID: ${NC}")" TOKEN_ID
    read -p "$(echo -e "${WHITE}Token: ${NC}")" TOKEN
    read -p "$(echo -e "${WHITE}Panel URL (e.g., https://panel.example.com): ${NC}")" REMOTE

    print_status "Creating configuration"
    tee /etc/pterodactyl/config.yml > /dev/null <<CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wings/fullchain.pem
    key: /etc/certs/wings/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${REMOTE}'
CFG

    check_success "Configuration saved" "Failed to save configuration"
    
    print_status "Starting Wings"
    systemctl start wings
    check_success "Wings started" "Failed to start Wings"
    
    echo -e ""
    echo -e "${GREEN}✅ Wings is now running!${NC}"
    echo -e "${YELLOW}Check status: ${GREEN}systemctl status wings${NC}"
else
    echo -e ""
    echo -e "${YELLOW}⚠️  Manual configuration required${NC}"
    echo -e "Edit: ${GREEN}/etc/pterodactyl/config.yml${NC}"
fi

echo -e ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}              Thank you for using Hio's Tools!   ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
