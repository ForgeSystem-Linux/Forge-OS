#!/bin/bash
# Generate app list from .desktop files for Forge Shell
# Output: ~/.local/share/forge/apps.json

DATA_DIR="$HOME/.local/share/forge"
APPS_FILE="$DATA_DIR/apps.json"
DESKTOP_FILE="$DATA_DIR/desktop.json"

mkdir -p "$DATA_DIR"

# Generate apps list
echo "[" > "$APPS_FILE"
FIRST=true
for f in /usr/share/applications/*.desktop; do
    [ -f "$f" ] || continue
    
    # Skip hidden/no-display
    grep -q "^NoDisplay=true" "$f" 2>/dev/null && continue
    grep -q "^Hidden=true" "$f" 2>/dev/null && continue
    
    NAME=$(grep "^Name=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
    ICON=$(grep "^Icon=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
    EXEC=$(grep "^Exec=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
    COMMENT=$(grep "^Comment=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
    CATEGORIES=$(grep "^Categories=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
    
    [ -z "$NAME" ] && continue
    
    # Escape JSON strings
    NAME=$(echo "$NAME" | sed 's/"/\\"/g')
    ICON=$(echo "$ICON" | sed 's/"/\\"/g')
    EXEC=$(echo "$EXEC" | sed 's/"/\\"/g')
    COMMENT=$(echo "$COMMENT" | sed 's/"/\\"/g')
    CATEGORIES=$(echo "$CATEGORIES" | sed 's/"/\\"/g')
    
    # Resolve icon path
    ICON_PATH=""
    if [ -n "$ICON" ]; then
        # Check if icon is an absolute path
        if [[ "$ICON" == /* ]]; then
            if [ -f "$ICON" ]; then
                ICON_PATH="$ICON"
            fi
        else
            # Search icon themes
            for size in 128 96 64 48 32 24 16; do
                for dir in /usr/share/icons/hicolor/${size}x${size}/apps /usr/share/icons/hicolor/scalable/apps /usr/share/pixmaps; do
                    if [ -f "$dir/$ICON.png" ]; then
                        ICON_PATH="$dir/$ICON.png"
                        break 2
                    fi
                    if [ -f "$dir/$ICON.svg" ]; then
                        ICON_PATH="$dir/$ICON.svg"
                        break 2
                    fi
                    if [ -f "$dir/$ICON" ]; then
                        ICON_PATH="$dir/$ICON"
                        break 2
                    fi
                done
            done
        fi
    fi
    
    ICON_PATH=$(echo "$ICON_PATH" | sed 's/"/\\"/g')
    
    [ "$FIRST" = true ] && FIRST=false || echo "," >> "$APPS_FILE"
    echo "  {\"name\":\"$NAME\",\"icon\":\"$ICON\",\"iconPath\":\"$ICON_PATH\",\"exec\":\"$EXEC\",\"comment\":\"$COMMENT\",\"categories\":\"$CATEGORIES\"}" >> "$APPS_FILE"
done
echo "" >> "$APPS_FILE"
echo "]" >> "$APPS_FILE"

# Generate desktop files list
echo "[" > "$DESKTOP_FILE"
FIRST=true
for f in ~/Desktop/*; do
    [ -e "$f" ] || continue
    BASENAME=$(basename "$f")
    IS_DIR=0
    [ -d "$f" ] && IS_DIR=1
    SIZE=$(stat -c%s "$f" 2>/dev/null || echo 0)
    
    [ "$FIRST" = true ] && FIRST=false || echo "," >> "$DESKTOP_FILE"
    echo "  {\"name\":\"$BASENAME\",\"isDir\":$IS_DIR,\"size\":$SIZE}" >> "$DESKTOP_FILE"
done
echo "" >> "$DESKTOP_FILE"
echo "]" >> "$DESKTOP_FILE"

echo "Generated $APPS_FILE and $DESKTOP_FILE"
