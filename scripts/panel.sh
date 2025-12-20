#!/bin/bash
clear
NEON='\033[38;2;43;233;138m'  
MAGENTA='\033[38;2;249;38;114m' 
BLUE='\033[38;2;50;142;255m' 
RED='\033[38;2;230;42;25m'  
YELLOW='\033[38;2;230;219;116m' 
GREEN='\033[38;2;43;233;138m' 
CYAN='\033[38;2;73;224;253m'  
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${NEON} $1 ${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${RED}⚠️  $1${NC}"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}           Pterodactyl Panel Installer${NC}"
echo -e "${CYAN}                    by Hio${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Get domain input
read -p "$(echo -e "${YELLOW}Enter your domain (e.g., panel.example.com): ${NC}")" DOMAIN

if [ -z "$DOMAIN" ]; then
    print_error "Domain cannot be empty!"
    exit 1
fi

print_header "INSTALLING DEPENDENCIES"
print_status "Updating system and installing required packages"
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "ubuntu" ]]; then
    print_success "Detected Ubuntu"
    print_status "Adding PPA for PHP"
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    print_success "Detected Debian"
    print_status "Adding SURY PHP repository"
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
else
    print_warning "Unknown OS: $OS. Proceeding anyway..."
fi

# Add Redis repository
print_status "Adding Redis repository"
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt update

print_header "INSTALLING PHP 8.3 & EXTENSIONS"
print_status "Installing PHP and required extensions"
apt install -y php8.3 php8.3-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server
print_success "PHP 8.3 and extensions installed"

print_header "INSTALLING COMPOSER"
print_status "Downloading and installing Composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
print_success "Composer installed"

print_header "DOWNLOADING PTERODACTYL PANEL"
print_status "Creating panel directory and downloading files"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
print_success "Panel files downloaded and extracted"

print_header "SETTING UP DATABASE"
DB_NAME="panel"
DB_USER="pterodactyl"

# Get database password
read -sp "$(echo -e "${YELLOW}Enter database password for pterodactyl user: ${NC}")" DB_PASS
echo ""

if [ -z "$DB_PASS" ]; then
    print_error "Database password cannot be empty!"
    exit 1
fi

print_status "Creating database and user"
mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"
print_success "Database '$DB_NAME' and user '$DB_USER' created"

print_header "CONFIGURING ENVIRONMENT"
print_status "Setting up .env file"
if [ ! -f ".env.example" ]; then
    curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
fi
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi
print_success "Environment configured"

print_header "INSTALLING PHP DEPENDENCIES"
print_status "Running composer install"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
print_success "PHP dependencies installed"

print_header "GENERATING APPLICATION KEY"
print_status "Generating key"
php artisan key:generate --force
print_success "Application key generated"

print_header "RUNNING MIGRATIONS"
print_status "Migrating database"
php artisan migrate --seed --force
print_success "Database migrated"

print_header "SETTING PERMISSIONS"
print_status "Setting ownership to www-data"
chown -R www-data:www-data /var/www/pterodactyl/*
print_success "Permissions set"

print_header "SETTING UP CRON JOB"
print_status "Adding scheduler to crontab"
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null | grep -v 'pterodactyl/artisan schedule:run'; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
print_success "Cron job added"

print_header "GENERATING SSL CERTIFICATE"
print_status "Creating self-signed SSL certificate"
mkdir -p /etc/certs/panel
cd /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Indonesia/L=Jakarta/O=Hio/CN=${DOMAIN}" \
    -keyout privkey.pem -out fullchain.pem
print_success "SSL certificate generated"

print_header "CONFIGURING NGINX"
print_status "Creating Nginx configuration"

# Get PHP version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
print_success "Nginx configured"

print_header "SETTING UP QUEUE WORKER"
print_status "Creating pteroq service"
tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
print_success "Queue worker configured"

print_header "CREATING ADMIN USER"
cd /var/www/pterodactyl
php artisan p:user:make

# Ensure APP_ENVIRONMENT_ONLY is set
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env

# Final output
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     🎉 PTERODACTYL PANEL INSTALLATION COMPLETE!  ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║           📋 INSTALLATION DETAILS             ║${NC}"
echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
echo -e "${WHITE}║ ${CYAN}🌐 Panel URL:${NC}     https://${DOMAIN}"
echo -e "${WHITE}║ ${CYAN}📂 Directory:${NC}     /var/www/pterodactyl"
echo -e "${WHITE}║ ${CYAN}🗄️  Database:${NC}      ${DB_NAME}"
echo -e "${WHITE}║ ${CYAN}👤 DB User:${NC}       ${DB_USER}"
echo -e "${WHITE}║ ${CYAN}🔑 DB Password:${NC}   ${DB_PASS}"
echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
echo -e ""
echo -e "${YELLOW}📝 NEXT STEPS:${NC}"
echo -e "  ${CYAN}•${NC} Point your domain to this server's IP"
echo -e "  ${CYAN}•${NC} Access your panel at ${GREEN}https://${DOMAIN}${NC}"
echo -e "  ${CYAN}•${NC} Install Wings on your game nodes"
echo -e ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}              Thank you for using Hio Tools!   ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
