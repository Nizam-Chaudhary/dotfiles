# ==========================================================
# ZINIT HIGH-PERFORMANCE CONFIG
# ==========================================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# ----------------------------------------------------------
# 1. Helper Function: Fix OMZ Plugins (Multi-file Support)
# ----------------------------------------------------------
_fix-omz-plugin() {
    [[ -f ./._zinit/teleid ]] || return 1
    local teleid="$(<./._zinit/teleid)"
    local pluginid
    for pluginid (${teleid#OMZ::plugins/} ${teleid#OMZP::}) {
        [[ $pluginid != $teleid ]] && break
    }
    (($?)) && return 1
    print "Fixing $teleid..."
    git clone --quiet --no-checkout --depth=1 --filter=tree:0 https://github.com/ohmyzsh/ohmyzsh
    cd ./ohmyzsh
    git sparse-checkout set --no-cone /plugins/$pluginid
    git checkout --quiet
    cd ..
    local file
    for file (./ohmyzsh/plugins/$pluginid/*~(.gitignore|*.plugin.zsh)(D)) {
        print "Copying ${file:t}..."
        cp -R $file ./${file:t}
    }
    rm -rf ./ohmyzsh
}

zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

# ----------------------------------------------------------
# 2. Oh My Zsh Libraries (Turbo Group 0)
# ----------------------------------------------------------
zinit ice wait lucid
zi snippet OMZL::git.zsh
zinit ice wait lucid
zi snippet OMZL::functions.zsh 
zinit ice wait lucid
zi snippet OMZL::bzr.zsh 
zinit ice wait lucid
zi snippet OMZL::clipboard.zsh 
zinit ice wait lucid
zi snippet OMZL::key-bindings.zsh 
zinit ice wait lucid
zi snippet OMZL::misc.zsh 
zinit ice wait lucid
zi snippet OMZL::spectrum.zsh 
zinit ice wait lucid
zi snippet OMZL::directories.zsh 
zinit ice wait lucid
zi snippet OMZL::grep.zsh 
zinit ice wait lucid
zi snippet OMZL::history.zsh 
zinit ice wait lucid
zi snippet OMZL::correction.zsh 
zinit ice wait lucid
zi snippet OMZL::async_prompt.zsh 
zinit ice wait lucid
zi snippet OMZL::completion.zsh 
zinit ice wait lucid
zi snippet OMZL::compfix.zsh 
zinit ice wait lucid
zi snippet OMZL::termsupport.zsh

zinit ice wait"1" lucid
zi snippet OMZP::bun
zinit ice wait"1" lucid
zi snippet OMZP::alias-finder
zinit ice wait"1" lucid
zi snippet OMZP::git
zinit ice wait"1" lucid
zi snippet OMZP::extract
zinit ice wait"1" lucid
zi snippet OMZP::pm2
zinit ice wait"1" lucid
zi snippet OMZP::sudo
zinit ice wait"1" lucid
zi snippet OMZP::dnf
zinit ice wait"1" lucid
zi snippet OMZP::colored-man-pages
zinit ice wait"1" lucid
zi snippet OMZP::web-search
zinit ice wait"1" lucid
zi snippet OMZP::copyfile
zinit ice wait"1" lucid
zi snippet OMZP::copypath
zinit ice wait"1" lucid
zi snippet OMZP::cp
zinit ice wait"1" lucid
zi snippet OMZP::git-extras
zinit ice wait"1" lucid
zi snippet OMZP::history
zinit ice wait"1" lucid
zi snippet OMZP::command-not-found
zinit ice wait"1" lucid
zi snippet OMZP::systemd
zinit ice wait lucid
zi snippet OMZP::zoxide
zinit ice wait lucid
zi snippet OMZP::eza
zinit ice wait"1" lucid
zi snippet OMZP::tldr
zinit ice wait"1" lucid
zi snippet OMZP::fzf
zinit ice wait"1" lucid
zi snippet OMZP::mise
zinit ice wait"1" lucid
zi snippet OMZP::rsync
zinit ice wait"1" lucid
zi snippet OMZP::python
zinit ice wait"1" lucid
zi snippet OMZP::ruby
zinit ice wait"1" lucid
zi snippet OMZP::golang
zinit ice wait"1" lucid
zi snippet OMZP::node
zinit ice wait"1" lucid
zi snippet OMZP::deno
zinit ice wait"1" lucid
zi snippet OMZP::nestjs
zinit ice wait"1" lucid
zi snippet OMZP::npm
zinit ice wait"1" lucid
zi snippet OMZP::nvm
zinit ice wait"1" lucid
zi snippet OMZP::fnm
zinit ice wait"1" lucid
zi snippet OMZP::postgres
zinit ice wait"1" lucid
zi snippet OMZP::mongocli
zinit ice wait"1" lucid
zi snippet OMZP::vscode
zinit ice wait"1" lucid
zi snippet OMZP::gh
zinit ice wait"1" lucid
zi snippet OMZP::docker
zinit ice wait"1" lucid
zi snippet OMZP::docker-compose
zinit ice wait"1" lucid
zi snippet OMZP::podman
zinit ice wait"1" lucid
zi snippet OMZP::kubectl
zinit ice wait"1" lucid
zi snippet OMZP::kubectx
zinit ice wait"1" lucid
zi snippet OMZP::k9s
zinit ice wait"1" lucid
zi snippet OMZP::kind
zinit ice wait"1" lucid
zi snippet OMZP::minikube
zinit ice wait"1" lucid
zi snippet OMZP::helm
zinit ice wait"1" lucid
zi snippet OMZP::argocd
zinit ice wait"1" lucid
zi snippet OMZP::svcat
zinit ice wait"1" lucid
zi snippet OMZP::brew
zinit ice wait"1" lucid
zi snippet OMZP::terraform

ZOXIDE_CMD_OVERRIDE=cd

# ----------------------------------------------------------
# 3. Oh My Zsh Plugins (With Sparse Checkout Fix)
# ----------------------------------------------------------
zinit wait"0" lucid atpull"%atclone" atclone"_fix-omz-plugin" for \
    OMZP::history-substring-search  \
    OMZP::aliases

# --- Database & Tools ---
    

# --- Disabled / Inactive Plugins (Safe to comment here) ---
# zinit wait"0" lucid atpull"%atclone" atclone"_fix-omz-plugin" for \
#    OMZP::ufw \
#    OMZP::deno \
#    OMZP::nestjs \
#    OMZP::brew \
#    OMZP::ubuntu \
#    OMZP::dnf \
#    OMZP::ng \
#    OMZP::pass \
    # OMZP::git-auto-fetch \
    # OMZP::archlinux \
#    OMZP::redis-cli \
    # OMZP::ssh-agent \
    # OMZP::gpg-agent \
#    OMZP::suse

# alias-finder config
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default

# eza config
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'icons' yes
zstyle ':omz:plugins:eza' 'header' yes
zstyle ':omz:plugins:eza' 'git-status' yes
# ----------------------------------------------------------
# 4. Community Plugins & Tools
# ----------------------------------------------------------

# Completions: Must run compinit early
# zinit ice wait"0" lucid atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit"
# zinit light zsh-users/zsh-completions

# Autosuggestions
zinit ice wait"0" lucid atload"!_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zi for \
    atload"zicompinit -C; zicdreplay" \
    blockf \
    lucid \
    wait \
  zsh-users/zsh-completions

# Syntax Highlighting: Must be loaded last in the group
zinit ice wait"0" lucid atload"zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

# pnpm completion
zinit ice wait"0" lucid atload"zpcdreplay" atclone"./zplug.zsh" atpull"%atclone"
zinit light g-plane/pnpm-shell-completion

# Zsh VI Mode (Shallow clone)
# zinit ice wait lucid depth"1"
# zinit light jeffreytse/zsh-vi-mode

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
    
autoload -Uz compinit
compinit
zinit cdreplay -q
### End of Zinit's installer chunk
