#!/usr/bin/env bash
set -e

CONFIG_FILE="$HOME/.tunnelrc"
PID_DIR="$HOME/.tunnel-pids"
mkdir -p "$PID_DIR"

# Defaults
SAVED_PORT=""
SAVED_SERVER=""

# Load config if exists
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# -------------------------
# Helpers
# -------------------------
bold() { printf "\033[1m%s\033[0m\n" "$1"; }
dim() { printf "\033[2m%s\033[0m\n" "$1"; }
ask() { printf "\n\033[1m%s\033[0m\n" "$1"; }

usage() {
  cat <<EOF
Usage:
  tunnel.sh client|server [options]
  tunnel.sh kill
  tunnel.sh list

Options:
  -p <port>           Port to forward
  --server <user@h>   Middle-man SSH server
  -y                  Skip confirmation

Examples:
  tunnel.sh client -p 4200
  tunnel.sh server --server user@example.com -p 4200
EOF
  exit 1
}

# -------------------------
# Commands: list / kill
# -------------------------
if [[ "$1" == "list" ]]; then
  bold "Active tunnels:"
  if ls "$PID_DIR"/*.pid >/dev/null 2>&1; then
    for f in "$PID_DIR"/*.pid; do
      pid=$(cat "$f")
      name=$(basename "$f" .pid)
      if ps -p "$pid" >/dev/null 2>&1; then
        echo "• $name (PID $pid)"
      else
        echo "• $name (stale)"
      fi
    done
  else
    dim "No active tunnels."
  fi
  exit 0
fi

if [[ "$1" == "kill" ]]; then
  bold "Stopping tunnels..."
  if ls "$PID_DIR"/*.pid >/dev/null 2>&1; then
    for f in "$PID_DIR"/*.pid; do
      pid=$(cat "$f")
      name=$(basename "$f" .pid)
      if ps -p "$pid" >/dev/null 2>&1; then
        kill "$pid"
        echo "• Stopped $name (PID $pid)"
      fi
      rm -f "$f"
    done
  else
    dim "No tunnels running."
  fi
  exit 0
fi

# -------------------------
# Mode
# -------------------------
MODE="$1"
shift || true

if [[ "$MODE" != "client" && "$MODE" != "server" ]]; then
  usage
fi

PORT=""
SERVER=""
AUTO_YES=false

# -------------------------
# Parse args
# -------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      PORT="$2"
      shift 2
      ;;
    --server)
      SERVER="$2"
      shift 2
      ;;
    -y)
      AUTO_YES=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# -------------------------
# Interactive prompts
# -------------------------
ask "Tunnel configuration"

if [[ -z "$PORT" ]]; then
  read -rp "➤ Port to forward [${SAVED_PORT}]: " PORT
  PORT=${PORT:-$SAVED_PORT}
fi

if [[ -z "$PORT" ]]; then
  echo "Port is required."
  exit 1
fi

if [[ -z "$SERVER" ]]; then
  read -rp "➤ Middle-man server (user@host) [${SAVED_SERVER}]: " SERVER
  SERVER=${SERVER:-$SAVED_SERVER}
fi

if [[ -z "$SERVER" ]]; then
  echo "Server is required."
  exit 1
fi

# Save config
cat > "$CONFIG_FILE" <<EOF
SAVED_PORT="$PORT"
SAVED_SERVER="$SERVER"
EOF

# -------------------------
# Summary
# -------------------------
ask "Summary"
echo "Mode    : $MODE"
echo "Port    : $PORT"
echo "Server  : $SERVER"

if ! $AUTO_YES; then
  echo
  read -rp "Proceed? [y/N]: " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 0
fi

# -------------------------
# Start tunnel
# -------------------------
PID_FILE="$PID_DIR/${MODE}_${PORT}.pid"

if [[ "$MODE" == "server" ]]; then
  bold "Starting reverse tunnel..."
  ssh -N -R "${PORT}:localhost:${PORT}" "$SERVER" &
else
  bold "Starting local forward..."
  ssh -N -L "${PORT}:localhost:${PORT}" "$SERVER" &
fi

PID=$!
echo "$PID" > "$PID_FILE"

echo
bold "Tunnel running"
dim "PID: $PID"
dim "Use: tunnel.sh kill  or  tunnel.sh list"

