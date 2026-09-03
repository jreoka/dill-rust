#!/bin/bash
set -e

echo "Checking for Rust update..."
steamcmd +force_install_dir "$SERVER_DIR" +login anonymous +app_update 258550 validate +quit

IDENTITY_DIR="$SERVER_DIR/server/rust"
SEED_FILE="$IDENTITY_DIR/current_seed.txt"

# Random seed on first launch / wipe if +server.seed not set in compose.yaml
if [[ "$*" != *"+server.seed"* ]]; then
  if [ -f "$SEED_FILE" ]; then
    SEED=$(cat "$SEED_FILE")
    echo "[Rust] Using existing seed: $SEED"
  else
    SEED=$(shuf -i 1-2147483647 -n 1 2>/dev/null || echo $(( ( RANDOM << 15 | RANDOM ) % 2147483647 + 1 )))
    mkdir -p "$IDENTITY_DIR"
    echo "$SEED" > "$SEED_FILE"
    echo "[Rust] Wipe detected - generated random seed: $SEED"
  fi
  set -- "$@" +server.seed "$SEED"
fi

echo "Starting RustDedicated with args: $@"
exec "$SERVER_DIR/RustDedicated" -batchmode -nographics "$@"