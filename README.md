# Dotfiles & Bootstrap Repo

The following is a dotfiles repository and collection of start up utils in order to get my new arch systems running and automate the process of settling into a new device. In case a none arch system is set up the list of packages might lead to difficulties being parsed directly and a manual case by case install is necessary.

The setup requires GNU stow to be on your GNU+Linux machine as well as obviously git, all else is handled by the script.


```
sudo pacman -S stow git

mkdir .dotfiles
cd .dotfiles
git clone https://github.com/f-klement/hyprland-arch-dotfiles .
chmod +x bootstrap.sh
./bootstrap.sh
```
