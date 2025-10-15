#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_NGINX_CONF="$REPO_ROOT/nginx_conf/nginx.conf"

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

ensure_packages() {
    local packages=("$@") missing=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        echo "[+] Installing missing packages: ${missing[*]}"
        $SUDO apt-get update
        $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    else
        echo "[+] Required packages already installed"
    fi
}

detect_server_ip() {
    if [ -n "${SERVER_IP:-}" ]; then
        echo "$SERVER_IP"
        return 0
    fi

    local ips ip
    ips="$(hostname -I 2>/dev/null || true)"
    for ip in $ips; do
        if [[ "$ip" != 127.* ]]; then
            echo "$ip"
            return 0
        fi
    done

    return 1
}

configure_nginx() {
    local site_available="/etc/nginx/sites-available/victim"
    local site_enabled="/etc/nginx/sites-enabled/victim"

    if [ ! -f "$REPO_NGINX_CONF" ]; then
        echo "[!] Nginx configuration template not found at $REPO_NGINX_CONF" >&2
        exit 1
    fi

    echo "[+] Deploying Nginx site configuration"
    $SUDO cp "$REPO_NGINX_CONF" "$site_available"

    if [ ! -e "$site_enabled" ]; then
        $SUDO ln -s "$site_available" "$site_enabled"
    fi

    $SUDO nginx -t
    $SUDO systemctl enable nginx
    $SUDO systemctl reload nginx
    echo "[+] Nginx is configured to proxy victim.com"
}

configure_dnsmasq() {
    local server_ip="$1"
    local dns_conf="/etc/dnsmasq.d/victim.conf"

    echo "[+] Configuring dnsmasq to resolve victim.com to $server_ip and bind to $server_ip"
    cat <<EOF | $SUDO tee "$dns_conf" >/dev/null
listen-address=$server_ip
bind-interfaces
address=/victim.com/$server_ip
EOF

    $SUDO systemctl enable dnsmasq
    $SUDO systemctl restart dnsmasq
    echo "[+] dnsmasq reloaded with lab DNS entry"
}

configure_systemd_resolved() {
    local server_ip="$1"
    local resolved_conf="/etc/systemd/resolved.conf"

    echo "[+] Configuring systemd-resolved to use dnsmasq on $server_ip"

    if [ ! -f "$resolved_conf" ]; then
        echo "[!] systemd-resolved configuration not found at $resolved_conf" >&2
        return
    fi

    $SUDO sed -i \
        -e "s/^#\?DNS=.*/DNS=$server_ip/" \
        -e "s/^#\?Domains=.*/Domains=~victim.com/" \
        "$resolved_conf"

    if ! grep -q "^DNS=$server_ip" "$resolved_conf"; then
        echo "DNS=$server_ip" | $SUDO tee -a "$resolved_conf" >/dev/null
    fi
    if ! grep -q "^Domains=~victim.com" "$resolved_conf"; then
        echo "Domains=~victim.com" | $SUDO tee -a "$resolved_conf" >/dev/null
    fi

    $SUDO systemctl restart systemd-resolved
    echo "[+] systemd-resolved now points to dnsmasq"
}

main() {
    ensure_packages nginx dnsmasq

    local ip
    if ! ip="$(detect_server_ip)"; then
        echo "[!] Unable to determine server IP address. Set SERVER_IP env variable and retry." >&2
        exit 1
    fi

    echo "[+] Using server IP: $ip"

    configure_nginx
    configure_dnsmasq "$ip"
    configure_systemd_resolved "$ip"

    cat <<EOF

[i] Environment ready.
    - Nginx proxies victim.com to the Flask app on localhost.
    - dnsmasq resolves victim.com to $ip.
    - systemd-resolved on this server trusts dnsmasq.
    - Point victim machines' DNS to $ip and start the Flask app on port 8000.
EOF
}

main "$@"
