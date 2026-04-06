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

# ----------------------------------------------------------
# 2. Oh My Zsh Libraries (Turbo Group 0)
# ----------------------------------------------------------
zinit wait"0" lucid for \
    OMZL::git.zsh \
    OMZL::functions.zsh \
    OMZL::bzr.zsh \
    OMZL::clipboard.zsh \
    OMZL::key-bindings.zsh \
    OMZL::misc.zsh \
    OMZL::spectrum.zsh \
    OMZL::directories.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::correction.zsh \
    OMZL::async_prompt.zsh \
    OMZL::completion.zsh \
    OMZL::compfix.zsh \
    OMZL::termsupport.zsh

zinit wait"0" lucid for \
    OMZP::bun \
    OMZP::alias-finder \
    OMZP::git \
    OMZP::extract \
    OMZP::pm2 \
    OMZP::sudo \
    OMZP::dnf \
    OMZP::colored-man-pages \
    OMZP::web-search \
    OMZP::copyfile \
    OMZP::copypath \
    OMZP::cp \
    OMZP::git-extras \
    OMZP::history \
    OMZP::command-not-found \
    OMZP::systemd \
    OMZP::zoxide \
    OMZP::eza \
    OMZP::tldr \
    OMZP::fzf \
    OMZP::mise \
    OMZP::rsync \
    OMZP::python \
    OMZP::ruby \
    OMZP::golang \
    OMZP::node \
    OMZP::deno \
    OMZP::nestjs \
    OMZP::npm \
    OMZP::nvm \
    OMZP::fnm \
    OMZP::postgres \
    OMZP::mongocli \
    OMZP::vscode \
    OMZP::gh \
    OMZP::docker \
    OMZP::docker-compose \
    OMZP::podman \
    OMZP::kubectl \
    OMZP::kubectx \
    OMZP::k9s \
    OMZP::kind \
    OMZP::minikube \
    OMZP::helm \
    OMZP::argocd \
    OMZP::svcat \
    OMZP::starship \
    OMZP::brew \
    OMZP::terraform

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
    
zi for \
    atload"zicompinit; zicdreplay" \
    blockf \
    lucid \
    wait \
  zsh-users/zsh-completions

### End of Zinit's installer chunk

# autoload -Uz compinit
# compinit
# zinit cdreplay -q
