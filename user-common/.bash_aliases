# Essential command aliases
alias cat='bat'
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A' 
alias l='ls -CF'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcauto='git commit -m "$(claude -p --dangerously-skip-permissions "analyze the currently staged git changes and generate only a commit message following this repo'\''s conventional commit style. Output only the commit message, nothing else.")"'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
alias lg='lazygit'

# System shortcuts
alias h='history'
alias j='jobs -l'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Directory shortcuts with zoxide
alias z='zoxide'
alias zi='cdi'  # Interactive directory search

# Alert for long running commands
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Quick edit configs
alias bashrc='$EDITOR ~/.bashrc'
alias aliases='$EDITOR ~/.bash_aliases'