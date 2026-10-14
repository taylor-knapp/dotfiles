#!/bin/bash
#
# Claude Code Statusline Command
# ===============================
#
# OUTPUT FORMAT:
#   Line 1: Model (CtxSize) | repo (branch) | ctx [bar] X% | blk [bar] Y% (Zhrs) | wk [bar] W%
#   Line 2: Costs: $A session | $B blk | $C mo | $D Mtok
#
# COMPONENTS:
#   - Model:     Current Claude model (e.g., "Opus 4.6")
#   - CtxSize:   Context window size (e.g., "200K")
#   - effort:    Reasoning effort level from .effort.level (e.g. "high"); omitted if unsupported
#   - repo:      Git repository name
#   - branch:    Current git branch
#   - ctx [bar]: Context window usage relative to autocompact threshold
#                Calculated as: used_tokens / compact_window * 100
#                Where compact_window = CLAUDE_CODE_AUTO_COMPACT_WINDOW (default: ctx_window)
#                Color based on effective percentage (green <70%, yellow 70-89%, red >=90%)
#   - blk [bar]: 5-hour rate limit utilization bar
#                Color based on projected utilization
#   - Zhrs:      Hours remaining until 5-hour block resets
#   - wk [bar]:  7-day rolling utilization bar
#                Color based on projected utilization
#   - $A session: Cost of this conversation
#   - $B blk:    Cost of current 5-hour block (from ccusage)
#   - $C mo:     Cost over last 30 days (from ccusage)
#   - $D Mtok:   Base input price per million tokens for the current model
#                Opus $4, Sonnet $2, Haiku $0.10 (green) up to 100K used tokens, $0.50 (red) above
#
# COLOR THRESHOLDS (same for all bars):
#   Green  = <70%
#   Yellow = 70-89%
#   Red    = >=90%
#
# DATA SOURCES:
#   - Anthropic OAuth API (api.anthropic.com/api/oauth/usage):
#       five_hour.utilization, five_hour.resets_at, seven_day.utilization
#   - ccusage (local JSONL logs): block cost, monthly cost
#   - Statusline JSON input: model, context %, session cost, cwd
#   - CLAUDE_CODE_AUTO_COMPACT_WINDOW env var: compact window in tokens (default: ctx window)
#
# CACHING:
#   - API cache: /tmp/claude/statusline-api-cache.json (300s TTL)
#   - ccusage cache: /tmp/claude/statusline-ccusage-cache.json (300s TTL)
#   - Both refresh in background to avoid blocking statusline
#   - Stale cache is preserved; atomic writes prevent corruption
#   - Staleness indicator (Xm) shown when cache exceeds TTL
#

input=$(cat)

# ==== Color definitions ====
GREEN=$'\033[38;2;43;147;72m'     # #2b9348
YELLOW=$'\033[38;2;254;228;64m'   # #fee440
RED=$'\033[38;2;255;89;94m'       # #ff595e
LIGHT=$'\033[38;2;248;249;250m'   # #f8f9fa
DIM=$'\033[38;2;73;80;87m'        # #212529 lightened
RESET=$'\033[0m'

# ==== Progress bar function ====
# Args: $1=fill_pct (0-100), $2=color_pct (determines color threshold, 0-100)
make_bar() {
    local fill_pct=${1:-0}
    local color_pct=${2:-$fill_pct}
    local width=5

    local filled=$(( fill_pct * width / 100 ))
    [[ $fill_pct -gt 0 && $filled -eq 0 ]] && filled=1
    [[ $filled -gt $width ]] && filled=$width
    local empty=$(( width - filled ))

    local color
    if [[ $color_pct -ge 90 ]]; then
        color="$RED"
    elif [[ $color_pct -ge 70 ]]; then
        color="$YELLOW"
    else
        color="$GREEN"
    fi

    local bar="" empty_bar="" i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do empty_bar+="░"; done

    printf '%s' "${color}${bar}${DIM}${empty_bar}${RESET}"
}

