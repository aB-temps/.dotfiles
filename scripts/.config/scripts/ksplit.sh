#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║                         ksplit                                   ║
# ║         Kitty window layout manager — .ksconf preset system     ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# USAGE
#   ksplit <preset_name> [--cwd /path]   — run a preset
#   ksplit --list                        — list available presets
#   ksplit --help                        — show this help
#
# PRESET SEARCH ORDER  (first match wins)
#   1. $KSPLIT_DIR        (env var, if set)
#   2. ~/.config/scripts/ksplit/
#   3. ./                 (current directory)
#
# REQUIREMENTS
#   kitty.conf must contain:
#     allow_remote_control yes
#     listen_on unix:/tmp/kitty
#
# ════════════════════════════════════════════════════════════════════
# .ksconf FILE FORMAT
# ════════════════════════════════════════════════════════════════════
#
# A .ksconf file is a plain list of instructions, one per line.
# Blank lines and lines starting with # are ignored.
#
# ── PANE DECLARATION ────────────────────────────────────────────
#
#   pane <id>("<command>")   command run after layout is built
#   pane <id>()              no command — raw shell
#   pane <id>                same as above, () is optional
#
# ── SPLIT (where to place this pane) ────────────────────────────
#
#   split <direction> [bias%]
#
#       direction : right | left | below | above
#       bias%     : percentage of the REMAINING space given to the
#                   NEW pane (default 50).
#
#   !! BIAS IS RELATIVE TO THE PANE BEING SPLIT, NOT THE SCREEN !!
#
#   Formula: bias = desired_abs% / available_space% * 100
#
#   Example — 3 columns at 30% / 47% / 23% absolute width:
#     pane a                  (full width = 100%)
#       split right 70        → new right side = 70%, a = 30%
#     pane b
#       focus a
#       split right 33        → new right = 33% of 70% = ~23%, b = 47%
#     pane c
#
#   The `split` of the FIRST declared pane is ignored.
#
# ── FOCUS (which existing pane to branch from) ──────────────────
#
#   focus <pane_id>
#       Move to pane_id before creating this pane.
#       Lets you attach splits to any existing pane, enabling
#       arbitrary N-pane tree layouts.
#
# ════════════════════════════════════════════════════════════════════
# INTERNALS
# ════════════════════════════════════════════════════════════════════

set -euo pipefail

KSPLIT_CONF_DIRS=(
  "${KSPLIT_DIR:-}"
  "$HOME/.config/scripts/ksplit"
  "$(pwd)"
)

# ── kitty remote helpers ─────────────────────────────────────────

_k() { kitty @ "$@" 2>/dev/null; }

_check_remote() {
  if ! kitty @ ls > /dev/null 2>&1; then
    echo ""
    echo "  ✗  Cannot reach kitty remote control."
    echo "     Add to kitty.conf and restart kitty:"
    echo ""
    echo "       allow_remote_control yes"
    echo "       listen_on unix:/tmp/kitty"
    echo ""
    exit 1
  fi
}

# Returns the kitty window id of the currently focused window
_focused_window_id() {
  kitty @ ls 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for os_win in data:
  for tab in os_win.get('tabs', []):
    for win in tab.get('windows', []):
      if win.get('is_focused'):
        print(win['id'])
        sys.exit()
" 2>/dev/null || echo ""
}

# ── pane registry ────────────────────────────────────────────────

declare -A PANE_WIN_ID   # pane_name → kitty window id

_register_pane() {
  local name="$1"
  local wid="$2"
  PANE_WIN_ID["$name"]="$wid"
}

_focus_pane() {
  local name="$1"
  local wid="${PANE_WIN_ID[$name]:-}"
  if [[ -z "$wid" ]]; then
    echo "  ✗  Unknown pane: '$name'" >&2; exit 1
  fi
  _k focus-window --match "id:$wid" 2>/dev/null || true
  sleep 0.05
}

_send() {
  local text="$1"
  local wid="$2"
  sleep 0.3   # let the shell finish initializing
  kitty @ send-text --match "id:$wid" -- "$text
" 2>/dev/null || true
}

# ── .ksconf parser & executor ────────────────────────────────────

