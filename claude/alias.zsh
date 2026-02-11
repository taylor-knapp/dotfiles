# Set the task list id and pass through arguments to claude.
function cl { node -v > /dev/null 2>&1; CLAUDE_CODE_TASK_LIST_ID=$(git rev-parse --path-format=absolute --git-common-dir) claude "$@"; }