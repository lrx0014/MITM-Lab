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

    echo "[+] Configuring dnsmasq to resolve victim.com to $server_ip"
    echo "address=/victim.com/$server_ip" | $SUDO tee "$dns_conf" >/dev/null

    $SUDO systemctl enable dnsmasq
    $SUDO systemctl restart dnsmasq
    echo "[+] dnsmasq reloaded with lab DNS entry"
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

    cat <<EOF

[i] Environment ready.
    - Nginx proxies victim.com to the Flask app on localhost.
    - dnsmasq resolves victim.com to $ip.
    - Point victim machines' DNS to $ip and start the Flask app on port 8000.
EOF
}

main "$@"