_run_preset_file() {
  local file="$1"
  local global_cwd="$2"

  # ── phase 1: parse ───────────────────────────────────────────
  local -a pane_list
  local -A p_split_dir    # pane → right|left|below|above
  local -A p_split_bias   # pane → 1-99
  local -A p_focus        # pane → parent pane id to split from
  local -A p_cmd          # pane → command to run after layout (may be empty)

  local cur=""

  while IFS= read -r raw || [[ -n "${raw:-}" ]]; do
    local line="${raw%%#*}"                     # strip comments
    line="${line#"${line%%[! ]*}"}"             # ltrim
    line="${line%"${line##*[! ]}"}"             # rtrim
    [[ -z "$line" ]] && continue

    local kw="${line%% *}"
    local rest="${line#* }"; [[ "$rest" == "$kw" ]] && rest=""

    case "$kw" in
      pane)
        local pane_id pane_cmd
        if [[ "$rest" == *"("* ]]; then
          pane_id="${rest%%(*}"
          pane_cmd="${rest#*(}"
          pane_cmd="${pane_cmd%)}"   # strip ) first
          pane_cmd="${pane_cmd%\"}"  # strip trailing "
          pane_cmd="${pane_cmd#\"}"  # strip leading  "
          pane_cmd="${pane_cmd%\'}"  # strip trailing '
          pane_cmd="${pane_cmd#\'}"  # strip leading  '
        else
          pane_id="$rest"
          pane_cmd=""
        fi
        cur="$pane_id"
        pane_list+=("$cur")
        p_split_dir["$cur"]="right"
        p_split_bias["$cur"]="50"
        p_focus["$cur"]=""
        p_cmd["$cur"]="$pane_cmd"
        ;;
      split)
        [[ -z "$cur" ]] && continue
        local dir="${rest%% *}"
        local bias="${rest#* }"; [[ "$bias" == "$dir" ]] && bias="50"
        p_split_dir["$cur"]="$dir"
        p_split_bias["$cur"]="$bias"
        ;;
      focus)
        [[ -z "$cur" ]] && continue
        p_focus["$cur"]="$rest"
        ;;
    esac
  done < "$file"

  # ── phase 2: build layout ────────────────────────────────────
  _check_remote

  local first=1
  for pname in "${pane_list[@]}"; do
    if (( first )); then
      local wid; wid="$(_focused_window_id)"
      _register_pane "$pname" "$wid"
      if [[ -n "$global_cwd" ]]; then
        _send "cd '$global_cwd'" "$wid"
      fi
      first=0
    else
      local parent="${p_focus[$pname]:-}"
      [[ -n "$parent" ]] && _focus_pane "$parent"

      local loc
      case "${p_split_dir[$pname]}" in
        right|left) loc="vsplit" ;;
        below|above) loc="hsplit" ;;
        *) loc="vsplit" ;;
      esac

      local launch_cwd="${global_cwd:-current}"
      local wid
      wid=$(kitty @ launch \
        --location="$loc" \
        --bias="${p_split_bias[$pname]}" \
        --type=window \
        --cwd="$launch_cwd" 2>/dev/null) || true
      _register_pane "$pname" "$wid"
    fi
  done

  # ── phase 3: populate each pane ──────────────────────────────
  for pname in "${pane_list[@]}"; do
    local cmd="${p_cmd[$pname]:-}"
    [[ -z "$cmd" ]] && continue
    local wid="${PANE_WIN_ID[$pname]}"
    _send "$cmd" "$wid"
  done

  # leave focus on first pane
  [[ ${#pane_list[@]} -gt 0 ]] && _focus_pane "${pane_list[0]}"
}

# ── preset discovery ─────────────────────────────────────────────

_find_preset() {
  local name="$1"
  for dir in "${KSPLIT_CONF_DIRS[@]}"; do
    [[ -z "$dir" ]] && continue
    local f="$dir/${name}.ksconf"
    [[ -f "$f" ]] && { echo "$f"; return 0; }
  done
  return 1
}

_list_presets() {
  echo ""
  echo "  Preset search paths:"
  for dir in "${KSPLIT_CONF_DIRS[@]}"; do
    [[ -z "$dir" ]] && continue
    printf "    %s\n" "$dir"
  done
  echo ""
  echo "  Available presets:"
  local found=0
  for dir in "${KSPLIT_CONF_DIRS[@]}"; do
    [[ -z "$dir" || ! -d "$dir" ]] && continue
    for f in "$dir"/*.ksconf; do
      [[ -f "$f" ]] || continue
      printf "    %-24s  %s\n" "$(basename "$f" .ksconf)" "$f"
      found=1
    done
  done
  (( found )) || echo "    (none found)"
  echo ""
  echo "  Usage:  ksplit <preset> [--cwd /path]"
  echo ""
}

_usage() {
  echo ""
  echo "  ksplit — kitty layout manager"
  echo ""
  echo "  ksplit <preset> [--cwd /path]   run a .ksconf preset"
  echo "  ksplit --list                   list available presets"
  echo "  ksplit --help                   show this help"
  echo ""
}

# ── entry point ──────────────────────────────────────────────────

main() {
  local preset="" cwd=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list|-l)  _list_presets; exit 0 ;;
      --help|-h)  _usage; exit 0 ;;
      --cwd|-c)   cwd="$2"; shift 2 ;;
      -*)         echo "Unknown option: $1"; _usage; exit 1 ;;
      *)          preset="$1"; shift ;;
    esac
  done

  if [[ -z "$preset" ]]; then
    echo "  Error: no preset specified."
    _list_presets; exit 1
  fi

  local file
  if ! file="$(_find_preset "$preset")"; then
    echo "  Error: preset '$preset' not found."
    _list_presets; exit 1
  fi

  echo "  → Running preset '$preset'  ($file)"
  _run_preset_file "$file" "$cwd"
}

main "$@"
