#!/bin/bash
# Tuxedo Power Management Diagnostic Script
# Comprehensive validation of power management configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Status counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Tuxedo Power Management Diagnostics${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
}

print_section() {
    echo -e "${YELLOW}--- $1 ---${NC}"
}

check_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

check_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Configuration file checks
check_config_files() {
    print_section "Configuration Files"
    
    # Check logind config
    local logind_config="/etc/systemd/logind.conf.d/tuxedo-power.conf"
    if [[ -f "$logind_config" ]]; then
        check_pass "Logind config file exists: $logind_config"
        if [[ -r "$logind_config" ]]; then
            check_pass "Logind config file is readable"
            check_info "Config contents:"
            grep -v '^#' "$logind_config" | grep -v '^$' | sed 's/^/    /'
        else
            check_fail "Logind config file is not readable"
        fi
    else
        check_fail "Logind config file missing: $logind_config"
    fi
    
    # Check sleep config
    local sleep_config="/etc/systemd/sleep.conf.d/deep-sleep.conf"
    if [[ -f "$sleep_config" ]]; then
        check_pass "Sleep config file exists: $sleep_config"
        if [[ -r "$sleep_config" ]]; then
            check_pass "Sleep config file is readable"
            check_info "Sleep config:"
            grep -v '^#' "$sleep_config" | grep -v '^$' | sed 's/^/    /'
        else
            check_fail "Sleep config file is not readable"
        fi
    else
        check_fail "Sleep config file missing: $sleep_config"
    fi
    
    echo
}

# SystemD service status checks
check_systemd_status() {
    print_section "SystemD Services"
    
    # Check systemd-logind status
    if systemctl is-active --quiet systemd-logind; then
        check_pass "systemd-logind service is active"
    else
        check_fail "systemd-logind service is not active"
    fi
    
    # Check if systemd-logind is enabled
    if systemctl is-enabled --quiet systemd-logind; then
        check_pass "systemd-logind service is enabled"
    else
        check_warn "systemd-logind service is not enabled"
    fi
    
    # Check for inhibitors
    local inhibitors=$(systemd-inhibit --list --no-legend 2>/dev/null | wc -l)
    if [[ $inhibitors -eq 0 ]]; then
        check_pass "No power management inhibitors active"
    else
        check_warn "$inhibitors power management inhibitor(s) active:"
        systemd-inhibit --list 2>/dev/null | sed 's/^/    /' || true
    fi
    
    echo
}

# Current power management settings
check_power_settings() {
    print_section "Power Management Settings"
    
    # Get current user session
    local session_id="${XDG_SESSION_ID:-}"
    if [[ -z "$session_id" ]]; then
        session_id=$(loginctl show-user "${USER:-root}" --property=Sessions --value | cut -d' ' -f1)
    fi
    
    if [[ -n "$session_id" ]]; then
        check_pass "Found active session: $session_id"
        
        # Check session type
        local session_type=$(loginctl show-session "$session_id" --property=Type --value 2>/dev/null || echo "unknown")
        check_info "Session type: $session_type"
        
        # Check if session is active
        local session_active=$(loginctl show-session "$session_id" --property=Active --value 2>/dev/null || echo "no")
        if [[ "$session_active" == "yes" ]]; then
            check_pass "Session is active"
        else
            check_warn "Session is not active"
        fi
    else
        check_warn "No active session found"
    fi
    
    # Show current power key handling
    local power_key=$(loginctl show-user "${USER:-root}" --property=HandlePowerKey --value 2>/dev/null || echo "unknown")
    check_info "Power key handling: $power_key"
    
    # Show current lid switch handling
    local lid_switch=$(loginctl show-user "${USER:-root}" --property=HandleLidSwitch --value 2>/dev/null || echo "unknown")
    check_info "Lid switch handling: $lid_switch"
    
    echo
}

