#!/bin/bash
# TorDaemon Install Script
# Repository: https://github.com/MoE1N/tor-daemon

INSTALL_DIR="/usr/local/share/tord"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/tord"
SCRIPT_NAME="tord"
LINK_NAME="tord"
REPO_RAW_URL="https://raw.githubusercontent.com/MoE1N/tor-daemon/main"

# Check for root
if [ "$EUID" -ne 0 ]; then
   echo "Please run as root (e.g. sudo bash install.sh)"
   exit 1
fi

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS_ID=$ID
        OS_LIKE=$ID_LIKE
        # Combine ID and ID_LIKE for better matching
        OS_COMBINED="$OS_ID $OS_LIKE"
    elif [ "$(uname)" = "Darwin" ]; then
        OS_ID="macos"
        OS_LIKE="macos"
        OS_COMBINED="macos"
    else
        OS_ID="unknown"
        OS_LIKE="unknown"
        OS_COMBINED="unknown"
    fi
}

install_tor() {
    echo "[+] Checking Tor installation..."
    
    if command -v tor >/dev/null 2>&1; then
        echo "[+] Tor is already installed."
        return 0
    fi
    
    echo "[+] Installing Tor..."
    detect_os
    
    case "$OS_COMBINED" in
        *ubuntu*|*debian*|*linuxmint*)
            apt-get update
            apt-get install -y tor
            ;;
        *fedora*|*rhel*|*centos*)
            dnf install -y tor || yum install -y tor
            ;;
        *arch*|*manjaro*)
            pacman -S --noconfirm tor
            ;;
        *macos*)
            if command -v brew >/dev/null 2>&1; then
                brew install tor
            else
                echo "[!] Homebrew not found. Please install Tor manually."
                return 1
            fi
            ;;
        *)
            echo "[!] Unsupported OS. Please install Tor manually."
            return 1
            ;;
    esac
}

enable_tor_service() {
    echo "[+] Configuring Tor service..."
    
    detect_os
    
    if command -v systemctl >/dev/null 2>&1; then
        # Enable and start Tor service
        systemctl enable tor 2>/dev/null || systemctl enable tor@default 2>/dev/null
        systemctl start tor 2>/dev/null || systemctl start tor@default 2>/dev/null
        
        if systemctl is-active --quiet tor || systemctl is-active --quiet tor@default; then
            echo "[+] Tor service is running."
        else
            echo "[!] Failed to start Tor service. You may need to start it manually."
        fi
    elif [ "$OS_ID" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew services start tor
            echo "[+] Tor service started via Homebrew."
        fi
    else
        echo "[!] systemctl not found. You may need to start Tor manually."
    fi
}

install_app() {
    echo "[+] Installing TorDaemon..."
    
    # Install Tor if needed
    install_tor
    enable_tor_service
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Install script: Use local if available, else download
    if [ -f "./$SCRIPT_NAME" ]; then
        echo "[+] Found local $SCRIPT_NAME, using it."
        cp "./$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
    else
        echo "[+] Downloading $SCRIPT_NAME from repository..."
        if command -v curl >/dev/null 2>&1; then
            curl -sL "$REPO_RAW_URL/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$INSTALL_DIR/$SCRIPT_NAME" "$REPO_RAW_URL/$SCRIPT_NAME"
        else
            echo "[!] Error: curl or wget required to download files."
            exit 1
        fi
    fi

    # Verify installation
    if [ ! -s "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        echo "[!] Error: Failed to install $SCRIPT_NAME (empty or missing)."
        exit 1
    fi

    # Set permissions
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    
    # Create symlink
    rm -f "$BIN_DIR/$LINK_NAME"
    ln -s "$INSTALL_DIR/$SCRIPT_NAME" "$BIN_DIR/$LINK_NAME"
    
    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_DIR/config" ]; then
        cat > "$CONFIG_DIR/config" << 'EOF'
# TorDaemon Configuration
SOCKS_HOST=127.0.0.1
SOCKS_PORT=9050
INTERVAL=60
EOF
        chmod 644 "$CONFIG_DIR/config"
        echo "[+] Created default configuration at $CONFIG_DIR/config"
    fi
    
    echo ""
    echo "[+] Installation successful!"
    echo "[+] Run '$LINK_NAME' to start."
}

uninstall_app() {
    echo "[+] Uninstalling TorDaemon..."
    
    # Stop any running tord processes
    pkill -f "$INSTALL_DIR/$SCRIPT_NAME" 2>/dev/null
    
    # Remove files and directories
    rm -rf "$INSTALL_DIR"
    rm -rf "$CONFIG_DIR"
    rm -f "$BIN_DIR/$LINK_NAME"
    
    echo "[+] TorDaemon uninstalled successfully."
    echo ""
    read -r -p "Do you want to remove Tor as well? [y/N] " remove_tor
    
    if [[ "$remove_tor" =~ ^[Yy]$ ]]; then
        echo "[+] Removing Tor..."
        detect_os
        
        case "$OS_COMBINED" in
            *ubuntu*|*debian*|*linuxmint*)
                apt-get remove -y tor
                ;;
            *fedora*|*rhel*|*centos*)
                dnf remove -y tor || yum remove -y tor
                ;;
            *arch*|*manjaro*)
                pacman -R --noconfirm tor
                ;;
            *macos*)
                brew uninstall tor
                brew services stop tor 2>/dev/null
                ;;
        esac
        echo "[+] Tor removed."
    fi
}

# Main Argument Handling
case "$1" in
    uninstall|--uninstall)
        uninstall_app
        ;;
    *)
        install_app
        ;;
esac
