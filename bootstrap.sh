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
flatpak install com.usebottles.bottles -y
flatpak install flathub com.github.tchx84.Flatseal -y

# Locale and Keyboard Layouts
sudo cp locale.gen /etc/locale.gen
sudo cp vconsole.conf /etc/vconsole.conf
sudo cp 00-keyboard.conf /etc/X11/xorg.conf.d/
sudo locale-gen


echo "Migration complete! \n Use stow . to symlink the dotfiles once you are settled in"
 