# ==== Extract values from JSON ====
# Single jq pass — one value per line so we fork once instead of six times.
# Do NOT switch this to @tsv + `IFS=$'\t' read`: tab is an IFS whitespace
# character, so empty fields collapse and every later value shifts left.
{
    read -r model
    read -r effort
    read -r context_used
    read -r context_total
    read -r session_cost
    read -r cwd
} <<<"$(
    echo "$input" | jq -r '
        .model.display_name // "Claude",
        .effort.level // "",
        (.context_window.used_percentage // 0 | round),
        (.context_window.context_window_size // 0 | round),
        .cost.total_cost_usd // 0,
        .cwd // ""
    '
)"

# ==== Calculate effective ctx percentage ====
# compact_window: token budget for compaction (defaults to full context window)
# Effective % = used_tokens / compact_window * 100
compact_window="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-$context_total}"
# Cap at actual context window
if [[ "$compact_window" -gt "$context_total" ]] 2>/dev/null; then
    compact_window="$context_total"
fi

# ==== Format model with effort and context window size ====
# Format: "Model: effort (CtxSizeK)" — e.g. "Opus 4.8: high (200K)"
# Shows the compact window when set (what the ctx bar measures against),
# otherwise the full context window.
# Effort level (/effort low|medium|high|xhigh|max) comes from .effort.level in the
# statusline JSON input. It is only present when the current model supports
# reasoning effort, so it is omitted when absent.
model_display="$model"
[[ -n "$effort" ]] && model_display="$model: $effort"
if [[ "$compact_window" -gt 0 ]] 2>/dev/null; then
    ctx_size_k=$(( compact_window / 1000 ))
    model_display="$model_display (${ctx_size_k}K)"
fi
if [[ $compact_window -gt 0 ]] 2>/dev/null; then
    ctx_effective_pct=$(awk "BEGIN {
        used_tokens = $context_used * $context_total / 100
        v = used_tokens / $compact_window * 100
        printf \"%.0f\", (v > 100 ? 100 : v)
    }")
else
    ctx_effective_pct=$context_used
fi

# ==== Base token price (per million input tokens) ====
# Opus and Sonnet have fixed prices. Haiku is tiered on used context tokens:
# green $0.10 at or below 100K, red $0.50 above 100K.
used_tokens=$(( context_used * context_total / 100 ))
base_token_segment=""
case "$model" in
    *Opus*)   base_token_segment=" | \$4 Mtok" ;;
    *Sonnet*) base_token_segment=" | \$2 Mtok" ;;
    *Haiku*)
        if [[ $used_tokens -le 100000 ]]; then
            base_token_segment=" | ${GREEN}\$0.10 Mtok${RESET}"
        else
            base_token_segment=" | ${RED}\$0.50 Mtok${RESET}"
        fi
        ;;
esac

# ==== Get repo name, branch, and worktree info ====
# One rev-parse for all four values; --path-format applies to the options after it,
# so reset it to default before --abbrev-ref. Output order matches the flag order.
{
    read -r git_common_dir
    read -r git_dir
    read -r git_toplevel
    read -r branch
} <<<"$(git -C "$cwd" rev-parse \
    --path-format=absolute --git-common-dir --git-dir --show-toplevel \
    --path-format=relative --abbrev-ref HEAD 2>/dev/null)"

