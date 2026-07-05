# ==================================================
# Environment & Core Behavior
# ==================================================

# Mise shim
(& mise activate pwsh) | Out-String | Invoke-Expression

# Editor
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'nvim'
    $env:VISUAL = 'nvim'
}
elseif (Get-Command vim -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'vim'
    $env:VISUAL = 'vim'
}
else {
    $env:EDITOR = 'vi'
    $env:VISUAL = 'vi'
}

Set-Alias vi nvim -ErrorAction SilentlyContinue
Set-Alias vim nvim -ErrorAction SilentlyContinue

Set-Alias c cls -ErrorAction SilentlyContinue


# ==================================================
# ReadLine & Completion
# ==================================================

if (Get-Module -ListAvailable PSReadLine) {
    # Import-Module PSReadLine

    # Menu-style completion (bash-like)
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Optional (kept commented by you)
    # Set-PSReadLineOption -PredictionSource History
    # Set-PSReadLineOption -PredictionViewStyle ListView
}

# if (Get-Module -ListAvailable posh-git) {
#     Import-Module posh-git
# }

# if (Get-Module -ListAvailable TabExpansionPlusPlus) {
#     Import-Module TabExpansionPlusPlus
# }

# if (Get-Module -ListAvailable PSFzf) {
#     Import-Module PSFzf
# }


# ==================================================
# Filesystem & Navigation
# ==================================================

# eza (ls replacement)
if (Get-Command eza -ErrorAction SilentlyContinue) {

    Remove-Item alias:ls -ErrorAction SilentlyContinue

    function ls  { eza -lh --group-directories-first --icons=auto @args }
    function lsa { eza -lh --group-directories-first --icons=auto -a @args }
    function ll  { eza -lh --group-directories-first --icons=auto @args }
    function lt  { eza --tree --level=2 --long --icons --git @args }
    function lta { eza --tree --level=2 --long --icons --git -a @args }

    function l  { ls @args }
    function la { lsa @args }
}

# Directory shortcuts
function ..   { Set-Location .. }
function ...  { Set-Location ../.. }
function .... { Set-Location ../../.. }


# ==================================================
# Fuzzy Finder (fzf)
# ==================================================

if (Get-Command fzf -ErrorAction SilentlyContinue) {

    $env:FZF_DEFAULT_OPTS = '--height=40% --layout=reverse --border'

    # Ctrl+R → history search
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        $command = Get-Content (Get-PSReadLineOption).HistorySavePath |
                   fzf --tac --no-sort
        if ($command) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
        }
    }

    # Ctrl+T → file picker with bat preview
    Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock {
        $file = fzf --preview 'bat --style=numbers --color=always {}'
        if ($file) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($file)
        }
    }

    function ff {
        fzf --preview 'bat --style=numbers --color=always {}'
    }
}


# ==================================================
# External Tools
# ==================================================

# yazi (cwd sync)
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi.exe $args --cwd-file="$tmp"

    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }

    Remove-Item -Path $tmp
}

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (& zoxide init powershell) | Out-String | Invoke-Expression
    
    # Override cd to use zoxide
    Set-Alias -Name cd -Value z -Option AllScope -Force
}

# open (xdg-open equivalent)
function open {
    param([string[]]$Path)
    Start-Process @Path
}


# ==================================================
# Developer Shortcuts
# ==================================================

Set-Alias g git
Set-Alias d docker
Set-Alias r rails

function n {
    if ($args.Count -eq 0) {
        nvim .
    } else {
        nvim @args
    }
}


# ==================================================
# Git Helpers
# ==================================================

function gcm  { git commit -m @args }
function gcam { git commit -a -m @args }
function gcad { git commit -a --amend }

# ==================================================
# Prompt
# ==================================================

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
