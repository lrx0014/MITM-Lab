#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/lrx0014/MITM-Lab.git"
REPO_DIR="${REPO_DIR:-MITM-Lab}"
APP_DIR="$REPO_DIR/victim_site"

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
        $SUDO apt-get install -y "${missing[@]}"
    fi
}

clone_or_update_repo() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "[+] Cloning repository into $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    else
        echo "[+] Repository already present, updating"
        git -C "$REPO_DIR" pull --ff-only
    fi
}

start_app() {
    cd "$APP_DIR"

    if [ ! -d ".venv" ]; then
        echo "[+] Creating Python virtual environment"
        python3 -m venv .venv
    fi

    # shellcheck source=/dev/null
    source .venv/bin/activate
    echo "[+] Installing Python dependencies"
    pip install --upgrade pip
    pip install -r requirements.txt

    echo "[+] Starting victim application on port 8000"
    exec python app.py
}

main() {
    ensure_packages git python3 python3-venv python3-pip
    clone_or_update_repo

    if [ ! -d "$APP_DIR" ]; then
        echo "[!] Victim application directory not found at $APP_DIR" >&2
        exit 1
    fi

    start_app
}

main "$@"
