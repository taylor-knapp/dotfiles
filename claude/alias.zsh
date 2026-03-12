# Directories Claude is allowed to read/write inside the safehouse sandbox.
export SAFEHOUSE_ADD_DIRS="$HOME/code/claudie:$HOME/.dotfiles:$HOME/.config/nvim:$HOME/code/uaa-shared:$HOME/code/notes:$HOME/code/tickets"

# Wrap claude in agent-safehouse for runtime guardrails.
cl() { clear && safehouse claude "$@"; }
