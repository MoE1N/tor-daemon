# TorDaemon (tord)

**TorDaemon** is a lightweight Bash utility to manage Tor connections and automatically rotate your IP address.

## 🚀 Quick Start

1. **Install:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/MoE1N/tor-daemon/main/install.sh | sudo bash
   ```
2. **Run:**
   ```bash
   tord           # Interactive Menu
   tord -t 60     # Rotate every 60s
   tord -d        # Run as background daemon
   ```

## 📋 Features
- **Zero Dependencies:** Pure Bash.
- **Modes:** Active (Timed) or Passive (On Disconnect).
- **Service Support:** Easily install as a systemd service.
- **Cross-Platform:** Linux & macOS.

## 🛠 Usage

### Interactive Mode
Launch the TUI for easy configuration and service management:
```bash
tord
```

### CLI Options
| Flag | Description | Example |
|------|-------------|---------|
| `-t`, `--time` | IP rotation interval (seconds). Use `0` for passive. | `tord -t 120` |
| `-d`, `--daemon` | Run in background. | `tord -d` |
| `-h`, `--help` | Show help. | `tord -h` |

### Service Management (systemd)
```bash
sudo systemctl enable tord   # Enable on startup
sudo systemctl start tord    # Start service
sudo systemctl status tord   # Check status
```

## 🌐 Proxy Settings
- **Type:** SOCKS5
- **Host:** `127.0.0.1`
- **Port:** `9050`

## ⚠️ Disclaimer
For educational and ethical testing only. Use responsibly.

## 📄 License
MIT License. See `LICENSE`.