# Outside a repo, rev-parse writes only to stderr and these stay empty. The
# leading-slash test also rejects any git version that prints a bare `.git`.
if [[ "$git_common_dir" == /* ]]; then
    repo="${git_common_dir%/*}"
    repo="${repo##*/}"
else
    git_common_dir=""
    git_dir=""
    repo="${cwd##*/}"
    [[ -z "$repo" ]] && repo="unknown"
fi
[[ -z "$branch" ]] && branch="unknown"

is_worktree=false
worktree_name=""
if [[ -n "$git_dir" && -n "$git_common_dir" && "$git_dir" != "$git_common_dir" ]]; then
    is_worktree=true
    worktree_name="${git_toplevel%/}"
    worktree_name="${worktree_name##*/}"
fi

if [[ "$is_worktree" == "true" ]]; then
    location="$repo ($worktree_name: $branch)"
else
    location="$repo ($branch)"
fi

# ==== Anthropic API cache (block %, week %, reset time) ====
api_cache_file="/tmp/claude/statusline-api-cache.json"
ccusage_cache_file="/tmp/claude/statusline-ccusage-cache.json"
cache_max_age=300

# One `date` and one `stat` for both caches instead of two of each.
# stat silently skips missing files, so the mtimes are keyed by filename rather
# than by output position — position would shift when only one cache exists.
now_epoch=$(date +%s)

api_cache_mtime=0
cc_cache_mtime=0
while read -r _mtime _name; do
    case "$_name" in
        "$api_cache_file")     api_cache_mtime="$_mtime" ;;
        "$ccusage_cache_file") cc_cache_mtime="$_mtime" ;;
    esac
done <<<"$(stat -f '%m %N' "$api_cache_file" "$ccusage_cache_file" 2>/dev/null)"

if [[ "$api_cache_mtime" != 0 ]]; then
    api_age=$((now_epoch - api_cache_mtime))
else
    api_age=999999
fi
if [[ "$cc_cache_mtime" != 0 ]]; then
    cc_age=$((now_epoch - cc_cache_mtime))
else
    cc_age=999999
fi

