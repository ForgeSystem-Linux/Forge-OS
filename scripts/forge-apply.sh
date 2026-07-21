#!/bin/bash
# Forge Setup - Apply settings
# Called by the setup wizard QML

ACTION="$1"
VALUE="$2"
CONFIG_DIR="$HOME/.config/forge"
CONFIG_FILE="$CONFIG_DIR/config.toml"

mkdir -p "$CONFIG_DIR"

case "$ACTION" in
    save-language)
        sed -i "s/^language = .*/language = \"$VALUE\"/" "$CONFIG_FILE" 2>/dev/null || echo "language = \"$VALUE\"" >> "$CONFIG_FILE"
        echo "Language set to: $VALUE"
        ;;
    save-accent)
        sed -i "s/^accent_color = .*/accent_color = \"$VALUE\"/" "$CONFIG_FILE" 2>/dev/null || echo "accent_color = \"$VALUE\"" >> "$CONFIG_FILE"
        echo "Accent color set to: $VALUE"
        ;;
    save-wallpaper)
        sed -i "s/^wallpaper = .*/wallpaper = \"$VALUE\"/" "$CONFIG_FILE" 2>/dev/null || echo "wallpaper = \"$VALUE\"" >> "$CONFIG_FILE"
        echo "Wallpaper set to: $VALUE"
        ;;
    save-keyboard)
        # Actually set keyboard layout
        if command -v setxkbmap &>/dev/null; then
            setxkbmap "$VALUE" 2>/dev/null && echo "Keyboard layout set to: $VALUE"
        elif command -v localectl &>/dev/null; then
            localectl set-keymap "$VALUE" 2>/dev/null && echo "Keyboard layout set to: $VALUE"
        fi
        sed -i "s/^keyboard_layout = .*/keyboard_layout = \"$VALUE\"/" "$CONFIG_FILE" 2>/dev/null || echo "keyboard_layout = \"$VALUE\"" >> "$CONFIG_FILE"
        ;;
    create-user)
        USERNAME="$3"
        PASSWORD="$4"
        FULLNAME="$5"
        if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
            # Use pkexec if available, otherwise direct
            if command -v pkexec &>/dev/null; then
                pkexec useradd -m -G wheel -s /bin/bash "$USERNAME" 2>/dev/null
                echo "$USERNAME:$PASSWORD" | chpasswd 2>/dev/null
            else
                sudo useradd -m -G wheel -s /bin/bash "$USERNAME" 2>/dev/null
                echo "$USERNAME:$PASSWORD" | sudo chpasswd 2>/dev/null
            fi
            echo "User '$USERNAME' created"
        fi
        ;;
    set-hostname)
        HOSTNAME_VAL="$3"
        if [ -n "$HOSTNAME_VAL" ]; then
            if command -v hostnamectl &>/dev/null; then
                sudo hostnamectl set-hostname "$HOSTNAME_VAL" 2>/dev/null
            fi
            echo "Hostname set to: $HOSTNAME_VAL"
        fi
        ;;
    finish)
        # Create desktop directory if missing
        mkdir -p "$HOME/Desktop"
        
        # Set first-run flag
        sed -i "s/^first_run = .*/first_run = false/" "$CONFIG_FILE" 2>/dev/null || echo "first_run = false" >> "$CONFIG_FILE"
        
        # Ensure config has all required fields
        for key in language accent_color wallpaper keyboard_layout theme; do
            grep -q "^$key = " "$CONFIG_FILE" 2>/dev/null || echo "$key = \"\"" >> "$CONFIG_FILE"
        done
        
        echo "Setup complete!"
        echo "Config saved to: $CONFIG_FILE"
        cat "$CONFIG_FILE"
        ;;
    *)
        echo "Usage: forge-apply.sh <action> [value] [extra...]"
        echo "Actions: save-language, save-accent, save-wallpaper, save-keyboard, create-user, finish"
        ;;
esac
