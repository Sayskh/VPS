#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}"
echo ' ______  __  __  ______  ______  __   __  ______  '
echo '/\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  ___\ '
echo '\ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \___  \'
echo ' \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\/\_____\'
echo '  \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/_____/'
echo -e "${NC}"
echo -e "${CYAN}        Blueprint Extensions Installer${NC}"
echo -e "${CYAN}                  by Hio${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Installing curl...${NC}"
    apt-get install -y curl
fi

cd /var/www/pterodactyl || { echo -e "${RED}Panel not found!${NC}"; exit 1; }

# Download blueprints from repo
REPO_URL="https://raw.githubusercontent.com/Sayskh/VPS/main/plugin"

echo -e "${YELLOW}⏳ Downloading extensions...${NC}"
wget -q "${REPO_URL}/mcplugins.blueprint"
wget -q "${REPO_URL}/minecraftplayermanager.blueprint"
wget -q "${REPO_URL}/subdomains.blueprint"
echo -e "${GREEN}✅ Extensions downloaded${NC}"

echo -e "${YELLOW}⏳ Installing mcplugins...${NC}"
blueprint -i mcplugins.blueprint && echo -e "${GREEN}✅ mcplugins installed${NC}"

echo -e "${YELLOW}⏳ Installing minecraftplayermanager...${NC}"
blueprint -i minecraftplayermanager.blueprint && echo -e "${GREEN}✅ MC Player Manager installed${NC}"

echo -e "${YELLOW}⏳ Installing subdomains...${NC}"
blueprint -i subdomains.blueprint && echo -e "${GREEN}✅ Subdomains installed${NC}"

echo -e "\n${GREEN}🎉 All extensions installed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}           Thank you for using Hio's Tools!     ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

