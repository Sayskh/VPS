#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}         🧩 BLUEPRINT EXTENSIONS INSTALLER        ${NC}"
echo -e "${CYAN}                    by Hio                       ${NC}"
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

echo -e "${YELLOW}⏳ Downloading extensions...${NC}"
wget -q https://github.com/NotJishnuisback/Free123/raw/refs/heads/main/minecraftplayermanager.blueprint
wget -q https://github.com/NotJishnuisback/Free123/raw/refs/heads/main/mcplugins.blueprint
echo -e "${GREEN}✅ Extensions downloaded${NC}"

echo -e "${YELLOW}⏳ Installing mcplugins...${NC}"
blueprint -i mcplugins.blueprint && echo -e "${GREEN}✅ mcplugins installed${NC}"

echo -e "${YELLOW}⏳ Installing minecraftplayermanager...${NC}"
blueprint -i minecraftplayermanager.blueprint && echo -e "${GREEN}✅ MC Player Manager installed${NC}"

echo -e "\n${GREEN}🎉 All extensions installed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}           Thank you for using Hio's Tools!     ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
