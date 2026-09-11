# ~/.zshenv
# Sourced on ALL shells. Use for environment variables.

# --- Wayland Variables ---
export MOZ_ENABLE_WAYLAND=1
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland
# Matches hypr/env.lua's QT_QPA_PLATFORM -- that file deliberately keeps
# the ";xcb" fallback for Qt apps that don't do native Wayland. This is
# sourced by every zsh instance (including ones inside a terminal), so a
# stricter value here was silently overriding Hyprland's for anything
# launched from a shell prompt.
export QT_QPA_PLATFORM="wayland;xcb"

# --- Terminal ---
export TERM=xterm-color

# --- NVM (Node Version Manager) ---
export NVM_DIR="$HOME/.nvm"

# --- Bun ---
export BUN_INSTALL="$HOME/.bun"

# --- Source custom env file ---
# Moved from .zshrc/.bashrc; it belongs here.
if [ -f "$HOME/.local/bin/env" ]; then
  . "$HOME/.local/bin/env"
fi

# --- Podman/docker compat ---
# podman-docker's own DOCKER_HOST setup only runs via /etc/zsh/zprofile,
# which is login-shell-only -- kitty launches zsh non-login, so DOCKER_HOST
# was never set in normal terminals. .zshenv runs for every shell.
if [ -f /etc/profile.d/podman-docker.sh ]; then
  . /etc/profile.d/podman-docker.sh
fi

# --- Zsh-native PATH management ---
# 'typeset -U path' ensures each directory appears only once (Unique).
# 'path' is a Zsh array that is automatically tied to the $PATH variable.
typeset -U path
path=(
    "$BUN_INSTALL/bin"  # Prepended per your .bashrc
    $path               # The existing system path
    "$HOME/.local/bin"  # Appended per your .bashrc
)

# Export PATH for other processes that might not read the 'path' array.
export PATH
