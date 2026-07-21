#!/bin/bash
# Forge System OOBE - First Boot Experience
# Runs after installation, creates user and configures system

set -e

OOBE_DIR="/usr/share/forge/oobe"
LOG="/var/log/forge-oobe.log"

log() {
    echo "[$(date)] $1" | tee -a "$LOG"
}

log "Starting Forge OOBE"

# Check if OOBE already completed
if [ -f /var/lib/forge/.oobe-done ]; then
    log "OOBE already completed, skipping"
    exit 0
fi

log "Displaying OOBE..."

# Launch OOBE in the greeter
# The greeter will show the setup wizard with FORGE_INCLUDE_ACCOUNT_SETUP=1
export FORGE_INCLUDE_ACCOUNT_SETUP=1
export FORGE_OOBE=1

# Start the forge greeter with OOBE mode
# The greeter QML will detect FORGE_OOBE and show the wizard
if [ -x /usr/bin/forge-greeter ]; then
    /usr/bin/forge-greeter --oobe
fi

# Mark OOBE as done
mkdir -p /var/lib/forge
touch /var/lib/forge/.oobe-done
chmod 644 /var/lib/forge/.oobe-done

log "OOBE completed"
