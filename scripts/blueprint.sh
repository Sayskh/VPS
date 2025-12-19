#!/bin/bash

NEON='\033[38;5;118m'
ORANGE='\033[38;5;208m'
PURPLE='\033[0;35m'
RED='\033[0;91m'
YELLOW='\033[0;93m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
NC='\033[0m'

print_header() {
    echo -e "\n${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${ORANGE} $1 ${NC}"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
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

welcome() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}              Blueprint Installer${NC}"
    echo -e "${CYAN}                   by Hio${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 1
}

install_fresh() {
    print_header "FRESH INSTALLATION"
    
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        return 1
    fi

    # Install Node.js 20.x
    print_header "INSTALLING NODE.JS 20.x"
    print_status "Installing prerequisites"
    apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1 &
    spinner $!
    
    print_status "Setting up Node.js repository"
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg > /dev/null 2>&1
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | \
        tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    
    print_status "Updating package list"
    apt-get update > /dev/null 2>&1 &
    spinner $!
    
    print_status "Installing Node.js"
    apt-get install -y nodejs > /dev/null 2>&1 &
    spinner $!
    print_success "Node.js installed"

    # Install Yarn
    print_header "INSTALLING YARN"
    print_status "Installing Yarn globally"
    npm i -g yarn > /dev/null 2>&1 &
    spinner $!
    print_success "Yarn installed"

    # Setup in Panel directory
    print_status "Changing to panel directory"
    cd /var/www/pterodactyl || { print_error "Panel not found!"; return 1; }
    
    print_status "Installing Yarn dependencies"
    yarn > /dev/null 2>&1 &
    spinner $!
    print_success "Yarn dependencies installed"

    # Additional packages
    print_status "Installing additional tools"
    apt install -y zip unzip git curl wget > /dev/null 2>&1 &
    spinner $!
    print_success "Tools installed"

    # Download Blueprint
    print_header "DOWNLOADING BLUEPRINT"
    print_status "Fetching latest release"
    wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | \
        grep 'browser_download_url' | cut -d '"' -f 4)" -O release.zip > /dev/null 2>&1 &
    spinner $!
    print_success "Blueprint downloaded"

    print_status "Extracting files"
    unzip -o release.zip > /dev/null 2>&1 &
    spinner $!
    print_success "Files extracted"

    # Run installer
    print_header "RUNNING BLUEPRINT INSTALLER"
    if [ ! -f "blueprint.sh" ]; then
        print_error "blueprint.sh not found!"
        return 1
    fi

    chmod +x blueprint.sh
    print_success "Running installer..."
    bash blueprint.sh
}

reinstall() {
    print_header "REINSTALLING BLUEPRINT"
    print_status "Rerunning installation"
    blueprint -rerun-install > /dev/null 2>&1 &
    spinner $!
    print_success "Reinstallation completed"
}

update() {
    print_header "UPDATING BLUEPRINT"
    print_status "Running upgrade"
    blueprint -upgrade > /dev/null 2>&1 &
    spinner $!
    print_success "Update completed"
}

show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}            🔧 BLUEPRINT INSTALLER               ${NC}"
    echo -e "${CYAN}                   by Hio                       ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                📋 MAIN MENU                   ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}1)${NC} ${CYAN}Fresh Install${NC}                          ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}2)${NC} ${CYAN}Reinstall (Rerun)${NC}                      ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}3)${NC} ${CYAN}Update Blueprint${NC}                       ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}0)${NC} ${RED}Exit${NC}                                   ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e ""
}

# Main
welcome

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) install_fresh ;;
        2) reinstall ;;
        3) update ;;
        0) 
            echo -e "${GREEN}Exiting...${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}           Thank you for using Hio Tools!    ${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            exit 0 
            ;;
        *) 
            print_error "Invalid option!"
            sleep 1
            ;;
    esac
    
    echo -e ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
done
