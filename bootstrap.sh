#!/bin/bash

# Update system and install necessary packages for AUR building
sudo pacman -Syu --needed git base-devel flatpak

# Install yay if it's not already installed
if ! command -v yay &> /dev/null
then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay # Clean up
fi

# Add Flathub repository for Flatpak (if not already added)
if ! flatpak remotes | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install GNU Stow if not already installed
sudo pacman -S --needed stow

# Install packages from the lists within the dotfiles repo
sudo pacman -S --needed $(cat pkglist.txt)
yay -S --needed $(cat foreignpkglist.txt)

# Install specific Flatpak apps
flatpak install flathub com.usebottles.bottles -y
flatpak install flathub com.github.tchx84.Flatseal -y
flatpak install flathub com.protonvpn.www -y
flatpak install flathub me.proton.Pass -y
# Steam itself is NOT installed via any package manager on this machine --
# it's the self-updating client under ~/.local/share/Steam, installed by
# running Valve's own install script/binary by hand. Nothing to bootstrap
# here; install Steam manually, then use it (or protonup-qt) to fetch
# Proton-GE, which shows up as the
# com.valvesoftware.Steam.CompatibilityTool.Proton-GE Flatpak extension --
# also not something `flatpak install` can fetch on its own.

# Default shell: zsh (already in pkglist.txt, just needs to be set)
if [ "$SHELL" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)" "$USER"
fi

# nvm / uv / bun -- not in the official repos, installed via upstream scripts
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
if [ ! -f "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
if [ ! -d "$HOME/.bun" ]; then
    curl -fsSL https://bun.sh/install | bash
fi

# Podman rootless + Docker CLI compat (podman/podman-docker are in pkglist.txt)
grep -q "^$USER:" /etc/subuid || sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
sudo loginctl enable-linger "$USER"
systemctl --user enable --now podman.socket
sudo mkdir -p /etc/containers/registries.conf.d
sudo cp containers/registries.conf.d/*.conf /etc/containers/registries.conf.d/

# Locale and Keyboard Layouts
#
# BUG FOUND (2026-09-06): this cp'd a locale.gen out of the repo, but no
# locale.gen was ever actually committed here -- only vconsole.conf and
# 00-keyboard.conf exist. This step has been broken since the very first
# commit; running bootstrap.sh fresh today fails right here. Guarded so a
# fresh checkout without one just skips the step instead of aborting the
# whole script -- add locale.gen back to the repo if you want this
# re-enabled unconditionally.
if [ -f locale.gen ]; then
    sudo cp locale.gen /etc/locale.gen
    sudo locale-gen
else
    echo "locale.gen not found in repo -- skipping (see bootstrap.sh comment)"
fi
sudo cp vconsole.conf /etc/vconsole.conf
sudo cp 00-keyboard.conf /etc/X11/xorg.conf.d/


echo "Migration complete! \n Use stow . to symlink the dotfiles once you are settled in"
 
