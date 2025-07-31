# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# 1Password SSH Agent
export SSH_AUTH_SOCK=~/.1password/agent.sock

# Default editors
export EDITOR=nvim
export VISUAL="code --wait"

# History configuration
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size and update LINES and COLUMNS
shopt -s checkwinsize

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Enhanced prompt with color
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt

# Terminal title
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
esac

# Load aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Tool integrations
eval "$(mise activate bash)"
eval "$(starship init bash)"
eval "$(zoxide init bash)"

# Enhanced cd function with zoxide integration
cd() {
    if [ $# -eq 0 ]; then
        builtin cd ~ && zoxide add "$(pwd)"
    elif [ $# -eq 1 ] && [ "$1" = "-" ]; then
        builtin cd - && zoxide add "$(pwd)"
    else
        __zoxide_z "$@" 2>/dev/null || builtin cd "$@" && zoxide add "$(pwd)" 2>/dev/null
    fi
}

# fzf integrations (if available)
if command -v fzf >/dev/null 2>&1; then
    # Interactive directory search
    cdi() {
        local dir
        dir=$(zoxide query -l | fzf --preview 'ls -la {}' --height 40% --reverse) && cd "$dir"
    }
    
    # Bind Ctrl+T for file search
    bind -x '"\C-t": fzf-file-widget'
    
    # Bind Alt+C for directory search
    bind -x '"\ec": fzf-cd-widget'
fi
# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/sevos/.lmstudio/bin"
# End of LM Studio CLI section

