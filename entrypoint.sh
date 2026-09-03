#!/bin/bash
set -e

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$SERVER_DIR/server/rust"
  chown -R rust:rust "$SERVER_DIR" /home/rust/Steam /home/rust/.steam 2>/dev/null || true
  chown -R rust:rust "$SERVER_DIR/server/rust" 2>/dev/null || true
  exec gosu rust "$0" "$@"
fi

echo "Checking for Rust update..."
steamcmd +force_install_dir "$SERVER_DIR" +login anonymous +app_update 258550 validate +quit

# Fix steamclient.so after every update
mkdir -p "$HOME/.steam/sdk64" "$HOME/.steam/sdk32"
ln -sf "$SERVER_DIR/steamclient.so" "$HOME/.steam/sdk64/steamclient.so"
ln -sf "$SERVER_DIR/steamclient.so" "$HOME/.steam/sdk32/steamclient.so"

IDENTITY_DIR="$SERVER_DIR/server/rust"
SEED_FILE="$IDENTITY_DIR/current_seed.txt"

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

cd "$SERVER_DIR"

echo "Starting RustDedicated with args: $@"
exec ./RustDedicated -batchmode -nographics "$@"