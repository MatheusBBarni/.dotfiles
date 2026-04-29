export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="candy"

# CASE_SENSITIVE="true"

# HYPHEN_INSENSITIVE="true"

# DISABLE_AUTO_UPDATE="true"

# DISABLE_UPDATE_PROMPT="true"

# export UPDATE_ZSH_DAYS=13

# DISABLE_MAGIC_FUNCTIONS="true"

# DISABLE_LS_COLORS="true"

# DISABLE_AUTO_TITLE="true"

# ENABLE_CORRECTION="true"

# COMPLETION_WAITING_DOTS="true"

# DISABLE_UNTRACKED_FILES_DIRTY="true"

# HIST_STAMPS="mm/dd/yyyy"

# ZSH_CUSTOM=/path/to/new-custom-folder

plugins=(
	git
	dnf
	zsh-syntax-highlighting
	zsh-autosuggestions
	docker
	docker-compose
)

source $ZSH/oh-my-zsh.sh

# GIT
[ -f "$HOME/start-ssh.sh" ] && . "$HOME/start-ssh.sh"

alias ga="git add ."
alias gpush="git push"
alias gpull="git pull"
alias gs="git status"
alias gcm="git commit -m"
alias gf="git fetch origin"
alias gck="git checkout"

# Docker

# Docker Compose Up
alias dcu="docker compose up"
# Docker Compose Down
alias dcd="docker compose down"
# Docker Remove Images
alias drmi='docker rmi $(docker images -q)'
# Docker Delete All Containers
alias ddac='docker rm -f $(docker ps -a -q)'
# Docker Stop All Containers
alias dsal='docker kill $(docker ps -q)'

# NVM
[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh

command -v nvm >/dev/null 2>&1 && nvm use default >/dev/null 2>&1

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH

# GO
export GOROOT=/usr/local/go

# Turso
export PATH="$PATH:/home/adminai/.turso"

# Codex
alias coo="codex --yolo"

# bun completions
[ -s "/home/adminai/.bun/_bun" ] && source "/home/adminai/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
