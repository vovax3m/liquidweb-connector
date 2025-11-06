#!/bin/bash

source   ~/.lwc/config

set -euo pipefail

function connect {
        ssh "$SSH_USER"@$1 -i "$SSH_KEY_PATH" $SSH_PARAMS
}

function call {
    USER=$1
    PASS=$2
    curl -sS -u "$USER:$PASS" \
          -H 'Content-Type: application/json' \
          -X POST https://api.liquidweb.com/v3/asset/list  \
          -d '{"params":{"page_size":1000, "alsowith":["osFamily","networkSummary"]}}' | \
        jq '.items[] | select (.osFamily == "linux") |"\(.uniq_id)\t\(.custom_name)\t\(.domain)\t\(.ip)"' -r  | \
        column -t
    
}

function refresh_cache {
    echo "🔄 Refreshing cache..."
    (call "$LW_USER_ONE" "$LW_PASS_ONE" 2>/dev/null | grep -v '^<' >"$LW_ONE_FILE" || true) &
    (call "$LW_USER_TWO" "$LW_PASS_TWO" 2>/dev/null | grep -v '^<' >"$LW_TWO_FILE" || true)
    wait
    echo "✅ Cache refreshed"
}

function check_dependencies {
    for cmd in fzf awk jq column; do
      command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing dependency: $cmd"; exit 1; }
    done
}

function main {
# --- Check required tools ---
check_dependencies

# --- Preload data (cache for fast switching) ---
LW_ONE_FILE="/tmp/lwc_cache_one.txt"
LW_TWO_FILE="/tmp/lwc_cache_two.txt"

# Load from cache if exists, otherwise fetch fresh data
if [[ ! -f "$LW_ONE_FILE" || ! -f "$LW_TWO_FILE" ]]; then
    echo "🔄 Loading server data..."
    (call "$LW_USER_ONE" "$LW_PASS_ONE" 2>/dev/null | grep -v '^<' >"$LW_ONE_FILE" || true) &
    (call "$LW_USER_TWO" "$LW_PASS_TWO" 2>/dev/null | grep -v '^<' >"$LW_TWO_FILE" || true)
    wait
    echo "✅ Cache updated"
else
    echo "📁 Using cached data (press R to refresh)"
fi

if [[ ! -s "$LW_ONE_FILE" && ! -s "$LW_TWO_FILE" ]]; then
  echo "⚠️  No hosts found."
  exit 0
fi

current="lwone"
TMPFILE=$(mktemp)
cp "$LW_ONE_FILE" "$TMPFILE"

while true; do
#  echo
  echo "🔹 [$current]  ↑↓ move • TAB switch • ENTER connect • ~ refresh • ESC quit"
#  echo

  # inline
  { read -r key; read -r sel; } <<<"$(fzf \
    --height=20 \
    --border=rounded \
    --inline-info \
    --prompt="[$current] > " \
    --expect=enter,tab,esc,~ \
    --no-preview \
    <"$TMPFILE")"

  # --- ESC pressed ---
  [[ "$key" == "esc" ]] && { echo "👋 Exit."; break; }

  # --- ~ pressed (refresh cache) ---
  if [[ "$key" == "~" ]]; then
    refresh_cache
    # Reload current file into tmpfile
    if [[ "$current" == "lwone" ]]; then
      cp "$LW_ONE_FILE" "$TMPFILE"
    else
      cp "$LW_TWO_FILE" "$TMPFILE"
    fi
    continue
  fi

  # --- TAB pressed (toggle list) ---
  if [[ "$key" == "tab" ]]; then
    if [[ "$current" == "lwone" ]]; then
      current="lwtwo"
      cp "$LW_TWO_FILE" "$TMPFILE"
    else
      current="lwone"
      cp "$LW_ONE_FILE" "$TMPFILE"
    fi
    continue
  fi

  # --- ENTER pressed on valid line ---
  if [[ "$key" == "enter" && -n "${sel:-}" ]]; then
    # allow typing 'exit' or 'quit'
    if [[ "$sel" =~ ^(exit|quit)$ ]]; then
      echo "👋 Bye."
      break
    fi

    IP=$(echo "$sel" | awk '{print $NF}')
    if [[ ! "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "❌ No IP found in: $sel"
      continue
    fi

    echo
    echo "➡️  Connecting to $IP ..."
    connect "$IP"
    break
  fi
done

rm -f "$TMPFILE"
}

main