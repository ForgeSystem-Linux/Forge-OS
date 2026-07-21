#!/bin/bash
# Forge System Build Script
# Creates an Arch Linux ISO with Forge DE

set -e

BUILD_DIR="/tmp/forge-build"
ISO_NAME="forge-$(date +%Y%m%d)-x86_64.iso"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Forge System Builder"
echo "===================="
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check dependencies
for cmd in mkarchiso pacman; do
    if ! command -v $cmd &>/dev/null; then
        echo "Missing: $cmd"
        echo "Install: sudo pacman -S archiso"
        exit 1
    fi
done

echo "Building Forge System ISO..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create base archiso config
mkdir -p "$BUILD_DIR"/{airootfs,efiboot,grub}
cp -r /usr/share/archiso/configs/releng/* "$BUILD_DIR/" 2>/dev/null || {
    echo "Warning: archiso releng config not found, using minimal setup"
}

# Add Forge packages to packages.x86_64
cat >> "$BUILD_DIR/packages.x86_64" << 'EOF'
# Forge System
forge-compositor
forge-shell
forge-greeter
forge-notifications
forge-session
forge-privilege
forge-clip
forge-screenshot
forge-settings

# Required
alacritty
flatpak
xdg-utils
xdg-desktop-portal
mesa
libinput
libseat
libgbm
qt6-base
qt6-declarative
qt6-wayland
polkit
dbus

# Display
sddm
EOF

# Configure systemd services
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/getty.target.wants"
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/multi-user.target.wants"

# Enable Forge services
cat > "$BUILD_DIR/airootfs/etc/systemd/system/forge-greeter.service" << 'EOF'
[Unit]
Description=Forge Display Manager
After=systemd-user-sessions.service
Conflicts=getty@tty1.service

[Service]
Type=simple
ExecStart=/usr/bin/forge-greeter
Restart=always

[Install]
WantedBy=graphical.target
EOF

# Enable greeter
ln -sf /etc/systemd/system/forge-greeter.service "$BUILD_DIR/airootfs/etc/systemd/system/graphical.target.wants/"

# Create user script
mkdir -p "$BUILD_DIR/airootfs/usr/share/forge"
cp "$SCRIPT_DIR/oobe/forge-oobe.sh" "$BUILD_DIR/airootfs/usr/share/forge/"

# Set immutable root
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system"
cat > "$BUILD_DIR/airootfs/etc/systemd/system/forge-immutable.service" << 'EOF'
[Unit]
Description=Forge Immutable Root Setup
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/mount -o ro,remount /
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Configure pacman for Flatpak-only
mkdir -p "$BUILD_DIR/airootfs/etc"
cat > "$BUILD_DIR/airootfs/etc/pacman.conf" << 'EOF'
[options]
RootDir = /
CacheDir = /var/cache/pacman/pkg/
LogFile = /var/log/pacman.log
GPGDir = /etc/pacman.d/gnupg
HookDir = /etc/pacman.d/hooks/
Architecture = auto

SigLevel = Optional TrustAll
Server = https://archlinux.org/repos/$repo/os/$arch

[forge]
SigLevel = Required DatabaseOptional
Server = https://forge-linux.org/repo/$arch
EOF

# Limine bootloader config
mkdir -p "$BUILD_DIR/airootfs/boot"
cat > "$BUILD_DIR/airootfs/boot/limine.conf" << 'EOF'
TIMEOUT=0

:Forge
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    CMDLINE=root=UUID=ROOTUUID rw rootflags=subvol=@ quiet loglevel=0
    INITRD_PATH=boot:///initramfs-linux.img
EOF

# Build ISO
echo "Building ISO with mkarchiso..."
mkarchiso -w "$BUILD_DIR" -o "$BUILD_DIR/out" -D "FORGE" "$BUILD_DIR"

echo ""
echo "Build complete!"
echo "ISO: $BUILD_DIR/out/$ISO_NAME"
echo ""
echo "To test: qemu-system-x86_64 -cdrom $BUILD_DIR/out/$ISO_NAME -m 4G -enable-kvm"
