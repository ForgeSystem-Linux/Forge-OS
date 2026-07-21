#!/bin/bash
# Quick build and install for Arch Linux
# Usage: ./install-arch.sh

set -e

echo "Forge DE - Arch Linux Installer"
echo "================================"
echo ""

# Check dependencies
echo "Checking dependencies..."
MISSING=""
for pkg in cargo cmake qt6-base qt6-declarative qt6-wayland wayland libinput libseat libgbm xkbcommon polkit pam; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    echo "Missing packages:$MISSING"
    echo ""
    echo "Install them with:"
    echo "  sudo pacman -S$MISSING"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Building Forge DE..."
cargo build --release

echo ""
echo "Installing to /usr/local/bin (no sudo needed for testing)..."
mkdir -p ~/.local/bin

cp target/release/forge-compositor ~/.local/bin/
cp target/release/forge-shell ~/.local/bin/
cp target/release/forge-settings ~/.local/bin/
cp target/release/forge-notifications ~/.local/bin/
cp target/release/forge-privilege ~/.local/bin/
cp target/release/forge-session ~/.local/bin/
cp target/release/forge-greeter ~/.local/bin/
cp target/release/forge-clip ~/.local/bin/
cp target/release/forge-screenshot ~/.local/bin/

echo "Installing direct run script..."
mkdir -p ~/.local/share/forge
cp forge-shell/direct/forge-shell-direct ~/.local/bin/
cp forge-shell/direct/forge-shell-direct.qml ~/.local/share/forge/

echo "Installing QML files..."
cp forge-shell/qml/*.qml ~/.local/share/forge/

echo ""
echo "================================"
echo "Installation complete!"
echo ""
echo "Quick start from Hyprland:"
echo "  forge-shell-direct"
echo ""
echo "Or run the full compositor (in a tty):"
echo "  forge-compositor --backend winit"
echo ""
echo "If ~/.local/bin is not in your PATH, add it:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
