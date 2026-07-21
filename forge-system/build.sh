#!/bin/bash
# Forge System ISO Builder (Plasma-based)
# Builds an Arch Linux ISO with KDE Plasma + Forge theme

set -e

BUILD_DIR="$HOME/forge-build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="$(dirname "$SCRIPT_DIR")"
ISO_NAME="forge-$(date +%Y%m%d)-x86_64.iso"

echo "Forge System Builder (Plasma Edition)"
echo "======================================"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Building Forge System ISO..."
echo ""

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create archiso profile
mkdir -p "$BUILD_DIR"/{airootfs,efiboot/grub,grub}

# KDE Plasma + Forge packages
cat > "$BUILD_DIR/packages.x86_64" << 'EOF'
base
linux
linux-firmware
nano
vim
networkmanager
network-manager-applet
bluez
bluez-utils
pipewire
pipewire-pulse
wireplumber
xdg-utils
xdg-desktop-portal
xdg-desktop-portal-kde
polkit
dbus
flatpak

# KDE Plasma 6
plasma-desktop
plasma-workspace
plasma-panel
plasma-nm
plasma-pa
plasma-systemmonitor
kde-config-sddm
sddm
sddm-kcm
systemsettings
dolphin
konsole
kate
ark
gwenview
okular
spectacle
filelight
kcalc
ksystemlog

# Qt 6
qt6-base
qt6-declarative
qt6-wayland
qt6-tools

# Display
libinput
libseat
libgbm
mesa
xorg-xwayland
libxkbcommon

# Forge custom tools
alacritty
git
base-devel
cmake
EOF

# Build Forge binaries if they don't exist
echo "Building Forge tools..."
cd "$FORGE_DIR"
if [ ! -f target/release/forge-settings ]; then
    cargo build --release 2>/dev/null || true
fi
cd "$SCRIPT_DIR"

# Bundle Forge binaries
echo "Bundling Forge tools..."
mkdir -p "$BUILD_DIR/airootfs/usr/local/bin"
mkdir -p "$BUILD_DIR/airootfs/usr/share/forge"
mkdir -p "$BUILD_DIR/airootfs/usr/share/forge/qml"
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system"
mkdir -p "$BUILD_DIR/airootfs/etc/pam.d"
mkdir -p "$BUILD_DIR/airootfs/etc/dbus-1/system.d"
mkdir -p "$BUILD_DIR/airootfs/usr/share/polkit-1/actions"
mkdir -p "$BUILD_DIR/airootfs/usr/share/wayland-sessions"
mkdir -p "$BUILD_DIR/airootfs/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$BUILD_DIR/airootfs/usr/bin"
mkdir -p "$BUILD_DIR/airootfs/etc/sddm.conf.d"
mkdir -p "$BUILD_DIR/airootfs/root"

# Copy Forge binaries
for bin in forge-settings forge-notifications forge-privilege forge-session forge-clip forge-screenshot; do
    if [ -f "$FORGE_DIR/target/release/$bin" ]; then
        cp "$FORGE_DIR/target/release/$bin" "$BUILD_DIR/airootfs/usr/local/bin/"
    fi
done

# Copy helper scripts
for script in forge-power.sh forge-apply.sh forge-install-helper.sh; do
    if [ -f "$FORGE_DIR/scripts/$script" ]; then
        name=$(basename "$script" .sh)
        cp "$FORGE_DIR/scripts/$script" "$BUILD_DIR/airootfs/usr/local/bin/$name"
    fi
done
cp "$FORGE_DIR/forge-shell/direct/generate-data.sh" "$BUILD_DIR/airootfs/usr/local/bin/forge-gen-data" 2>/dev/null || true

# Generate data.js
bash "$BUILD_DIR/airootfs/usr/local/bin/forge-gen-data" 2>/dev/null || true
cp "$HOME/.local/share/forge/data.js" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true

# Copy QML files
cp "$FORGE_DIR/forge-shell/direct/forge-shell-direct.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true
cp "$FORGE_DIR/forge-shell/qml/"*.qml "$BUILD_DIR/airootfs/usr/share/forge/qml/" 2>/dev/null || true
cp "$FORGE_DIR/forge-system/forge-dm.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true
cp "$FORGE_DIR/forge-setup/forge-setup.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true

