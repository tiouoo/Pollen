#!/usr/bin/env bash
set -euo pipefail
command -v git >/dev/null || { echo 'Error: Git is required.' >&2; exit 1; }
command -v perl >/dev/null || { echo 'Error: Perl (with Encode) is required.' >&2; exit 1; }
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec perl "$SCRIPT_DIR/normalize-lf.pl"
