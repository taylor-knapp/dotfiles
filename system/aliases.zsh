# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
# $+commands[gls] checks zsh's command hash table — no subprocess fork needed.
# The old `$(gls &>/dev/null)` spawned a subshell on every startup.
if (( $+commands[gls] ))
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
fi

# ripgrep: case insensitive search sorted by file creation (most recent will be last, or closest to the new prompt).
alias rgs='rg --ignore-case --sort created'

# Keep track of time working in terminal during broken schedules (e.g. kids).
stopwatch() {
    start=$(date +%s)
    while true; do
        now=$(date +%s)
        echo -ne "\r$(date -ju -f %s $(($now - $start)) +%H:%M:%S)"
        sleep 1
    done
}