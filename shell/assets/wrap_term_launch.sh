#!/usr/bin/env sh

cat ~/.local/state/cxos/sequences.txt 2>/dev/null

exec "$@"
