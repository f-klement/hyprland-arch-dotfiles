source /etc/profile

export MOZ_ENABLE_WAYLAND=1
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland
export QT_QPA_PLATFORM=wayland

export PATH="$PATH:/home/arch/.local/bin"
#eval "$(register-python-argcomplete pip)"

### ARCHIVE EXTRACTION
# usage: ex <file>
ex() {
	if [ -f "$1" ]; then
		case $1 in
		*.tar.bz2) tar xjf $1 ;;
		*.tar.gz) tar xzf $1 ;;
		*.bz2) bunzip2 $1 ;;
		*.rar) unrar x $1 ;;
		*.gz) gunzip $1 ;;
		*.tar) tar xf $1 ;;
		*.tbz2) tar xjf $1 ;;
		*.tgz) tar xzf $1 ;;
		*.zip) unzip $1 ;;
		*.Z) uncompress $1 ;;
		*.7z) 7z x $1 ;;
		*.deb) ar x $1 ;;
		*.tar.xz) tar xf $1 ;;
		*.tar.zst) unzstd $1 ;;
		*) echo "'$1' cannot be extracted via ex()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

export TERM=xterm-color

alias vim="nvim"
alias ls="ls -ial --color=auto"
#look up
alias fman="compgen -c | fzf | xargs man"
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

#####  pacman

alias unlock='sudo rm /var/lib/pacman/db.lck'    # remove pacman lock
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)' # remove orphaned packages (DANGEROUS!)

##### misc

# adding flags
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

alias wire-up='wg-quick up wg0'
alias wire-down='wg-quick down wg0'
alias yayx='yay -Syu --noconfirm && sudo flatpak update -y && sudo snap refresh'

#####  starship

eval "$(starship init bash)"

##-----------------------------------------------------
## synth-shell-prompt.sh
if [ -f /home/florian/.config/synth-shell/synth-shell-prompt.sh ] && [ -n "$(echo $- | grep i)" ]; then
	source /home/florian/.config/synth-shell/synth-shell-prompt.sh
fi

##-----------------------------------------------------
## better-history
if [ -f /home/florian/.config/synth-shell/better-history.sh ] && [ -n "$(echo $- | grep i)" ]; then
	source /home/florian/.config/synth-shell/better-history.sh
fi
#send logs
alias paste="curl -F 'clbin=<-' https://clbin.com"
alias dc="docker compose"

eval "$(zoxide init --cmd cd bash)"
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

work() {
    local vm=debian-work uri=qemu:///system
    case "$1" in
        stop)   virsh -c $uri shutdown $vm ;;
        status) virsh -c $uri domstate $vm ;;
        *)
            [ "$(virsh -c $uri domstate $vm)" = running ] || virsh -c $uri start $vm
            virt-viewer --connect $uri --attach --full-screen --wait --reconnect $vm & disown
            ;;
    esac
}
