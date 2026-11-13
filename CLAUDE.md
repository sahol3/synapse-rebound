# haven-dhaka

Game project (Godot 4.7.2, GDScript; optional Ren'Py 8.5.3 visual-novel track; releases on itch.io).

Read in this order: `RULES.md` (tools, paths, versions, GDScript rules, build + itch.io flow) → top of `LEDGER.md` → `git status`.
Toolchain check: `powershell -ExecutionPolicy Bypass -File scripts\verify_toolchain.ps1` (expects `VERDICT: ALL PASS`).
MCP servers: `.mcp.json` here (godot, godot-editor, filesystem, git). Details and probe results in RULES.md section 3.
Deploy: there is no web deploy; itch.io pushes go through butler and only when the operator asks (RULES.md section 8).
