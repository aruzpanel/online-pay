#!/usr/bin/env bash
# Builds Paycue (server + CLI in Docker for linux/amd64, web UI with npm)
# on this machine and ships the artifacts to the VPS. Nothing is compiled on
# the server — a Go build needs more RAM than the VPS has.
# Usage: bash deploy.sh
set -euo pipefail
cd "$(dirname "$0")"

HOST="ubuntu@185.196.215.165"
# Git Bash reports the cwd as /c/Users/... — the form Docker Desktop mounts.
DOCKER_SRC="$(pwd)"

echo "==> go build (Docker, linux/amd64)"
MSYS_NO_PATHCONV=1 docker run --rm -v "$DOCKER_SRC:/src" -w /src golang:1.24-bookworm bash /src/build-linux.sh >/dev/null

echo "==> web UI build"
(cd web && npm ci --silent && npm run build >/dev/null)

echo "==> upload"
tar -czf /tmp/paycue-web-dist.tgz -C web/dist .
scp -o BatchMode=yes -q bin/paycue-linux bin/paycue-cli-linux /tmp/paycue-web-dist.tgz "$HOST:/tmp/"
rm -f /tmp/paycue-web-dist.tgz

echo "==> install + restart"
ssh -o BatchMode=yes "$HOST" "set -e
  sudo cp /opt/paycue/paycue /opt/paycue/paycue.prev
  sudo install -m 755 /tmp/paycue-linux /opt/paycue/paycue
  sudo install -m 755 /tmp/paycue-cli-linux /usr/local/bin/paycue-cli
  sudo rm -rf /opt/paycue/web.new && sudo mkdir -p /opt/paycue/web.new
  sudo tar -xzf /tmp/paycue-web-dist.tgz -C /opt/paycue/web.new
  sudo rm -rf /opt/paycue/web && sudo mv /opt/paycue/web.new /opt/paycue/web
  rm -f /tmp/paycue-linux /tmp/paycue-cli-linux /tmp/paycue-web-dist.tgz
  sudo systemctl restart paycue && sleep 4
  if systemctl is-active paycue >/dev/null; then echo 'paycue: active'; else
    echo 'paycue FAILED, rolling back'; sudo mv /opt/paycue/paycue.prev /opt/paycue/paycue; sudo systemctl restart paycue; exit 1; fi"

echo "==> smoke test"
echo "https://pay.danatpay.uz/health/ -> $(curl -s -m 15 https://pay.danatpay.uz/health/)"
