#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/lrx0014/MITM-Lab.git"
APP_DIR="victim_site"
REPO_NGINX_CONF="./nginx_conf/nginx.conf"

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

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

    echo "[+] Deploying Nginx proxy configuration"
    $SUDO cp "$REPO_NGINX_CONF" "$site_available"

    if [ ! -e "$site_enabled" ]; then
        $SUDO ln -s "$site_available" "$site_enabled"
    fi

    $SUDO nginx -t
    $SUDO systemctl enable nginx

    if $SUDO systemctl is-active --quiet nginx; then
        $SUDO systemctl reload nginx
    else
        $SUDO systemctl start nginx
    fi

    echo "[+] Nginx is running with the latest lab configuration"
}

configure_dnsmasq() {
    local server_ip="$1"
    local dns_conf="/etc/dnsmasq.d/victim.conf"

    echo "[+] Configuring dnsmasq to resolve victim.com to $server_ip"
    cat <<EOF | $SUDO tee "$dns_conf" >/dev/null
listen-address=$server_ip
bind-interfaces
address=/victim.com/$server_ip
EOF

    $SUDO systemctl enable dnsmasq
    $SUDO systemctl restart dnsmasq
    echo "[+] dnsmasq is running with the lab DNS entry"
}

start_app() {
    cd "$APP_DIR"

    if [ ! -d ".venv" ]; then
        echo "[+] Creating Python virtual environment"
        python3 -m venv .venv
    fi

    # shellcheck source=/dev/null
    source .venv/bin/activate

    echo "[+] Starting victim application on port 8000"
    exec python app.py
}

main() {

    if [ ! -d "$APP_DIR" ]; then
        echo "[!] Victim application directory not found at $APP_DIR" >&2
        exit 1
    fi

    configure_nginx

    local ip
    if ! ip="$(detect_server_ip)"; then
        echo "[!] Unable to detect server IP address automatically. Set SERVER_IP and retry." >&2
        exit 1
    fi

    configure_dnsmasq "$ip"

    start_app
}

main "$@"
