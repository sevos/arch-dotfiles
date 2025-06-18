#!/bin/bash
# Shared logging library for dotfiles sync scripts
# Provides consistent, visually appealing output across all scripts

# Color definitions
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RESET='\033[0m'

# Symbols
readonly SYMBOL_SUCCESS='✓'
readonly SYMBOL_ERROR='✗'
readonly SYMBOL_WARNING='⚠'
readonly SYMBOL_INFO='◦'
readonly SYMBOL_STEP='▶'
readonly SYMBOL_SUBSTEP='  ◦'
readonly SYMBOL_PROGRESS='⏳'
readonly SYMBOL_ARROW='→'

# Global variables for progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0
CURRENT_STEP_NAME=""
START_TIME=$(date +%s)
VERBOSITY_LEVEL="${DOTFILES_VERBOSITY:-normal}"  # quiet, normal, verbose, debug

# Initialize logging system
init_logging() {
    local total_steps="$1"
    TOTAL_STEPS="$total_steps"
    CURRENT_STEP=0
    START_TIME=$(date +%s)
}

# Check if colors should be used (not piped, terminal supports colors)
use_colors() {
    [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]] && [[ "${NO_COLOR:-}" != "1" ]]
}

# Apply color if colors are enabled
colorize() {
    local color="$1"
    local text="$2"
    if use_colors; then
        echo -e "${color}${text}${COLOR_RESET}"
    else
        echo -e "$text"
    fi
}

# Format duration in human readable format
format_duration() {
    local seconds="$1"
    if ((seconds < 60)); then
        echo "${seconds}s"
    elif ((seconds < 3600)); then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $((seconds % 3600 / 60))m $((seconds % 60))s"
    fi
}

# Get elapsed time since start
get_elapsed_time() {
    local current_time=$(date +%s)
    echo $((current_time - START_TIME))
}

# Progress bar display
show_progress() {
    local current="$1"
    local total="$2"
    local width=30
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    if use_colors; then
        local bar="["
        bar+="$(printf "%*s" "$filled" "" | tr ' ' '=')"
        bar+="$(printf "%*s" "$empty" "" | tr ' ' '-')"
        bar+="]"
        echo -e "${COLOR_CYAN}${bar} ${percentage}% (${current}/${total})${COLOR_RESET}"
    else
        echo "Progress: ${current}/${total} (${percentage}%)"
    fi
}

# Section header (major sections like "System Sync", "User Sync")
section() {
    local title="$1"
    local border="$(printf '=%.0s' {1..50})"
    
    echo
    if use_colors; then
        echo -e "${COLOR_BLUE}${COLOR_BOLD}${border}${COLOR_RESET}"
        echo -e "${COLOR_BLUE}${COLOR_BOLD} $title${COLOR_RESET}"
        echo -e "${COLOR_BLUE}${COLOR_BOLD}${border}${COLOR_RESET}"
    else
        echo "$border"
        echo " $title"
        echo "$border"
    fi
    echo
}

# Major step (top-level operations like "System Configuration Sync")
major_step() {
    local message="$1"
    CURRENT_STEP=$((CURRENT_STEP + 1))
    CURRENT_STEP_NAME="$message"
    
    echo
    if use_colors; then
        if [[ $TOTAL_STEPS -gt 0 ]]; then
            echo -e "${COLOR_CYAN}${COLOR_BOLD}${SYMBOL_ARROW} ${message} (${CURRENT_STEP}/${TOTAL_STEPS})${COLOR_RESET}"
        else
            echo -e "${COLOR_CYAN}${COLOR_BOLD}${SYMBOL_ARROW} ${message}${COLOR_RESET}"
        fi
    else
        if [[ $TOTAL_STEPS -gt 0 ]]; then
            echo "→ $message (${CURRENT_STEP}/${TOTAL_STEPS})"
        else
            echo "→ $message"
        fi
    fi
}

# Step (major step within a section)
step() {
    local message="$1"
    CURRENT_STEP=$((CURRENT_STEP + 1))
    CURRENT_STEP_NAME="$message"
    
    echo
    if use_colors; then
        if [[ $TOTAL_STEPS -gt 0 ]]; then
            echo -e "${COLOR_BLUE}${COLOR_BOLD}${SYMBOL_STEP} Step ${CURRENT_STEP}/${TOTAL_STEPS}: ${message}${COLOR_RESET}"
        else
            echo -e "${COLOR_BLUE}${COLOR_BOLD}${SYMBOL_STEP} ${message}${COLOR_RESET}"
        fi
    else
        if [[ $TOTAL_STEPS -gt 0 ]]; then
            echo "Step ${CURRENT_STEP}/${TOTAL_STEPS}: $message"
        else
            echo "▶ $message"
        fi
    fi
}

# Substep (minor step within a major step)
substep() {
    local message="$1"
    [[ "$VERBOSITY_LEVEL" == "quiet" ]] && return
    
    if use_colors; then
        echo -e "${COLOR_CYAN}${SYMBOL_SUBSTEP} ${message}${COLOR_RESET}"
    else
        echo "  ◦ $message"
    fi
}

# Success message
success() {
    local message="$1"
    if use_colors; then
        echo -e "${COLOR_GREEN}${SYMBOL_SUCCESS} ${message}${COLOR_RESET}"
    else
        echo "✓ $message"
    fi
}

