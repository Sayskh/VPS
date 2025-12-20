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
echo -e "${NEON}           Cloudflared Installer${NC}"
echo -e "${NEON}                by Hio${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

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
