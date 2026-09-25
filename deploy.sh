#!/usr/bin/env bash
# Builds Online Pay (server + CLI in Docker for linux/amd64, web UI with npm)
# on this machine and ships the artifacts to the VPS. Nothing is compiled on
# the server — a Go build needs more RAM than the VPS has.
# Usage: bash deploy.sh
set -euo pipefail
cd "$(dirname "$0")"

HOST="ubuntu@185.196.215.165"
# The live install predates the rename and still sits under its old name.
# The new binary goes into that same place, so the service, its .env, the
# database and the Telegram session all carry on untouched.
REMOTE_DIR="/opt/paycue"
SERVICE="paycue"
# Git Bash reports the cwd as /c/Users/... — the form Docker Desktop mounts.
DOCKER_SRC="$(pwd)"

echo "==> go build (Docker, linux/amd64)"
MSYS_NO_PATHCONV=1 docker run --rm -v "$DOCKER_SRC:/src" -w /src golang:1.24-bookworm bash /src/build-linux.sh >/dev/null

echo "==> web UI build"
(cd web && npm ci --silent && npm run build >/dev/null)

echo "==> upload"
tar -czf /tmp/onlinepay-web-dist.tgz -C web/dist .
scp -o BatchMode=yes -q bin/onlinepay-linux bin/onlinepay-cli-linux /tmp/onlinepay-web-dist.tgz "$HOST:/tmp/"
rm -f /tmp/onlinepay-web-dist.tgz

echo "==> install + restart"
ssh -o BatchMode=yes "$HOST" "set -e
  sudo cp $REMOTE_DIR/$SERVICE $REMOTE_DIR/$SERVICE.prev
  sudo install -m 755 /tmp/onlinepay-linux $REMOTE_DIR/$SERVICE
  sudo install -m 755 /tmp/onlinepay-cli-linux /usr/local/bin/onlinepay-cli
  sudo rm -f /usr/local/bin/paycue-cli
  sudo rm -rf $REMOTE_DIR/web.new && sudo mkdir -p $REMOTE_DIR/web.new
  sudo tar -xzf /tmp/onlinepay-web-dist.tgz -C $REMOTE_DIR/web.new
  sudo rm -rf $REMOTE_DIR/web && sudo mv $REMOTE_DIR/web.new $REMOTE_DIR/web
  rm -f /tmp/onlinepay-linux /tmp/onlinepay-cli-linux /tmp/onlinepay-web-dist.tgz
  sudo systemctl restart $SERVICE && sleep 4
  if systemctl is-active $SERVICE >/dev/null; then echo 'online pay: active'; else
    echo 'online pay FAILED, rolling back'; sudo mv $REMOTE_DIR/$SERVICE.prev $REMOTE_DIR/$SERVICE; sudo systemctl restart $SERVICE; exit 1; fi"

echo "==> smoke test"
echo "https://pay.danatpay.uz/health/ -> $(curl -s -m 15 https://pay.danatpay.uz/health/)"
