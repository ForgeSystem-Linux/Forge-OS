#!/bin/bash
# Forge DE Installation Script
# This script installs Forge DE system files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Forge DE Installation Script"
echo "============================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Install D-Bus configuration
echo "Installing D-Bus configuration..."
cp "$PROJECT_DIR/forge-privilege/org.forge.Privilege.conf" /etc/dbus-1/system.d/
echo "  Installed: /etc/dbus-1/system.d/org.forge.Privilege.conf"

# Install PolicyKit policy
echo "Installing PolicyKit policy..."
cp "$PROJECT_DIR/forge-privilege/org.forge.Privilege.policy" /usr/share/polkit-1/actions/
echo "  Installed: /usr/share/polkit-1/actions/org.forge.Privilege.policy"

# Reload D-Bus
echo "Reloading D-Bus..."
systemctl reload dbus 2>/dev/null || true

echo ""
echo "Installation complete!"
echo ""
echo "To start the privilege escalation service, run:"
echo "  forge-privilege"
echo ""
echo "To use pkexec from other components:"
echo "  pkexec <command>"
echo ""
