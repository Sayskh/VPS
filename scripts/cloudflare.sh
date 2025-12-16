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
echo ' ______  __      ______  __  __  _____         '
echo '/\  ___\/\ \    /\  __ \/\ \/\ \/\  __-.       '
echo '\ \ \___\ \ \___\ \ \/\ \ \ \_\ \ \ \/\ \      '
echo ' \ \_____\ \_____\ \_____\ \_____\ \____-      '
echo '  \/_____/\/_____/\/_____/\/_____/\/____/      '
echo -e "${NC}"
echo -e "${CYAN}           Cloudflared Installer${NC}"
echo -e "${CYAN}                by Hio${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}⏳ Creating keyrings directory...${NC}"
mkdir -p --mode=0755 /usr/share/keyrings
echo -e "${GREEN}✅ Done${NC}"

echo -e "${YELLOW}⏳ Adding Cloudflare GPG key...${NC}"
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo -e "${GREEN}✅ Done${NC}"

echo -e "${YELLOW}⏳ Adding repository...${NC}"
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
echo -e "${GREEN}✅ Done${NC}"

echo -e "${YELLOW}⏳ Installing cloudflared...${NC}"
apt-get update && apt-get install -y cloudflared

if command -v cloudflared >/dev/null 2>&1; then
    echo -e "\n${GREEN}✅ Cloudflared installed successfully!${NC}"
    echo -e "\n${CYAN}Next: cloudflared tunnel login${NC}"
else
    echo -e "${RED}❌ Installation failed${NC}"
fi
