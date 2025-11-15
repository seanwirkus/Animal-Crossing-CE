#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v luau-lsp >/dev/null 2>&1; then
    echo "luau-lsp not found in PATH. Run 'aftman install' or install via https://github.com/luau-lang/luau-lsp." >&2
    exit 1
fi

if ! command -v rojo >/dev/null 2>&1; then
    echo "rojo not found in PATH. Run 'aftman install' first." >&2
    exit 1
fi

TARGETS=()
for path in src ReplicatedStorage; do
    if [ -d "$path" ]; then
        TARGETS+=("$path")
    fi
done

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No Lua/Luau source directories detected (expected src/ or ReplicatedStorage/)." >&2
    exit 1
fi

SOURCEMAP="$PROJECT_ROOT/sourcemap.json"
if [ ! -f "$SOURCEMAP" ]; then
    if [ -f "$PROJECT_ROOT/default.project.json" ]; then
        echo "Generating sourcemap.json via Rojo..."
        rojo sourcemap default.project.json --output "$SOURCEMAP"
    else
        echo "Missing sourcemap.json and default.project.json; run 'rojo sourcemap' manually." >&2
        exit 1
    fi
fi

echo "Running luau-lsp analyze on: ${TARGETS[*]}"
luau-lsp analyze --sourcemap "$SOURCEMAP" "${TARGETS[@]}"