if [[ $api_age -gt $cache_max_age ]]; then
    mkdir -p /tmp/claude
    (
        log="/tmp/claude/statusline-fetch.log"
        ts=$(date +%Y-%m-%dT%H:%M:%S)
        log_line() { printf '[%s] %s\n' "$ts" "$*" >> "$log"; }

        token=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
        if [[ -z "$token" ]]; then
            log_line "FAIL token: keychain empty"
            exit 0
        fi
        log_line "OK token len=${#token}"

        http_code=$(curl -s -o "${api_cache_file}.body" -w '%{http_code}' --max-time 5 \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            https://api.anthropic.com/api/oauth/usage 2>>"$log")
        curl_exit=$?
        body_size=$(wc -c < "${api_cache_file}.body" 2>/dev/null | tr -d ' ')
        log_line "curl exit=$curl_exit http=$http_code body_bytes=$body_size"

        if [[ $curl_exit -ne 0 ]]; then
            log_line "FAIL curl nonzero, body head: $(head -c 200 "${api_cache_file}.body" 2>/dev/null)"
            rm -f "${api_cache_file}.body"
            exit 0
        fi

        if ! jq -e '.five_hour.utilization' < "${api_cache_file}.body" >/dev/null 2>&1; then
            log_line "FAIL jq validation, body head: $(head -c 200 "${api_cache_file}.body" 2>/dev/null)"
            rm -f "${api_cache_file}.body"
            exit 0
        fi

        mv "${api_cache_file}.body" "$api_cache_file"
        log_line "OK wrote cache"
    ) &
fi

# ==== ccusage cache (block cost, monthly cost) ====
# --offline can be added to speed up queries, but then often misses pricing data for the latest models
if [[ $cc_age -gt $cache_max_age ]]; then
    mkdir -p /tmp/claude
    (
        block_data=$(ccusage blocks --active --json --token-limit max 2>/dev/null)
        daily_data=$(ccusage --json 2>/dev/null)
        if [[ -n "$block_data" && -n "$daily_data" ]]; then
            combined="{\"block\": $block_data, \"daily\": $daily_data}"
            if echo "$combined" | jq -e . >/dev/null 2>&1; then
                echo "$combined" > "${ccusage_cache_file}.tmp" && mv "${ccusage_cache_file}.tmp" "$ccusage_cache_file"
            fi
        fi
    ) &
fi

# ==== Read API data ====
api_available=false
if [[ -f "$api_cache_file" ]]; then
    # Single jq pass; utilizations are rounded here instead of via extra printf forks.
    # One value per line — see the note above about tab-delimited reads.
    {
        read -r block_percent
        read -r week_percent
        read -r resets_at
        read -r week_resets_at
    } <<<"$(
        jq -r '
            (if .five_hour.utilization == null then "" else (.five_hour.utilization | round) end),
            (if .seven_day.utilization == null then "" else (.seven_day.utilization | round) end),
            .five_hour.resets_at // "",
            .seven_day.resets_at // ""
        ' < "$api_cache_file" 2>/dev/null
    )"

    if [[ -n "$block_percent" && -n "$week_percent" ]]; then
        api_available=true
        projected_block_percent=$block_percent

        if [[ -n "$resets_at" ]]; then
            reset_clean="${resets_at%%.*}"
            reset_clean="${reset_clean%%+*}"
            reset_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%S" "$reset_clean" +%s 2>/dev/null)
            if [[ -n "$reset_epoch" && "$reset_epoch" -gt "$now_epoch" ]]; then
                remaining_secs=$((reset_epoch - now_epoch))
                remaining_hrs=$(awk "BEGIN {printf \"%.1f\", $remaining_secs / 3600}")
                # Project linearly from elapsed share of the 5h window.
                # First ~6 minutes have too little signal — skip and use current %.
                projected_block_percent=$(awk "BEGIN {
                    elapsed = 5 - $remaining_secs / 3600
                    if (elapsed < 0.1) { print $block_percent; exit }
                    v = $block_percent * 5 / elapsed
                    printf \"%.0f\", (v > 100 ? 100 : v)
                }")
            else
                remaining_hrs="0.0"
            fi
        else
            remaining_hrs="?"
        fi

        # Project weekly utilization from elapsed share of the 7-day window.
        projected_week_percent=$week_percent
        week_day=""
        if [[ -n "$week_resets_at" ]]; then
            week_reset_clean="${week_resets_at%%.*}"
            week_reset_clean="${week_reset_clean%%+*}"
            week_reset_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%S" "$week_reset_clean" +%s 2>/dev/null)
            if [[ -n "$week_reset_epoch" && "$week_reset_epoch" -gt "$now_epoch" ]]; then
                week_day=" ($(date -r "$week_reset_epoch" +%a))"
                # Skip the first hour — too little signal to extrapolate.
                projected_week_percent=$(awk "BEGIN {
                    total = 7 * 86400
                    elapsed = total - ($week_reset_epoch - $now_epoch)
                    if (elapsed < 3600) { print $week_percent; exit }
                    v = $week_percent * total / elapsed
                    printf \"%.0f\", (v > 100 ? 100 : v)
                }")
            fi
        fi
    fi
fi

# ==== Read ccusage data ====
block_cost="0"
month_cost="0"
if [[ -f "$ccusage_cache_file" ]]; then
    ccusage_data=$(<"$ccusage_cache_file")
    # Compute the 30-day cutoff inside jq so we skip a `date` fork too.
    {
        read -r block_cost
        read -r month_cost
    } <<<"$(
        jq -r '
            (now - 30 * 86400 | strftime("%Y-%m-%d")) as $d |
            .block.blocks[0].costUSD // 0,
            ([.daily.daily[] | select(.period >= $d) | .totalCost] | add // 0)
        ' < "$ccusage_cache_file" 2>/dev/null
    )"
    block_cost="${block_cost:-0}"
    month_cost="${month_cost:-0}"
fi

# ==== Staleness indicator ====
api_stale=""
if [[ "$api_available" == "true" && $api_age -gt $cache_max_age ]]; then
    api_stale=" ($(( api_age / 60 ))m)"
fi
cc_stale=""
if [[ -f "$ccusage_cache_file" && $cc_age -gt $cache_max_age ]]; then
    cc_stale=" ($(( cc_age / 60 ))m)"
