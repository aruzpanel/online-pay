#!/usr/bin/env bash
# Builds onlinepay + onlinepay-cli for linux/amd64 (CGO for sqlite). Run inside golang:1.24-bookworm.
set -euo pipefail
export CGO_ENABLED=1 GOFLAGS=-buildvcs=false
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq gcc libc6-dev >/dev/null 2>&1
mkdir -p bin
go build -trimpath -ldflags='-s -w' -o bin/onlinepay-linux ./cmd/onlinepay
go build -trimpath -ldflags='-s -w' -o bin/onlinepay-cli-linux ./cmd/onlinepay-cli
ls -la bin/
