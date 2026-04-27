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
    cd ./ohmyzsh || return 1
    git sparse-checkout set --no-cone /plugins/$pluginid
    git checkout --quiet
    cd .. || return 1
    local file
    for file (./ohmyzsh/plugins/$pluginid/*~(.gitignore|*.plugin.zsh)(D)) {
        print "Copying ${file:t}..."
        cp -R $file ./${file:t}
    }
    rm -rf ./ohmyzsh
}

ZOXIDE_CMD_OVERRIDE=cd

# ----------------------------------------------------------
# 2. Prompt & Runtime Binaries (Immediate)
# ----------------------------------------------------------
# If starship feels slow, profile a minimal zsh first before moving it out of zinit.
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

# ----------------------------------------------------------
# 3. Core Shell Behavior (Immediate)
# ----------------------------------------------------------
zinit ice lucid atinit'[[ -f ./history-substring-search.zsh ]] || _fix-omz-plugin' \
          atpull"%atclone" atclone"_fix-omz-plugin"
zi snippet OMZP::history-substring-search

# ----------------------------------------------------------
# 4. Completions (Cached & Deferred)
# ----------------------------------------------------------
zinit ice wait"1" lucid blockf \
          atclone"./zplug.zsh" atpull"%atclone"
zinit light g-plane/pnpm-shell-completion

zinit ice wait"1" lucid blockf atload"zicompinit -C; zicdreplay"
zinit light zsh-users/zsh-completions

# ----------------------------------------------------------
# 5. Visual Enhancers (Deferred)
# ----------------------------------------------------------
zinit ice wait"1" lucid atload"!_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# Keep this last among visual plugins so highlighters attach after completions are ready.
zinit ice wait"2" lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# ----------------------------------------------------------
# 6. Active OMZ Libraries (Deferred)
# ----------------------------------------------------------
zinit ice wait"1" lucid
for snippet in \
    OMZL::git.zsh \
    OMZL::functions.zsh \
    OMZL::bzr.zsh \
    OMZL::clipboard.zsh \
    OMZL::key-bindings.zsh \
    OMZL::misc.zsh \
    OMZL::directories.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::correction.zsh \
    OMZL::async_prompt.zsh \
    OMZL::completion.zsh \
    OMZL::termsupport.zsh \
    OMZP::aliases \
    OMZP::git \
    OMZP::extract \
    OMZP::sudo \
    OMZP::colored-man-pages \
    OMZP::history \
    OMZP::eza
do
    zi snippet "$snippet"
done

# ----------------------------------------------------------
# 7. Enabled Tool Providers (Deferred)
# ----------------------------------------------------------
zinit wait"1" lucid atpull"%atclone" atclone"_fix-omz-plugin" for \
    OMZP::bun \
    OMZP::alias-finder \
    OMZP::pm2 \
    OMZP::web-search \
    OMZP::copyfile \
    OMZP::copypath \
    OMZP::cp \
    OMZP::git-extras \
    OMZP::command-not-found \
    OMZP::systemd \
    OMZP::rsync \
    OMZP::zoxide \
    OMZP::tldr \
    OMZP::fzf \
    OMZP::mise \
    OMZP::python \
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
    OMZP::brew \
    OMZP::terraform \
    OMZP::ubuntu

# OMZ plugins without a standard *.plugin.zsh entrypoint need completion-style loading.
zinit ice wait"1" lucid as"completion"
zi snippet OMZ::plugins/ufw/_ufw
zinit ice wait"1" lucid as"completion"
zi snippet OMZ::plugins/ng/_ng
zinit ice wait"1" lucid as"completion"
zi snippet OMZ::plugins/pass/_pass

# ----------------------------------------------------------
# 8. Optional Tool Providers (Disabled In Fast Path)
# ----------------------------------------------------------
# These stay commented so they can be re-enabled later without rewriting the provider.
# Prefer one active provider per tool to avoid duplicate hooks and completion cost.
#
# zinit ice wait"1" lucid
# for snippet in \
#     OMZP::bun \
#     OMZP::alias-finder \
#     OMZP::pm2 \
#     OMZP::dnf \
#     OMZP::web-search \
#     OMZP::copyfile \
#     OMZP::copypath \
#     OMZP::cp \
#     OMZP::git-extras \
#     OMZP::command-not-found \
#     OMZP::systemd \
#     OMZP::rsync \
#     OMZP::zoxide \
#     OMZP::tldr \
#     OMZP::fzf \
#     OMZP::mise \
#     OMZP::python \
#     OMZP::ruby \
#     OMZP::golang \
#     OMZP::node \
#     OMZP::deno \
#     OMZP::nestjs \
#     OMZP::npm \
#     OMZP::nvm \
#     OMZP::fnm \
#     OMZP::postgres \
#     OMZP::mongocli \
#     OMZP::vscode \
#     OMZP::gh \
#     OMZP::docker \
#     OMZP::docker-compose \
#     OMZP::podman \
#     OMZP::kubectl \
#     OMZP::kubectx \
#     OMZP::k9s \
#     OMZP::kind \
#     OMZP::minikube \
#     OMZP::helm \
#     OMZP::argocd \
#     OMZP::svcat \
#     OMZP::brew \
#     OMZP::terraform
# do
#     zi snippet "$snippet"
# done

# --- Database & Tools ---

# --- Disabled / Inactive Plugins (Safe to uncomment here) ---
# zinit wait"0" lucid atpull"%atclone" atclone"_fix-omz-plugin" for \
#     OMZP::ufw \
#     OMZP::deno \
#     OMZP::nestjs \
#     OMZP::brew \
#     OMZP::ubuntu \
#     OMZP::dnf \
#     OMZP::ng \
#     OMZP::pass \
#     OMZP::git-auto-fetch \
#     OMZP::archlinux \
#     OMZP::redis-cli \
#     OMZP::ssh-agent \
#     OMZP::gpg-agent \
#     OMZP::suse

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
# 9. Zinit Annexes
# ----------------------------------------------------------
# Annexes currently still need to be loaded without turbo.
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
