#!/bin/bash
# Tuxedo Laptop Conditional Lid Handler
# Suspends only when on battery power, stays awake when on AC power

set -euo pipefail

LOG_FILE="/var/log/lid-handler.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check AC power status
is_on_ac_power() {
    # Check multiple possible AC adapter paths
    local ac_paths=(
        "/sys/class/power_supply/AC/online"
        "/sys/class/power_supply/ADP1/online" 
        "/sys/class/power_supply/ACAD/online"
    )
    
    for path in "${ac_paths[@]}"; do
        if [[ -f "$path" ]]; then
            if [[ "$(cat "$path")" == "1" ]]; then
                return 0  # On AC power
            fi
        fi
    done
    
    return 1  # On battery power
}

# Function to get lid state
get_lid_state() {
    local lid_paths=(
        "/proc/acpi/button/lid/LID/state"
        "/proc/acpi/button/lid/LID0/state"
    )
    
    for path in "${lid_paths[@]}"; do
        if [[ -f "$path" ]]; then
            grep -q "closed" "$path" && return 0 || return 1
        fi
    done
    
    # Fallback: assume lid is closed if we can't determine
    return 0
}

main() {
    log_message "Lid event detected"
    
    # Check if lid is actually closed
    if ! get_lid_state; then
        log_message "Lid is open, no action needed"
        exit 0
    fi
    
    log_message "Lid is closed"
    
    # Check power source
    if is_on_ac_power; then
        log_message "On AC power - staying awake"
        # Optionally: turn off display but keep system running
        # xset dpms force off 2>/dev/null || true
    else
        log_message "On battery power - suspending system"
        systemctl suspend
    fi
}

# Ensure log file exists and is writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/lid-handler.log"

main "$@"