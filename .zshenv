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
# export TERM=xterm-color  # removed: forced 8 colors and crashed ranger previews; kitty sets TERM=xterm-kitty itself

# --- NVM (Node Version Manager) ---
export NVM_DIR="$HOME/.nvm"

# --- Bun ---
export BUN_INSTALL="$HOME/.bun"

# --- Source custom env file ---
# Moved from .zshrc/.bashrc; it belongs here.
if [ -f "$HOME/.local/bin/env" ]; then
  . "$HOME/.local/bin/env"
fi

# --- Podman as the Docker engine ---
# The docker CLI and `docker compose` talk to rootless podman's
# Docker-compatible API socket (the podman.socket user unit) instead of a
# Docker daemon. Set here directly rather than via podman-docker's
# /etc/profile.d/podman-docker.sh: that file disappears whenever the real
# docker package replaces podman-docker, and it only ran for login shells
# anyway. GUI apps get the same value from
# ~/.config/environment.d/10-podman-docker.conf. Respects a DOCKER_HOST
# that's already set.
if [ -z "${DOCKER_HOST:-}" ] && [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi
# podman has no built-in BuildKit, so buildx builds in a BuildKit
# container; the "podman" builder (`docker buildx create --name podman
# --driver docker-container --driver-opt default-load=true`) loads every
# result back into podman. Picked by env var because buildx ignores its
# stored default builder whenever DOCKER_HOST is set.
export BUILDX_BUILDER="${BUILDX_BUILDER:-podman}"

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
