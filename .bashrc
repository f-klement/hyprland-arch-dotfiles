source /etc/profile

export MOZ_ENABLE_WAYLAND=1
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland
export QT_QPA_PLATFORM=wayland



export PATH="$PATH:/home/arch/.local/bin"
#eval "$(register-python-argcomplete pip)"

export TERM=xterm-color

alias ls="ls -ial --color=auto"

alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

eval "$(starship init bash)"

##-----------------------------------------------------
## synth-shell-prompt.sh
if [ -f /home/florian/.config/synth-shell/synth-shell-prompt.sh ] && [ -n "$( echo $- | grep i )" ]; then
	source /home/florian/.config/synth-shell/synth-shell-prompt.sh
fi

##-----------------------------------------------------
## better-history
if [ -f /home/florian/.config/synth-shell/better-history.sh ] && [ -n "$( echo $- | grep i )" ]; then
	source /home/florian/.config/synth-shell/better-history.sh
fi

alias paste="curl -F 'clbin=<-' https://clbin.com"
