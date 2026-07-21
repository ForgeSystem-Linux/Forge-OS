#!/bin/bash
# Forge Power Actions Helper
# Called by the shell QML for power operations

ACTION="$1"

case "$ACTION" in
    lock)
        # Lock screen
        if command -v loginctl &>/dev/null; then
            loginctl lock-session
        elif [ -x /usr/bin/swaylock ]; then
            swaylock
        elif [ -x /usr/bin/i3lock ]; then
            i3lock -c 1e1e2e
        else
            echo "No lock screen found. Install swaylock or i3lock."
        fi
        ;;
    logoff)
        # Log out of the current session
        if [ -n "$WAYLAND_DISPLAY" ]; then
            # Try to find and kill the compositor
            if command -v loginctl &>/dev/null; then
                loginctl terminate-user "$USER"
            else
                # Fallback: kill parent processes
                pkill -u "$USER" -f "forge-compositor"
            fi
        fi
        ;;
    restart)
        # Restart the system
        if command -v systemctl &>/dev/null; then
            sudo systemctl reboot
        elif command -v loginctl &>/dev/null; then
            sudo loginctl reboot
        else
            sudo reboot
        fi
        ;;
    poweroff)
        # Shut down the system
        if command -v systemctl &>/dev/null; then
            sudo systemctl poweroff
        elif command -v loginctl &>/dev/null; then
            sudo loginctl poweroff
        else
            sudo shutdown -h now
        fi
        ;;
    suspend)
        # Suspend the system
        if command -v systemctl &>/dev/null; then
            sudo systemctl suspend
        else
            echo "Suspend not available"
        fi
        ;;
    hibernate)
        # Hibernate the system
        if command -v systemctl &>/dev/null; then
            sudo systemctl hibernate
        else
            echo "Hibernate not available"
        fi
        ;;
    *)
        echo "Usage: forge-power <action>"
        echo "Actions: lock, logoff, restart, poweroff, suspend, hibernate"
        exit 1
        ;;
esac
