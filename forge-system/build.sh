#!/bin/bash
# Forge System ISO Builder
# Builds an Arch Linux ISO with Forge DE

set -e

BUILD_DIR="$HOME/forge-build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="$(dirname "$SCRIPT_DIR")"
ISO_NAME="forge-$(date +%Y%m%d)-x86_64.iso"

echo "Forge System Builder"
echo "===================="
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

# Base packages (no Forge packages in repos yet)
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
xdg-desktop-portal-wlr
polkit
dbus
flatpak
alacritty
git
base-devel
cmake

# Qt
qt6-base
qt6-declarative
qt6-wayland

# Display
libinput
libseat
libgbm
mesa
xorg-xwayland
sddm
sddm-kcm

# Boot
limine
limine-install
EOF

# Copy Forge binaries into the ISO
echo "Bundling Forge binaries..."
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

# Build Forge if binaries don't exist
if [ ! -f "$FORGE_DIR/target/release/forge-compositor" ]; then
    echo "Building Forge from source..."
    cd "$FORGE_DIR"
    cargo build --release
    cd "$SCRIPT_DIR"
fi

# Copy binaries
echo "Copying binaries..."
for bin in forge-compositor forge-shell forge-settings forge-notifications forge-privilege forge-session forge-greeter forge-clip forge-screenshot; do
    if [ -f "$FORGE_DIR/target/release/$bin" ]; then
        cp "$FORGE_DIR/target/release/$bin" "$BUILD_DIR/airootfs/usr/local/bin/"
    fi
done

# Copy direct run scripts
cp "$FORGE_DIR/forge-shell/direct/forge-shell-direct" "$BUILD_DIR/airootfs/usr/local/bin/" 2>/dev/null || true
chmod +x "$BUILD_DIR/airootfs/usr/local/bin/"*

# Copy QML files
cp "$FORGE_DIR/forge-shell/direct/forge-shell-direct.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true
cp "$FORGE_DIR/forge-shell/qml/"*.qml "$BUILD_DIR/airootfs/usr/share/forge/qml/" 2>/dev/null || true
cp "$FORGE_DIR/forge-system/forge-dm.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true
cp "$FORGE_DIR/forge-setup/forge-setup.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true
cp "$FORGE_DIR/forge-installer/forge-installer.qml" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true

# Copy helper scripts
cp "$FORGE_DIR/scripts/forge-power.sh" "$BUILD_DIR/airootfs/usr/local/bin/forge-power" 2>/dev/null || true
cp "$FORGE_DIR/scripts/forge-apply.sh" "$BUILD_DIR/airootfs/usr/local/bin/forge-apply" 2>/dev/null || true
cp "$FORGE_DIR/scripts/forge-install-helper.sh" "$BUILD_DIR/airootfs/usr/local/bin/forge-install-helper" 2>/dev/null || true
cp "$FORGE_DIR/forge-shell/direct/generate-data.sh" "$BUILD_DIR/airootfs/usr/local/bin/forge-gen-data" 2>/dev/null || true
chmod +x "$BUILD_DIR/airootfs/usr/local/bin/"*

# Generate default data.js
bash "$BUILD_DIR/airootfs/usr/local/bin/forge-gen-data" 2>/dev/null || true
cp "$HOME/.local/share/forge/data.js" "$BUILD_DIR/airootfs/usr/share/forge/" 2>/dev/null || true

# Copy DM launcher
cp "$FORGE_DIR/forge-system/forge-dm" "$BUILD_DIR/airootfs/usr/local/bin/forge-dm" 2>/dev/null || true
cp "$FORGE_DIR/forge-setup/forge-setup" "$BUILD_DIR/airootfs/usr/local/bin/forge-setup" 2>/dev/null || true
cp "$FORGE_DIR/forge-installer/forge-installer" "$BUILD_DIR/airootfs/usr/local/bin/forge-installer" 2>/dev/null || true
chmod +x "$BUILD_DIR/airootfs/usr/local/bin/"*

# Copy icon
cp "$FORGE_DIR/packaging/forge-logo.svg" "$BUILD_DIR/airootfs/usr/share/icons/hicolor/scalable/apps/" 2>/dev/null || true

# Systemd services
# SDDM is the default display manager (forge-greeter is optional/experimental)
# forge-greeter.service is NOT auto-enabled to avoid conflicts

cat > "$BUILD_DIR/airootfs/etc/systemd/system/forge-notifications.service" << 'EOF'
[Unit]
Description=Forge Notification Daemon
After=forge-greeter.service

[Service]
Type=simple
ExecStart=/usr/local/bin/forge-notifications
Restart=always

[Install]
WantedBy=graphical.target
EOF

# Enable SDDM as default display manager
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.target.wants"
ln -sf /usr/lib/systemd/system/sddm.service "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.target.wants/sddm.service" 2>/dev/null || true

# Desktop session
cat > "$BUILD_DIR/airootfs/usr/share/wayland-sessions/forge.desktop" << 'EOF'
[Desktop Entry]
Name=Forge
Comment=Forge Desktop Environment
Exec=/usr/local/bin/forge-compositor --backend winit
Type=Application
DesktopNames=Forge
EOF

# PAM config
cat > "$BUILD_DIR/airootfs/etc/pam.d/forge-greeter" << 'EOF'
#%PAM-1.0
auth       required     pam_unix.so
account    required     pam_unix.so
session    required     pam_unix.so
EOF

# OOBE first-boot script
mkdir -p "$BUILD_DIR/airootfs/usr/share/forge"
cat > "$BUILD_DIR/airootfs/usr/share/forge/forge-oobe.sh" << 'OOBESCRIPT'
#!/bin/bash
if [ ! -f /var/lib/forge/.oobe-done ]; then
    mkdir -p /var/lib/forge
    touch /var/lib/forge/.oobe-done
    /usr/local/bin/forge-setup
fi
OOBESCRIPT
chmod +x "$BUILD_DIR/airootfs/usr/share/forge/forge-oobe.sh"

# Auto-login on tty1 for live ISO
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/getty@tty1.service.d"
cat > "$BUILD_DIR/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root -o '-p -f \\u' --noclear %I $TERM
EOF

# Root shell profile
mkdir -p "$BUILD_DIR/airootfs/root"
cat > "$BUILD_DIR/airootfs/root/.bash_profile" << 'EOF'
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx /usr/bin/forge-compositor --backend winit
fi
EOF

# Limine bootloader config
mkdir -p "$BUILD_DIR/airootfs/boot"
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

# Use archiso to build
# Copy the profile
cp -r /usr/share/archiso/configs/releng/* "$BUILD_DIR/" 2>/dev/null || true

# Packages are already in BUILD_DIR from earlier
echo "Using custom packages list"

# Build ISO
echo "Building ISO..."
mkarchiso -v -w "$BUILD_DIR/work" -o "$BUILD_DIR/out" "$BUILD_DIR"

echo ""
echo "========================="
echo "Build complete!"
echo "ISO: $BUILD_DIR/out/$ISO_NAME"
echo ""
echo "Test with: qemu-system-x86_64 -cdrom $BUILD_DIR/out/$ISO_NAME -m 4G -enable-kvm"
