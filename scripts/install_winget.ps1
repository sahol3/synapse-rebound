# Haven Dhaka toolchain: winget installs. Idempotent; re-run safe.
# Usage: powershell -ExecutionPolicy Bypass -File D:\CLAUDE-CODE\haven-dhaka\scripts\install_winget.ps1
$ids = @(
  'GodotEngine.GodotEngine',   # Godot 4 standard (GDScript)
  'RenPy.RenPySDK',            # Ren'Py SDK (visual novel engine)
  'ItchIo.Itch',               # itch.io desktop app
  # LibreSprite is not on winget: portable v1.3 zip from GitHub lives in tools\libresprite
  'Tiled.Tiled',           # tilemaps
  'Inkscape.Inkscape',         # vector / UI
  'Audacity.Audacity',         # audio edit
  'Gyan.FFmpeg',               # audio/video conversion
  'Git.Git',
  'astral-sh.uv'
)
foreach ($id in $ids) {
  $have = winget list --id $id -e --accept-source-agreements 2>$null | Select-String -SimpleMatch $id
  if ($have) { Write-Output "SKIP $id (installed)"; continue }
  Write-Output "INSTALL $id"
  winget install --id $id -e --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
  Write-Output "EXIT $id = $LASTEXITCODE"
}
