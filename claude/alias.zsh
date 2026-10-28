# cl: Claude Code with omai env (settings.json `env` block), no nono sandbox. --no-omai skips omai env.
cl() {
  local omai="$HOME/.dotfiles/claude/omai/settings.json" use_omai=true a
  local -a args env_pairs
  for a in "$@"; do
    case "$a" in
      --no-omai) use_omai=false ;;
      *) args+=("$a") ;;
    esac
  done
  if [[ $use_omai == true && -s $omai ]]; then
    env_pairs=("${(@f)$(python3 -I - "$omai" <<'PY'
import json, re, sys
env = json.load(open(sys.argv[1])).get("env") or {}
for k, v in env.items():
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", k):
        print(f"{k}={v}")
PY
)}")
    env "${env_pairs[@]}" claude "${args[@]}"
  else
    claude "${args[@]}"
  fi
}
