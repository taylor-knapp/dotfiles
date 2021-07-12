# Lazy load rvm.
# Source: https://github.com/FrederickGeek8/zsh-rvm-lazy/blob/master/zsh-rvm-lazy.plugin.zsh

function _unset_lazy_load_rvm() {
    local RVM_HOME="$HOME/.rvm"
    local EXT=$( head -n 1 $RVM_HOME/environments/default )
    local EXT=${EXT:13:${#EXT}-20}
    local EXT="$EXT:$HOME/.rvm/bin"

	for dir in ${(s/:/)EXT}; do
		for file in "$dir"/*(N); do
			BINARY=$file:t
			unset -f "$BINARY" 2> /dev/null
		done
	done
}

function _lazy_load_rvm() {
    local RVM_HOME="$HOME/.rvm"
    local EXT=$( head -n 1 $RVM_HOME/environments/default )
    local EXT=${EXT:13:${#EXT}-20}
    local EXT="$EXT:$HOME/.rvm/bin"

    for dir in ${(s/:/)EXT}; do
    #	echo $dir
        for file in "$dir"/*(N); do
            BINARY=$file:t
            $BINARY() {
                _unset_lazy_load_rvm

                [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

                "$0" "$@"
            }
        done
    done
}

_lazy_load_rvm