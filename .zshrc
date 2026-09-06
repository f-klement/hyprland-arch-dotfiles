# ~/.zshrc
# Sourced for INTERACTIVE shells. Use for aliases, functions, and tool init.

# --- Original Zsh config (from zsh-newuser-install) ---
# Use the $HOME variable for portability
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit

HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt autocd beep extendedglob nomatch
# BUG FOUND (2026-09-06): this was `bindkey -v` (vi keybindings), left over
# verbatim from the zsh-newuser-install wizard that generated this block --
# never revisited, unlike everything below it. Vi mode has no default
# binding for Ctrl+A/Ctrl+E (those are emacs-mode shortcuts for
# beginning-of-line/end-of-line), which is why they silently stopped
# working in every terminal, not just kitty. `bindkey -e` is zsh's own
# default and restores those plus Ctrl+K/U/W and the rest of the readline-
# style bindings.
bindkey -e
# --- End of original config ---


# --- synth-shell & better-history ---
# We use Zsh's native check for an interactive shell: [[ -o interactive ]]
if [ -f "$HOME/.config/synth-shell/synth-shell-prompt.sh" ] && [[ -o interactive ]]; then
	source "$HOME/.config/synth-shell/synth-shell-prompt.sh"
fi

if [ -f "$HOME/.config/synth-shell/better-history.sh" ] && [[ -o interactive ]]; then
	source "$HOME/.config/synth-shell/better-history.sh"
fi

# --- Aliases (Copied directly from .bashrc) ---
alias vim="nvim"
alias ls="ls -ial --color=auto"
alias grep='grep --color=auto'
alias paste="curl -F 'clbin=<-' https://clbin.com"
alias dc="docker compose"
alias dcc="docker compose up -d --force-recreate --remove-orphans"
alias dcb='docker compose up -d --build'

# fman (See In-Depth Note below)
alias fman="compgen -c | fzf | xargs man"

# pacman
alias unlock='sudo rm /var/lib/pacman/db.lck'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)' # remove orphaned packages (DANGEROUS!)

# misc
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# wireguard
alias wire-up='wg-quick up wg0'
alias wire-down='wg-quick down wg0'

# --- Archive Extraction Function (Copied directly from .bashrc) ---
# This POSIX-compliant function works perfectly in Zsh.
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


# --- Tool Integrations (at the end) ---
# These *must* be changed to initialize for Zsh.

# NVM (Node Version Manager)
# NVM_DIR is already set in .zshenv. We just source the script.
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# NOTE: The 'bash_completion' line is removed. nvm.sh handles Zsh
# completions, which are picked up by 'compinit' above.

# Atuin (Shell History)
# We use 'atuin init zsh' and REMOVE the .bash-preexec.sh line.
# Zsh has native preexec/precmd hooks that Atuin will now use.
eval "$(atuin init zsh)"

# Zoxide (Smart cd)
eval "$(zoxide init --cmd cd zsh)"

# Starship (Prompt)
# This MUST be last to ensure it controls the prompt.
eval "$(starship init zsh)"
