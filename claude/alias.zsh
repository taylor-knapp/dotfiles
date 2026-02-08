# Set the task list id and pass through arguments to claude.
function cl { CLAUDE_CODE_TASK_LIST_ID=$(git rev-parse --show-toplevel) claude "$@"; }