#!/bin/bash
NEON='\033[38;2;43;233;138m'
MAGENTA='\033[38;2;249;38;114m'
BLUE='\033[38;2;50;142;255m'
RED='\033[38;2;230;42;25m'
YELLOW='\033[38;2;230;219;116m'
GREEN='\033[38;2;43;233;138m'
CYAN='\033[38;2;73;224;253m'
NC='\033[0m'

clear
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${NEON}        Blueprint Extensions Installer${NC}"
echo -e "${NEON}                  by Hio${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

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
echo -e "${CYAN}           Thank you for using Hio Tools!     ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

