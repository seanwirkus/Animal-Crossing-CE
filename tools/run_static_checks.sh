#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v stylua >/dev/null 2>&1; then
    echo "stylua not found in PATH. Run 'aftman install' first." >&2
    exit 1
fi

if ! command -v selene >/dev/null 2>&1; then
    echo "selene not found in PATH. Run 'aftman install' first." >&2
    exit 1
fi

if ! command -v luau-lsp >/dev/null 2>&1; then
    echo "luau-lsp not found in PATH. Run 'aftman install' first." >&2
    exit 1
fi

if ! command -v rojo >/dev/null 2>&1; then
    echo "rojo not found in PATH. Run 'aftman install' first." >&2
    exit 1
fi

# 1. Formatting check
stylua --check src ReplicatedStorage

# 2. Linting with Selene (Roblox standard)
selene src ReplicatedStorage

# 3. Luau static analysis (uses generated sourcemap for context)
luau-lsp analyze \
    --sourcemap=sourcemap.json \
    --definitions=.luaurc \
    src

# 4. Validate RemoteEvent manifests
python3 tools/validate_remotes.py

# 5. Ensure project builds cleanly
rojo build -o "build-lint.rbxl"

echo "All static checks completed successfully."
