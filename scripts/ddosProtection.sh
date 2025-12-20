#!/bin/bash
set -e
NEON='\033[38;2;43;233;138m'
MAGENTA='\033[38;2;249;38;114m'
BLUE='\033[38;2;50;142;255m'
RED='\033[38;2;230;42;25m'
YELLOW='\033[38;2;230;219;116m'
GREEN='\033[38;2;43;233;138m'
CYAN='\033[38;2;73;224;253m'
NC='\033[0m'

print_header() {
    echo -e "${NEON}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                    HIO DDoS PROTECTION INSTALLER                  ║"
    echo "║                        Safe for High-Traffic                      ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${RED}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root!"
    exit 1
fi

print_header

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION - Adjust these for your needs
# ═══════════════════════════════════════════════════════════════════════════════

# Rate limits per IP (adjust based on your server capacity)
SYN_LIMIT="100/s"        # New TCP connections per IP
SYN_BURST="200"          # Burst allowance
UDP_LIMIT="200/s"        # UDP packets per IP (game traffic)
UDP_BURST="400"          # Burst allowance
ICMP_LIMIT="10/s"        # Ping per IP
ICMP_BURST="20"          # Burst allowance

# Whitelist your admin IPs (separated by space)
WHITELIST_IPS=""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: Kernel Tuning (sysctl)
# ═══════════════════════════════════════════════════════════════════════════════

print_status "Applying kernel-level DDoS protection..."

cat <<EOF >/etc/sysctl.d/99-ddos-protect.conf
# ════════════════════════════════════════════════════════════════════
# HIO DDoS Protection - Kernel Parameters
# Safe for high-traffic game servers
# ════════════════════════════════════════════════════════════════════

# === TCP SYN Flood Protection ===
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# === Connection Handling (High Performance) ===
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# === Memory Tuning for High Connection Count ===
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.ip_local_port_range = 1024 65535

# === IP Spoofing Protection ===
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# === Disable Dangerous Features ===
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# === ICMP Protection ===
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_ratelimit = 100
net.ipv4.icmp_ratemask = 88089

# === RFC Compliance ===
net.ipv4.tcp_rfc1337 = 1

# === Conntrack for High Connection Count ===
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
EOF

sysctl --system > /dev/null 2>&1
print_success "Kernel parameters applied"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: Install iptables-persistent
# ═══════════════════════════════════════════════════════════════════════════════

print_status "Installing iptables-persistent..."
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent > /dev/null 2>&1
print_success "iptables-persistent installed"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: Load conntrack modules
# ═══════════════════════════════════════════════════════════════════════════════

print_status "Loading kernel modules..."
modprobe nf_conntrack 2>/dev/null || true
modprobe nf_conntrack_ipv4 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: Configure iptables (Per-IP Rate Limiting)
# ═══════════════════════════════════════════════════════════════════════════════

print_status "Configuring iptables rules..."

# Check if Docker is running
DOCKER_RUNNING=false
if systemctl is-active --quiet docker 2>/dev/null; then
    DOCKER_RUNNING=true
    print_warning "Docker detected - will preserve Docker chains"
fi

# Flush rules safely (preserve Docker chains if Docker is running)
print_warning "Flushing existing rules..."

if [ "$DOCKER_RUNNING" = true ]; then
    # Only flush INPUT chain, preserve FORWARD and Docker chains
    iptables -F INPUT
    iptables -t mangle -F
else
    # No Docker, safe to flush everything
    iptables -F
    iptables -X
    iptables -t mangle -F
    iptables -t mangle -X
fi

# Default policies - ACCEPT (we'll drop bad traffic explicitly)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# ─────────────────────────────────────────────────────────────────────────────
# WHITELIST - Admin IPs bypass all protection
# ─────────────────────────────────────────────────────────────────────────────
if [[ -n "$WHITELIST_IPS" ]]; then
    for ip in $WHITELIST_IPS; do
        iptables -A INPUT -s "$ip" -j ACCEPT
        print_status "Whitelisted: $ip"
    done
fi

# ─────────────────────────────────────────────────────────────────────────────
# LOOPBACK - Always allow localhost
# ─────────────────────────────────────────────────────────────────────────────
iptables -A INPUT -i lo -j ACCEPT

# ─────────────────────────────────────────────────────────────────────────────
# ESTABLISHED/RELATED - Allow existing connections (critical!)
# ─────────────────────────────────────────────────────────────────────────────
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ─────────────────────────────────────────────────────────────────────────────
# INVALID PACKETS - Drop malformed
# ─────────────────────────────────────────────────────────────────────────────
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# ─────────────────────────────────────────────────────────────────────────────
# TCP FLAG ATTACKS - Block scan techniques
# ─────────────────────────────────────────────────────────────────────────────
# XMAS Scan
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# NULL Scan  
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# FIN Scan
iptables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP
# SYN/RST (invalid)
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
# SYN/FIN (invalid)
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
# New without SYN
iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# ─────────────────────────────────────────────────────────────────────────────
# PER-IP RATE LIMITING (Safe for 1000+ players)
# ─────────────────────────────────────────────────────────────────────────────

# SYN Flood Protection - Per IP
iptables -A INPUT -p tcp --syn -m hashlimit \
    --hashlimit-name syn_flood \
    --hashlimit-mode srcip \
    --hashlimit-upto $SYN_LIMIT \
    --hashlimit-burst $SYN_BURST \
    --hashlimit-htable-expire 30000 \
    -j ACCEPT

# Excess SYN - Log and drop
iptables -A INPUT -p tcp --syn -m limit --limit 5/min -j LOG --log-prefix "DDOS-SYN-FLOOD: "
iptables -A INPUT -p tcp --syn -j DROP

# UDP Flood Protection - Per IP (Game Traffic)
iptables -A INPUT -p udp -m hashlimit \
    --hashlimit-name udp_flood \
    --hashlimit-mode srcip \
    --hashlimit-upto $UDP_LIMIT \
    --hashlimit-burst $UDP_BURST \
    --hashlimit-htable-expire 30000 \
    -j ACCEPT

# Excess UDP - Log and drop
iptables -A INPUT -p udp -m limit --limit 5/min -j LOG --log-prefix "DDOS-UDP-FLOOD: "
iptables -A INPUT -p udp -j DROP

# ICMP (Ping) Rate Limiting - Per IP
iptables -A INPUT -p icmp --icmp-type echo-request -m hashlimit \
    --hashlimit-name icmp_flood \
    --hashlimit-mode srcip \
    --hashlimit-upto $ICMP_LIMIT \
    --hashlimit-burst $ICMP_BURST \
    --hashlimit-htable-expire 30000 \
    -j ACCEPT

# Other ICMP types (needed for network functionality)
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type parameter-problem -j ACCEPT

# Drop excess ICMP
iptables -A INPUT -p icmp -j DROP

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: Save rules persistently
# ═══════════════════════════════════════════════════════════════════════════════

print_status "Saving iptables rules..."
netfilter-persistent save > /dev/null 2>&1
print_success "Rules saved and will persist after reboot"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: Create management commands
# ═══════════════════════════════════════════════════════════════════════════════

print_status "Creating management commands..."

# Status command
cat <<'EOF' >/usr/local/bin/ddos-status
#!/bin/bash
echo "═══════════════════════════════════════════════════════════════"
echo "              🛡️  DDoS Protection Status"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Active Connections:"
ss -s
echo ""
echo "🔥 iptables Packet Counters:"
iptables -L -v -n | head -40
echo ""
echo "📝 Recent Blocks (last 20):"
dmesg | grep "DDOS-" | tail -20
echo ""
echo "═══════════════════════════════════════════════════════════════"
EOF
chmod +x /usr/local/bin/ddos-status

# Whitelist command
cat <<'EOF' >/usr/local/bin/ddos-whitelist
#!/bin/bash
if [[ -z "$1" ]]; then
    echo "Usage: ddos-whitelist <IP>"
    echo "Current whitelist:"
    iptables -L INPUT -n | grep -E "^ACCEPT.*all.*--" | awk '{print $4}'
    exit 1
fi
iptables -I INPUT 1 -s "$1" -j ACCEPT
netfilter-persistent save > /dev/null 2>&1
echo "✅ Whitelisted: $1"
EOF
chmod +x /usr/local/bin/ddos-whitelist

# Disable command
cat <<'EOF' >/usr/local/bin/ddos-disable
#!/bin/bash
echo "⚠️  Disabling DDoS protection..."
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "✅ DDoS protection disabled. Run the installer again to re-enable."
EOF
chmod +x /usr/local/bin/ddos-disable

print_success "Management commands created"

# ═══════════════════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         ✅ HIO DDoS Protection Installed Successfully!           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${ORANGE}📊 Rate Limits (Per IP):${NC}"
echo "   • TCP SYN:  $SYN_LIMIT (burst: $SYN_BURST)"
echo "   • UDP:      $UDP_LIMIT (burst: $UDP_BURST)"  
echo "   • ICMP:     $ICMP_LIMIT (burst: $ICMP_BURST)"
echo ""
echo -e "${ORANGE}🛠️  Management Commands:${NC}"
echo "   • ddos-status    - View protection status & blocked IPs"
echo "   • ddos-whitelist - Add IP to whitelist"
echo "   • ddos-disable   - Temporarily disable protection"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "   • Whitelist your admin IP: ddos-whitelist YOUR_IP"
echo "   • Check blocked attacks: dmesg | grep DDOS-"
echo "   • Rules persist after reboot automatically"
echo ""