# ACPI hardware detection
check_acpi_hardware() {
    print_section "ACPI Hardware Detection"
    
    # Check for lid switch
    local lid_paths=(
        "/proc/acpi/button/lid/LID/state"
        "/proc/acpi/button/lid/LID0/state"
        "/proc/acpi/button/lid/LIDD/state"
    )
    
    local lid_found=false
    for path in "${lid_paths[@]}"; do
        if [[ -f "$path" ]]; then
            check_pass "Lid switch found: $path"
            local lid_state=$(cat "$path" 2>/dev/null | awk '{print $2}' || echo "unknown")
            check_info "Current lid state: $lid_state"
            lid_found=true
            break
        fi
    done
    
    if [[ "$lid_found" == "false" ]]; then
        check_fail "No lid switch found in /proc/acpi/button/lid/"
        # Check alternative locations
        if ls /sys/class/input/*/name 2>/dev/null | xargs grep -l "Lid Switch" >/dev/null 2>&1; then
            check_info "Alternative lid switch detection available in /sys/class/input/"
        fi
    fi
    
    # Check for power button
    if [[ -d "/proc/acpi/button/power" ]]; then
        check_pass "Power button ACPI interface found"
    else
        check_warn "Power button ACPI interface not found in /proc/acpi/button/power"
    fi
    
    # Check power supply
    local ac_paths=(
        "/sys/class/power_supply/AC/online"
        "/sys/class/power_supply/ADP1/online"
        "/sys/class/power_supply/ACAD/online"
    )
    
    local ac_found=false
    for path in "${ac_paths[@]}"; do
        if [[ -f "$path" ]]; then
            check_pass "AC adapter found: $path"
            local ac_state=$(cat "$path" 2>/dev/null || echo "unknown")
            if [[ "$ac_state" == "1" ]]; then
                check_info "Currently on AC power"
            else
                check_info "Currently on battery power"
            fi
            ac_found=true
            break
        fi
    done
    
    if [[ "$ac_found" == "false" ]]; then
        check_fail "No AC adapter found in /sys/class/power_supply/"
    fi
    
    echo
}

# Sleep capabilities
check_sleep_capabilities() {
    print_section "Sleep Capabilities"
    
    # Check available sleep states
    if [[ -f "/sys/power/mem_sleep" ]]; then
        check_pass "Sleep states file found"
        local sleep_states=$(cat /sys/power/mem_sleep 2>/dev/null || echo "unknown")
        check_info "Available sleep states: $sleep_states"
        
        # Check if deep sleep is available and active
        if echo "$sleep_states" | grep -q '\[deep\]'; then
            check_pass "Deep sleep (S3) is currently active"
        elif echo "$sleep_states" | grep -q 'deep'; then
            check_warn "Deep sleep (S3) is available but not active"
        else
            check_warn "Deep sleep (S3) not available"
        fi
    else
        check_fail "Sleep states file not found: /sys/power/mem_sleep"
    fi
    
    # Check suspend capability
    if [[ -f "/sys/power/state" ]]; then
        check_pass "Power state file found"
        local power_states=$(cat /sys/power/state 2>/dev/null || echo "unknown")
        check_info "Available power states: $power_states"
    else
        check_fail "Power state file not found: /sys/power/state"
    fi
    
    echo
}

# Journal analysis
check_journal_logs() {
    print_section "Recent Journal Logs"
    
    # Check for recent logind messages
    local logind_logs=$(journalctl -u systemd-logind --since "1 hour ago" --no-pager -q 2>/dev/null | wc -l)
    if [[ $logind_logs -gt 0 ]]; then
        check_info "Found $logind_logs systemd-logind log entries in last hour"
        check_info "Recent logind messages:"
        journalctl -u systemd-logind --since "1 hour ago" --no-pager -q 2>/dev/null | tail -5 | sed 's/^/    /' || true
    else
        check_warn "No recent systemd-logind log entries found"
    fi
    
    # Check for ACPI events
    local acpi_logs=$(journalctl --grep="ACPI" --since "1 hour ago" --no-pager -q 2>/dev/null | wc -l)
    if [[ $acpi_logs -gt 0 ]]; then
        check_info "Found $acpi_logs ACPI-related log entries in last hour"
    else
        check_info "No recent ACPI-related log entries found"
    fi
    
    echo
}

# Summary
print_summary() {
    print_section "Diagnostic Summary"
    
    echo "Results:"
    echo -e "  ${GREEN}Passed: $PASSED${NC}"
    echo -e "  ${RED}Failed: $FAILED${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
    echo
    
    if [[ $FAILED -eq 0 ]]; then
        if [[ $WARNINGS -eq 0 ]]; then
            echo -e "${GREEN}✓ All checks passed! Power management should be working correctly.${NC}"
        else
            echo -e "${YELLOW}⚠ Configuration looks mostly good, but there are some warnings to review.${NC}"
        fi
    else
        echo -e "${RED}✗ Some critical issues found. Power management may not work as expected.${NC}"
        echo -e "${YELLOW}Suggested actions:${NC}"
        echo "  1. Check file permissions and ownership"
        echo "  2. Restart systemd-logind: systemctl restart systemd-logind"
        echo "  3. Reload systemd configuration: systemctl daemon-reload"
        echo "  4. Check for conflicting power management software"
    fi
    
    echo
    echo -e "${BLUE}To test power management:${NC}"
    echo "  1. Check current behavior with: loginctl show-user \$USER"
    echo "  2. Monitor events with: journalctl -u systemd-logind -f"
    echo "  3. Test lid close/open (should suspend on battery, stay awake on AC)"
    echo "  4. Test power button (should suspend)"
}

# Main execution
main() {
    print_header
    check_config_files
    check_systemd_status
    check_power_settings
    check_acpi_hardware
    check_sleep_capabilities
    check_journal_logs
    print_summary
}

# Run diagnostics
main "$@"