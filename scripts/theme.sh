#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}            🎨 PTERODACTYL THEME MANAGER          ${NC}"
echo -e "${CYAN}                    by Hio                       ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

cd /var/www/pterodactyl || { echo -e "${RED}Panel not found!${NC}"; exit 1; }

show_menu() {
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║              🎨 THEME OPTIONS                 ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}1)${NC} ${CYAN}Restore Default Theme${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}2)${NC} ${CYAN}Rebuild Assets${NC}                         ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}0)${NC} ${RED}Exit${NC}                                   ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
}

while true; do
    show_menu
    read -p "$(echo -e "${YELLOW}Choose option: ${NC}")" choice

    case $choice in
        1)
            echo -e "${YELLOW}⏳ Restoring default theme...${NC}"
            php artisan view:clear
            php artisan config:clear
            yarn build:production 2>/dev/null || npm run build:production 2>/dev/null
            echo -e "${GREEN}✅ Default theme restored${NC}"
            ;;
        2)
            echo -e "${YELLOW}⏳ Rebuilding assets...${NC}"
            yarn build:production 2>/dev/null || npm run build:production 2>/dev/null
            echo -e "${GREEN}✅ Assets rebuilt${NC}"
            ;;
        0)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    echo ""
done