fi

# ==== Fallback: use ccusage for block % if API unavailable ====
if [[ "$api_available" != "true" && -f "$ccusage_cache_file" ]]; then
    block_tokens=$(echo "$ccusage_data" | jq -r '.block.blocks[0].totalTokens // 0')
    block_limit=$(echo "$ccusage_data" | jq -r '.block.blocks[0].tokenLimitStatus.limit // 50000000')
    block_percent=$(awk "BEGIN {printf \"%.0f\", ($block_tokens / $block_limit) * 100}")

    remaining_mins=$(echo "$ccusage_data" | jq -r '.block.blocks[0].projection.remainingMinutes // 0')
    remaining_hrs=$(echo "$remaining_mins" | awk '{printf "%.1f", $1/60}')

    projected_tokens=$(echo "$ccusage_data" | jq -r '.block.blocks[0].projection.totalTokens // 0')
    projected_percent=$(awk "BEGIN {printf \"%.0f\", ($projected_tokens / $block_limit) * 100}")

    week_ago=$(date -v-7d +%Y-%m-%d)
    week_cost=$(echo "$ccusage_data" | jq -r --arg d "$week_ago" '[.daily.daily[] | select(.period >= $d) | .totalCost] | add // 0')

    # Build bars — blk color based on projected utilization
    ctx_bar=$(make_bar "$ctx_effective_pct" "$ctx_effective_pct")
    blk_bar=$(make_bar "$block_percent" "$projected_percent")

    session_cost_display=$(printf "\$%.2f" "$session_cost")
    block_cost_display=$(printf "\$%.2f" "$block_cost")
    week_cost_display=$(printf "\$%.0f" "$week_cost")
    month_cost_display=$(printf "\$%.0f" "$month_cost")

    printf "${RESET}%s | %s | ctx [%s${RESET}] %s%% | blk [%s${RESET}] %s%% (%shrs) | %s wk%s\nCosts: %s session | %s blk | %s mo%s${RESET}" \
        "$model_display" "$location" \
        "$ctx_bar" "$ctx_effective_pct" \
        "$blk_bar" "$block_percent" "$remaining_hrs" \
        "$week_cost_display" "$cc_stale" \
        "$session_cost_display" "$block_cost_display" "$month_cost_display" "$base_token_segment"
    exit 0
fi

# ==== Output ====
if [[ "$api_available" == "true" ]]; then
    ctx_bar=$(make_bar "$ctx_effective_pct" "$ctx_effective_pct")
    blk_bar=$(make_bar "$block_percent" "$projected_block_percent")
    wk_bar=$(make_bar "$week_percent" "$projected_week_percent")

    session_cost_display=$(printf "\$%.2f" "$session_cost")
    block_cost_display=$(printf "\$%.2f" "$block_cost")
    month_cost_display=$(printf "\$%.0f" "$month_cost")

    printf "${RESET}%s | %s | ctx [%s${RESET}] %s%% | blk [%s${RESET}] %s%% (%shrs) | wk [%s${RESET}] %s%%%s%s\nCosts: %s session | %s blk | %s mo%s${RESET}" \
        "$model_display" "$location" \
        "$ctx_bar" "$ctx_effective_pct" \
        "$blk_bar" "$block_percent" "$remaining_hrs" \
        "$wk_bar" "$week_percent" "$week_day" "$api_stale" \
        "$session_cost_display" "$block_cost_display" "$month_cost_display" "$base_token_segment"
else
    # No data at all — minimal output
    ctx_bar=$(make_bar "$ctx_effective_pct" "$ctx_effective_pct")
    session_cost_display=$(printf "\$%.2f" "$session_cost")
    printf "${RESET}%s | %s | ctx [%s${RESET}] %s%% | %s s%s${RESET}" \
        "$model_display" "$location" \
        "$ctx_bar" "$ctx_effective_pct" \
        "$session_cost_display" "$base_token_segment"
fi
