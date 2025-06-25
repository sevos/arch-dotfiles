# ~/.profile - executed by login shells
# This file is sourced by niri-session

# Add user's private bin to PATH
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Wayland environment variables
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# XDG directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Terminal
export TERMINAL=alacritty

# Editor
export EDITOR=nano
export VISUAL=nano
# ydotool socket configuration
export YDOTOOL_SOCKET="/run/user/1000/.ydotool_socket"