# Copy DM and installer
cp "$FORGE_DIR/forge-system/forge-dm" "$BUILD_DIR/airootfs/usr/local/bin/" 2>/dev/null || true
cp "$FORGE_DIR/forge-setup/forge-setup" "$BUILD_DIR/airootfs/usr/local/bin/" 2>/dev/null || true
cp "$FORGE_DIR/forge-installer/forge-installer" "$BUILD_DIR/airootfs/usr/local/bin/" 2>/dev/null || true

# Copy icon
cp "$FORGE_DIR/packaging/forge-logo.svg" "$BUILD_DIR/airootfs/usr/share/icons/hicolor/scalable/apps/forge-logo.svg" 2>/dev/null || true

# Fix permissions
echo "Setting permissions..."
chmod 755 "$BUILD_DIR/airootfs/usr/local/bin/"* 2>/dev/null || true
chmod 755 "$BUILD_DIR/airootfs/usr/share/forge/"*.sh 2>/dev/null || true

# Install Plasma theme
echo "Installing Forge Plasma theme..."
THEME_DIR="$BUILD_DIR/airootfs/usr/share/plasma/look-and-feel/Forge.desktop"
mkdir -p "$THEME_DIR/contents/layouts"
cp "$FORGE_DIR/forge-theme/plasma/look-and-feel/metadata.desktop" "$THEME_DIR/"
cp "$FORGE_DIR/forge-theme/plasma/look-and-feel/contents/layouts/defaults" "$THEME_DIR/contents/layouts/" 2>/dev/null || true

# Install color scheme
mkdir -p "$BUILD_DIR/airootfs/usr/share/color-schemes"
cp "$FORGE_DIR/forge-theme/colors/Forge.colors" "$BUILD_DIR/airootfs/usr/share/color-schemes/" 2>/dev/null || true

# Install KWin config
mkdir -p "$BUILD_DIR/airootfs/etc/xdg"
cp "$FORGE_DIR/forge-theme/kwin/kwinrc" "$BUILD_DIR/airootfs/etc/xdg/" 2>/dev/null || true

# SDDM configuration
cat > "$BUILD_DIR/airootfs/etc/sddm.conf.d/forge.conf" << 'EOF'
[Theme]
Current=Forge

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
EOF

# Desktop session entry
cat > "$BUILD_DIR/airootfs/usr/share/wayland-sessions/forge.desktop" << 'EOF'
[Desktop Entry]
Name=Forge
Comment=Forge Desktop Environment (Plasma)
Exec=/usr/bin/startplasma-wayland
Type=Application
DesktopNames=KDE
EOF

# Systemd services
cat > "$BUILD_DIR/airootfs/etc/systemd/system/forge-notifications.service" << 'EOF'
[Unit]
Description=Forge Notification Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/forge-notifications
Restart=always

[Install]
WantedBy=graphical-session.target
EOF

# Enable SDDM
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.target.wants"
ln -sf /usr/lib/systemd/system/sddm.service "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.target.wants/sddm.service" 2>/dev/null || true

# PAM config
cat > "$BUILD_DIR/airootfs/etc/pam.d/forge-greeter" << 'EOF'
#%PAM-1.0
auth       required     pam_unix.so
account    required     pam_unix.so
session    required     pam_unix.so
EOF

# OOBE script
cat > "$BUILD_DIR/airootfs/usr/share/forge/forge-oobe.sh" << 'OOBESCRIPT'
#!/bin/bash
if [ ! -f /var/lib/forge/.oobe-done ]; then
    mkdir -p /var/lib/forge
    touch /var/lib/forge/.oobe-done
    /usr/local/bin/forge-setup
fi
OOBESCRIPT
chmod +x "$BUILD_DIR/airootfs/usr/share/forge/forge-oobe.sh"

# Root shell profile
cat > "$BUILD_DIR/airootfs/root/.bash_profile" << 'EOF'
# Forge Auto-login (remove for production)
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startplasma-wayland
fi
EOF

# Limine config
cat > "$BUILD_DIR/airootfs/boot/limine.conf" << 'EOF'
TIMEOUT=0

:Forge
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    CMDLINE=root=UUID=ROOTUUID rw quiet loglevel=0
    INITRD_PATH=boot:///initramfs-linux.img
EOF

echo ""
echo "Setting up archiso..."
echo ""

# Use archiso
cp -r /usr/share/archiso/configs/releng/* "$BUILD_DIR/" 2>/dev/null || true

# Build ISO
echo "Building ISO..."
mkarchiso -v -w "$BUILD_DIR/work" -o "$BUILD_DIR/out" "$BUILD_DIR"

echo ""
echo "========================="
echo "Build complete!"
echo "ISO: $BUILD_DIR/out/$ISO_NAME"
