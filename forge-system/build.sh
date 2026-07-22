#!/bin/bash
# Forge System ISO Builder (Custom - No mkarchiso)
# Builds a minimal Arch Linux ISO with KDE Plasma + Forge

set -e

BUILD_DIR="$HOME/forge-build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="$(dirname "$SCRIPT_DIR")"
ISO_NAME="forge-$(date +%Y%m%d)-x86_64.iso"
WORK_DIR="$BUILD_DIR/work"
ROOTFS_DIR="$WORK_DIR/rootfs"

echo "Forge System Builder (Custom)"
echo "=============================="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$WORK_DIR" "$ROOTFS_DIR"

echo "[1/8] Bootstrap Arch Linux base..."
echo ""

# Clean pacman cache to free space before build
pacman -Scc --noconfirm 2>/dev/null || true

# Bootstrap base system
pacstrap -K "$ROOTFS_DIR" base linux linux-firmware \
    nano vim networkmanager network-manager-applet \
    bluez bluez-utils pipewire pipewire-pulse wireplumber \
    xdg-utils xdg-desktop-portal polkit dbus flatpak \
    seatd libinput libxkbcommon mesa xorg-xwayland \
    qt6-base qt6-declarative qt6-wayland \
    alacritty git base-devel cmake

echo ""
echo "[2/8] Installing KDE Plasma 6..."
echo ""

arch-chroot "$ROOTFS_DIR" /bin/bash << 'CHROOT'
pacman -S --noconfirm --needed \
    plasma-desktop plasma-workspace \
    systemsettings dolphin konsole kate ark gwenview \
    okular spectacle filelight kcalc \
    sddm sddm-kcm
CHROOT

echo ""
echo "[3/8] Installing Forge tools..."
echo ""

# Copy Forge binaries
mkdir -p "$ROOTFS_DIR/usr/local/bin"
mkdir -p "$ROOTFS_DIR/usr/share/forge"
mkdir -p "$ROOTFS_DIR/usr/share/forge/qml"

for bin in forge-settings forge-notifications forge-privilege forge-session forge-clip forge-screenshot; do
    if [ -f "$FORGE_DIR/target/release/$bin" ]; then
        cp "$FORGE_DIR/target/release/$bin" "$ROOTFS_DIR/usr/local/bin/"
    fi
done

# Copy helper scripts
for script in forge-power.sh forge-apply.sh forge-install-helper.sh; do
    [ -f "$FORGE_DIR/scripts/$script" ] && cp "$FORGE_DIR/scripts/$script" "$ROOTFS_DIR/usr/local/bin/$(basename $script .sh)"
done
cp "$FORGE_DIR/forge-shell/direct/generate-data.sh" "$ROOTFS_DIR/usr/local/bin/forge-gen-data" 2>/dev/null || true

# Generate data
bash "$ROOTFS_DIR/usr/local/bin/forge-gen-data" 2>/dev/null || true
cp "$HOME/.local/share/forge/data.js" "$ROOTFS_DIR/usr/share/forge/" 2>/dev/null || true

# Copy QML
cp "$FORGE_DIR/forge-shell/direct/forge-shell-direct.qml" "$ROOTFS_DIR/usr/share/forge/" 2>/dev/null || true
cp "$FORGE_DIR/forge-shell/qml/"*.qml "$ROOTFS_DIR/usr/share/forge/qml/" 2>/dev/null || true

# Copy DM
cp "$FORGE_DIR/forge-system/forge-dm" "$ROOTFS_DIR/usr/local/bin/" 2>/dev/null || true
cp "$FORGE_DIR/forge-setup/forge-setup" "$ROOTFS_DIR/usr/local/bin/" 2>/dev/null || true

# Fix permissions
chmod 755 "$ROOTFS_DIR/usr/local/bin/"* 2>/dev/null || true

echo ""
echo "[4/8] Installing Forge Plasma theme..."
echo ""

# Plasma theme
THEME_DIR="$ROOTFS_DIR/usr/share/plasma/look-and-feel/Forge.desktop"
mkdir -p "$THEME_DIR/contents/layouts"
cat > "$THEME_DIR/metadata.desktop" << 'EOF'
[Desktop Entry]
Comment=Forge Desktop Environment
Name=Forge
X-KDE-PluginInfo-Author=Forge Team
X-KDE-PluginInfo-Category=Plasma Look And Feel
X-KDE-PluginInfo-Name=Forge
X-KDE-PluginInfo-Version=0.1.0
X-Plasma-API-Migrate-Version=6
X-Plasma-MainScript=contents/layouts/defaults
EOF