# Info message
info() {
    local message="$1"
    [[ "$VERBOSITY_LEVEL" == "quiet" ]] && return
    
    if use_colors; then
        echo -e "  ${COLOR_BLUE}${SYMBOL_INFO} ${message}${COLOR_RESET}"
    else
        echo "  ◦ $message"
    fi
}

# Warning message
warn() {
    local message="$1"
    if use_colors; then
        echo -e "${COLOR_YELLOW}${SYMBOL_WARNING} ${message}${COLOR_RESET}"
    else
        echo "⚠ $message"
    fi
}

# Error message
error() {
    local message="$1"
    if use_colors; then
        echo -e "${COLOR_RED}${SYMBOL_ERROR} ${message}${COLOR_RESET}" >&2
    else
        echo "✗ $message" >&2
    fi
}

# Debug message (only shown in debug mode)
debug() {
    local message="$1"
    [[ "$VERBOSITY_LEVEL" != "debug" ]] && return
    
    if use_colors; then
        echo -e "${COLOR_GRAY}DEBUG: ${message}${COLOR_RESET}" >&2
    else
        echo "DEBUG: $message" >&2
    fi
}

# Processing message (for long-running operations)
processing() {
    local message="$1"
    [[ "$VERBOSITY_LEVEL" == "quiet" ]] && return
    
    if use_colors; then
        echo -e "${COLOR_YELLOW}${SYMBOL_PROGRESS} ${message}...${COLOR_RESET}"
    else
        echo "⏳ $message..."
    fi
}

# Highlight text (for important values, paths, etc.)
highlight() {
    local text="$1"
    if use_colors; then
        echo -e "${COLOR_CYAN}${COLOR_BOLD}${text}${COLOR_RESET}"
    else
        echo "$text"
    fi
}

# Execute command with logging
# Usage: run_cmd "description" command args...
run_cmd() {
    local description="$1"
    shift
    
    debug "Executing: $*"
    
    if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
        substep "$description"
        "$@"
    else
        processing "$description"
        if "$@" >/dev/null 2>&1; then
            success "$description"
        else
            local exit_code=$?
            error "$description failed"
            return $exit_code
        fi
    fi
}

# Execute command with captured output (shows output only on failure)
run_cmd_with_output() {
    local description="$1"
    shift
    
    debug "Executing: $*"
    processing "$description"
    
    local temp_file=$(mktemp)
    if "$@" >"$temp_file" 2>&1; then
        success "$description"
    else
        local exit_code=$?
        error "$description failed"
        if [[ "$VERBOSITY_LEVEL" != "quiet" ]]; then
            echo "--- Command output ---"
            cat "$temp_file"
            echo "--- End output ---"
        fi
        rm -f "$temp_file"
        return $exit_code
    fi
    rm -f "$temp_file"
}

# Summary functions
summary_header() {
    local title="$1"
    section "$title"
}

summary_item() {
    local label="$1"
    local value="$2"
    local status="${3:-}"
    
    if [[ -n "$status" ]]; then
        case "$status" in
            "success"|"ok")
                if use_colors; then
                    echo -e "${COLOR_GREEN}${SYMBOL_SUCCESS}${COLOR_RESET} ${label}: $(highlight "$value")"
                else
                    echo "✓ ${label}: ${value}"
                fi
                ;;
            "warning"|"warn")
                if use_colors; then
                    echo -e "${COLOR_YELLOW}${SYMBOL_WARNING}${COLOR_RESET} ${label}: $(highlight "$value")"
                else
                    echo "⚠ ${label}: ${value}"
                fi
                ;;
            "error"|"fail")
                if use_colors; then
                    echo -e "${COLOR_RED}${SYMBOL_ERROR}${COLOR_RESET} ${label}: $(highlight "$value")"
                else
                    echo "✗ ${label}: ${value}"
                fi
                ;;
            *)
                info "${label}: $(highlight "$value")"
                ;;
        esac
    else
        info "${label}: $(highlight "$value")"
    fi
}

# Package installation summary
package_summary() {
    local total="$1"
    local installed="$2"
    local updated="$3"
    local skipped="$4"
    
    if [[ $installed -gt 0 || $updated -gt 0 ]]; then
        if [[ $installed -gt 0 && $updated -gt 0 ]]; then
            success "Processed $total packages: $(highlight "$installed new"), $(highlight "$updated updated"), $(highlight "$skipped up-to-date")"
        elif [[ $installed -gt 0 ]]; then
            success "Processed $total packages: $(highlight "$installed new"), $(highlight "$skipped up-to-date")"
        else
            success "Processed $total packages: $(highlight "$updated updated"), $(highlight "$skipped up-to-date")"
        fi
    else
        info "All $total packages up-to-date"
    fi
}

# Final summary with timing
final_summary() {
    local operation="$1"
    local elapsed=$(get_elapsed_time)
    local elapsed_str=$(format_duration "$elapsed")
    
    echo
    summary_header "Sync Complete"
    success "$operation completed successfully in $(highlight "$elapsed_str")"
    
    if [[ $TOTAL_STEPS -gt 0 ]]; then
        summary_item "Steps completed" "$CURRENT_STEP/$TOTAL_STEPS" "success"
    fi
    
    summary_item "Total time" "$elapsed_str"
    echo
}

# Error exit function
die() {
    local message="$1"
    local exit_code="${2:-1}"
    error "$message"
    exit "$exit_code"
}

# Check if function is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a library file and should be sourced, not executed directly."
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi