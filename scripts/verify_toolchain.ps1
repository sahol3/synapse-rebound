# Haven Dhaka toolchain check. Prints one PASS/FAIL line per tool and a final verdict.
# Usage: powershell -ExecutionPolicy Bypass -File D:\CLAUDE-CODE\haven-dhaka\scripts\verify_toolchain.ps1
$root = 'D:\CLAUDE-CODE\haven-dhaka'
$fail = 0
function Check($name, [scriptblock]$probe, $expect) {
  try { $out = (& $probe 2>&1 | Out-String).Trim() } catch { $out = "ERR: $_" }
  $line = ($out -split "`n")[0]
  if ($out -match $expect) { Write-Output ("PASS  {0,-22} {1}" -f $name, $line) }
  else { $script:fail++; Write-Output ("FAIL  {0,-22} {1}" -f $name, $line) }
}
Check 'godot'            { & "$root\tools\bin\godot.cmd" --version } '4\.7\.2\.stable'
Check 'godot on D:'       { if ((Test-Path "$root\tools\godot\._sc_") -and (Test-Path "$root\tools\godot\Godot_v4.7.2-stable_win64.exe")) { 'self-contained Godot present on D:' } else { 'missing' } } 'present'
Check 'export templates' { Get-Content "$root\tools\godot\editor_data\export_templates\4.7.2.stable\version.txt" } '4\.7\.2\.stable'
Check 'web export'       { & "$root\tools\bin\godot.cmd" --headless --path "$root\game" --export-release "Web" "$root\exports\web\index.html" | Out-Null; if (Test-Path "$root\exports\web\index.wasm") { 'exports/web/index.wasm present' } else { 'missing' } } 'present'
Check 'game boots'       { $o = (& "$root\tools\bin\godot.cmd" --headless --path "$root\game" --quit-after 60 2>&1 | Out-String); if ($o -match 'SCRIPT ERROR|Parse Error') { ($o -split "`n" | Select-String 'ERROR' | Select-Object -First 1) } else { 'boot clean, no SCRIPT ERROR' } } 'boot clean'
Check 'renpy lint'       { $r = "$env:TEMP\hd_renpy_lint.txt"; Remove-Item $r -ErrorAction SilentlyContinue; Start-Process "$root\tools\renpy\renpy.exe" -ArgumentList 'the_question','lint',$r -WorkingDirectory "$root\tools\renpy" -Wait -WindowStyle Hidden; Get-Content $r -TotalCount 1 } 'Ren.Py 8\.5\.3'
Check 'butler'           { & "$root\tools\bin\butler.exe" -V } 'v15\.'
Check 'gdlint'           { & "$root\tools\bin\gdlint.cmd" --version } 'gdlint 4\.'
Check 'gdformat'         { & "$root\tools\bin\gdformat.cmd" --version } 'gdformat 4\.'
Check 'git mcp (venv)'   { if (Test-Path "$root\tools\pyenv\Scripts\mcp-server-git.exe") { 'mcp-server-git.exe present' } else { 'missing' } } 'present'
Check 'libresprite'      { if (Test-Path "$root\tools\libresprite\libresprite.exe") { 'libresprite.exe present' } else { 'missing' } } 'present'
Check 'tiled'            { $t = Get-ChildItem "$root\tools\tiled" -Recurse -Filter tiled.exe -ErrorAction SilentlyContinue | Select-Object -First 1; if ($t) { "tiled.exe present $($t.FullName)" } else { 'missing' } } 'present'
Check 'inkscape'         { $k = Get-ChildItem "$root\tools\inkscape" -Recurse -Filter inkscape.com -ErrorAction SilentlyContinue | Select-Object -First 1; if ($k) { & $k.FullName --version } else { 'missing' } } 'Inkscape 1\.'
Check 'audacity'         { winget list --id Audacity.Audacity -e } 'Audacity\.Audacity'
Check 'itch app on D:'   { if (Test-Path "$root\tools\itch-app\local\app-26.22.0\itch.exe") { 'itch.exe present on D:' } else { 'missing' } } 'present'
Check 'ffmpeg'           { ffmpeg -hide_banner -version } 'ffmpeg version'
Check 'node'             { node -v } '^v\d+'
Check 'uv'               { uv --version } '^uv '
Check 'git'              { git --version } 'git version'
Check 'godot-mcp build'  { if (Test-Path "$root\tools\godot-mcp\build\index.js") { 'build/index.js present' } else { 'missing' } } 'present'
Check 'editor-mcp build' { if (Test-Path "$root\tools\ee0pdt-godot-mcp\server\dist\index.js") { 'dist/index.js present' } else { 'missing' } } 'present'
Check 'godot docs'       { (Get-ChildItem "$root\refs\godot-docs\classes" -Filter *.rst).Count } '^\d{3,}'
if ($fail -eq 0) { Write-Output 'VERDICT: ALL PASS' } else { Write-Output "VERDICT: $fail FAIL" }