# Color scheme
mkdir -p "$ROOTFS_DIR/usr/share/color-schemes"
cp "$FORGE_DIR/forge-theme/colors/Forge.colors" "$ROOTFS_DIR/usr/share/color-solutions/" 2>/dev/null || true

# KWin config
mkdir -p "$ROOTFS_DIR/etc/xdg"
cp "$FORGE_DIR/forge-theme/kwin/kwinrc" "$ROOTFS_DIR/etc/xdg/" 2>/dev/null || true

echo ""
echo "[5/8] Configuring SDDM..."
echo ""

# SDDM config
mkdir -p "$ROOTFS_DIR/etc/sddm.conf.d"
cat > "$ROOTFS_DIR/etc/sddm.conf.d/forge.conf" << 'EOF'
[Theme]
Current=Forge

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
EOF

# Desktop session
cat > "$ROOTFS_DIR/usr/share/wayland-sessions/forge.desktop" << 'EOF'
[Desktop Entry]
Name=Forge
Comment=Forge Desktop Environment
Exec=/usr/bin/startplasma-wayland
Type=Application
DesktopNames=KDE
EOF

# Enable SDDM
arch-chroot "$ROOTFS_DIR" systemctl enable sddm

echo ""
echo "[6/8] Configuring system..."
echo ""

# Timezone
arch-chroot "$ROOTFS_DIR" ln -sf /usr/share/zoneinfo/UTC /etc/localtime
arch-chroot "$ROOTFS_DIR" hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" > "$ROOTFS_DIR/etc/locale.gen"
arch-chroot "$ROOTFS_DIR" locale-gen

# Hostname
echo "forge" > "$ROOTFS_DIR/etc/hostname"

# Network
echo "forge" > "$ROOTFS_DIR/etc/hostname"
cat > "$ROOTFS_DIR/etc/hosts" << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   forge
EOF

# Enable services
arch-chroot "$ROOTFS_DIR" systemctl enable NetworkManager
arch-chroot "$ROOTFS_DIR" systemctl enable bluetooth
arch-chroot "$ROOTFS_DIR" systemctl enable sddm

echo ""
echo "[7/8] Creating initramfs..."
echo ""

arch-chroot "$ROOTFS_DIR" mkinitcpio -P

echo ""
echo "[8/8] Creating ISO..."
echo ""

# Create EFI boot files
mkdir -p "$WORK_DIR/iso/EFI/BOOT"
cp "$ROOTFS_DIR/boot/vmlinuz-linux" "$WORK_DIR/iso/boot/"
cp "$ROOTFS_DIR/boot/initramfs-linux.img" "$WORK_DIR/iso/boot/"

# Create Limine config
mkdir -p "$WORK_DIR/iso/boot/limine"
cat > "$WORK_DIR/iso/boot/limine/limine.conf" << 'EOF'
TIMEOUT=0

:Forge
    PROTOCOL=linux
    KERNEL_PATH=boot:///boot/vmlinuz-linux
    CMDLINE=root=/dev/sda2 rw quiet loglevel=0
    INITRD_PATH=boot:///boot/initramfs-linux.img
EOF

# Copy Limine BIOS/UEFI files
cp /usr/share/limine/limine-bios.sys "$WORK_DIR/iso/boot/limine/" 2>/dev/null || true
cp /usr/share/limine/limine-bios-cd.bin "$WORK_DIR/iso/boot/limine/" 2>/dev/null || true
cp /usr/share/limine/limine-uefi-cd.bin "$WORK_DIR/iso/boot/limine/" 2>/dev/null || true

# Create squashfs
echo "Creating squashfs..."
mksquashfs "$ROOTFS_DIR" "$WORK_DIR/iso/airootfs.sfs" -comp xz -b 1M

# Create ISO with xorriso
echo "Creating ISO..."
xorriso -as mkisofs \
    -o "$BUILD_DIR/out/$ISO_NAME" \
    -b boot/limine/limine-bios-cd.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part-size 256 \
    -isohybrid-gpt-basdat \
    "$WORK_DIR/iso"

echo ""
echo "========================="
echo "Build complete!"
echo "ISO: $BUILD_DIR/out/$ISO_NAME"
echo "Size: $(du -h "$BUILD_DIR/out/$ISO_NAME" | cut -f1)"
