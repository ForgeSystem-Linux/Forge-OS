#!/bin/bash
# Forge System Installer Helper
# Called by the installer QML to perform actual system operations

ACTION="$1"
shift

case "$ACTION" in
    install-base)
        echo "[1/12] Creating directories..."
        mkdir -p /usr/local/bin 2>/dev/null || true
        mkdir -p /usr/share/forge 2>/dev/null || true
        mkdir -p /etc/systemd/system 2>/dev/null || true
        mkdir -p /etc/pam.d 2>/dev/null || true
        mkdir -p /etc/dbus-1/system.d 2>/dev/null || true
        mkdir -p /usr/share/polkit-1/actions 2>/dev/null || true
        mkdir -p /usr/share/wayland-sessions 2>/dev/null || true
        mkdir -p /usr/share/icons/hicolor/scalable/apps 2>/dev/null || true
        sleep 0.3
        ;;
    install-compositor)
        echo "[2/12] Installing compositor..."
        # Copy binaries
        for bin in forge-compositor forge-shell forge-settings forge-notifications forge-privilege forge-session forge-greeter forge-clip forge-screenshot forge-shell-direct forge-dm; do
            if [ -f "$HOME/.local/bin/$bin" ]; then
                cp "$HOME/.local/bin/$bin" /usr/local/bin/ 2>/dev/null || sudo cp "$HOME/.local/bin/$bin" /usr/local/bin/
            fi
        done
        sleep 0.3
        ;;
    install-shell)
        echo "[3/12] Installing shell components..."
        cp -r "$HOME/.local/share/forge/"* /usr/share/forge/ 2>/dev/null || sudo cp -r "$HOME/.local/share/forge/"* /usr/share/forge/
        sleep 0.3
        ;;
    install-services)
        echo "[4/12] Installing systemd services..."
        for svc in forge-compositor forge-notifications forge-privilege forge-session forge-greeter; do
            if [ -f "/home/admin/forge/systemd/$svc.service" ]; then
                cp "/home/admin/forge/systemd/$svc.service" /etc/systemd/system/ 2>/dev/null || sudo cp "/home/admin/forge/systemd/$svc.service" /etc/systemd/system/
            fi
        done
        sleep 0.3
        ;;
    install-dbus)
        echo "[5/12] Installing D-Bus configuration..."
        if [ -f "/home/admin/forge/forge-privilege/org.forge.Privilege.conf" ]; then
            cp "/home/admin/forge/forge-privilege/org.forge.Privilege.conf" /etc/dbus-1/system.d/ 2>/dev/null || sudo cp "/home/admin/forge/forge-privilege/org.forge.Privilege.conf" /etc/dbus-1/system.d/
        fi
        sleep 0.3
        ;;
    install-polkit)
        echo "[6/12] Installing PolicyKit policies..."
        if [ -f "/home/admin/forge/forge-privilege/org.forge.Privilege.policy" ]; then
            cp "/home/admin/forge/forge-privilege/org.forge.Privilege.policy" /usr/share/polkit-1/actions/ 2>/dev/null || sudo cp "/home/admin/forge/forge-privilege/org.forge.Privilege.policy" /usr/share/polkit-1/actions/
        fi
        sleep 0.3
        ;;
    install-pam)
        echo "[7/12] Installing PAM configuration..."
        for pam in forge-greeter forge-session; do
            if [ -f "/home/admin/forge/pam/$pam" ]; then
                cp "/home/admin/forge/pam/$pam" /etc/pam.d/ 2>/dev/null || sudo cp "/home/admin/forge/pam/$pam" /etc/pam.d/
            fi
        done
        sleep 0.3
        ;;
    install-session)
        echo "[8/12] Installing desktop session..."
        if [ -f "/home/admin/forge/xdg-autostart/forge.desktop" ]; then
            cp "/home/admin/forge/xdg-autostart/forge.desktop" /usr/share/wayland-sessions/ 2>/dev/null || sudo cp "/home/admin/forge/xdg-autostart/forge.desktop" /usr/share/wayland-sessions/
        fi
        sleep 0.3
        ;;
    install-icons)
        echo "[9/12] Installing icons..."
        if [ -f "/home/admin/forge/packaging/forge-logo.svg" ]; then
            cp "/home/admin/forge/packaging/forge-logo.svg" /usr/share/icons/hicolor/scalable/apps/ 2>/dev/null || sudo cp "/home/admin/forge/packaging/forge-logo.svg" /usr/share/icons/hicolor/scalable/apps/
        fi
        sleep 0.3
        ;;
    enable-services)
        echo "[10/12] Enabling services..."
        systemctl enable forge-greeter 2>/dev/null || true
        systemctl enable forge-notifications 2>/dev/null || true
        systemctl enable forge-privilege 2>/dev/null || true
        systemctl enable forge-session 2>/dev/null || true
        sleep 0.3
        ;;
    set-permissions)
        echo "[11/12] Setting permissions..."
        chmod 755 /usr/local/bin/forge-* 2>/dev/null || true
        chmod 644 /etc/systemd/system/forge-*.service 2>/dev/null || true
        chmod 644 /etc/pam.d/forge-* 2>/dev/null || true
        chmod 644 /etc/dbus-1/system.d/org.forge.Privilege.conf 2>/dev/null || true
        chmod 644 /usr/share/polkit-1/actions/org.forge.Privilege.policy 2>/dev/null || true
        sleep 0.3
        ;;
    set-hostname)
        HOSTNAME_VAL="$1"
        echo "[12/12] Setting hostname to $HOSTNAME_VAL..."
        if [ -n "$HOSTNAME_VAL" ]; then
            hostnamectl set-hostname "$HOSTNAME_VAL" 2>/dev/null || echo "$HOSTNAME_VAL" | sudo tee /etc/hostname > /dev/null
        fi
        sleep 0.3
        ;;
    finish)
        echo ""
        echo "Installation complete!"
        echo ""
        echo "Installed components:"
        echo "  - forge-compositor (Wayland compositor)"
        echo "  - forge-shell (Desktop shell)"
        echo "  - forge-greeter (Display manager)"
        echo "  - forge-notifications (Notification daemon)"
        echo "  - forge-session (Session manager)"
        echo "  - forge-privilege (pkexec helper)"
        echo "  - forge-clip (Clipboard manager)"
        echo "  - forge-screenshot (Screenshot tool)"
        echo "  - forge-settings (Settings app)"
        echo ""
        echo "To start: Reboot or run 'systemctl start forge-greeter'"
        ;;
    check-deps)
        echo "Checking dependencies..."
        MISSING=""
        for pkg in wayland libinput libseat libgbm mesa qt6-base qt6-declarative qt6-wayland polkit pam; do
            if ! pacman -Qi "$pkg" &>/dev/null 2>&1; then
                MISSING="$MISSING $pkg"
            fi
        done
        if [ -n "$MISSING" ]; then
            echo "MISSING:$MISSING"
        else
            echo "OK"
        fi
        ;;
    *)
        echo "Usage: forge-install-helper <action>"
        echo "Actions: install-base, install-compositor, install-shell, etc."
        ;;
esac
