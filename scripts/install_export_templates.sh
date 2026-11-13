#!/usr/bin/env bash
# Downloads Godot 4.7.2 standard export templates (~1.28 GB) and installs them where the editor looks.
# Re-run safe: skips if the version.txt already matches.
set -euo pipefail
VER="4.7.2"
DEST="/c/Users/Sahol/AppData/Roaming/Godot/export_templates/${VER}.stable"
TMP="/d/CLAUDE-CODE/haven-dhaka/tools/_dl"
if [ -f "$DEST/version.txt" ] && grep -q "${VER}.stable" "$DEST/version.txt"; then echo "templates already installed at $DEST"; exit 0; fi
mkdir -p "$TMP" "$DEST"
# --retry + -C - resumes after the connection resets seen on 2026-11-13 (curl 56)
curl -sS -L --fail --retry 10 --retry-all-errors --retry-delay 5 -C - -o "$TMP/templates.tpz" "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_export_templates.tpz"
cd "$TMP" && rm -rf templates && unzip -q templates.tpz
cp -r templates/* "$DEST/"
rm -rf "$TMP"
echo "installed:"; cat "$DEST/version.txt"; ls "$DEST" | wc -l
