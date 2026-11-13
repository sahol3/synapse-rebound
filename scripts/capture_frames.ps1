# Records PNG frames of the game with Godot's movie writer for visual review.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\capture_frames.ps1 -Tag before
# Output: tools\_frames\<tag>\<shot>\f########.png (gitignored scratch).
param([string]$Tag = 'shot', [int]$Fps = 30)
$root = 'D:\CLAUDE-CODE\haven-dhaka'
$godot = "$root\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) { $godot = "$root\tools\bin\godot.cmd" }
$shots = @(
  @{ name = 'menu';   scene = '';                           user = @();              frames = 75 },
  @{ name = 'stage1'; scene = '';                           user = @('--stage=1');   frames = 150 },
  @{ name = 'stage2'; scene = '';                           user = @('--stage=2');   frames = 150 },
  @{ name = 'stage3'; scene = '';                           user = @('--stage=3');   frames = 120 },
  @{ name = 'stage4'; scene = '';                           user = @('--stage=4');   frames = 210 },
  @{ name = 'mech';   scene = 'res://tests/MechTest.tscn';  user = @();              frames = 2400 }
)
foreach ($s in $shots) {
  $dir = "$root\tools\_frames\$Tag\$($s.name)"
  New-Item -ItemType Directory -Force $dir | Out-Null
  Get-ChildItem $dir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force
  $args = @('--path', "$root\game", '--write-movie', "$dir\f.png", '--fixed-fps', "$Fps", '--quit-after', "$($s.frames)", '--resolution', '1152x648')
  if ($s.scene) { $args += $s.scene }
  if ($s.user.Count -gt 0) { $args += '--'; $args += $s.user }
  $p = Start-Process -FilePath $godot -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$dir\out.txt" -RedirectStandardError "$dir\err.txt"
  $n = (Get-ChildItem $dir -Filter *.png).Count
  Write-Output ("{0,-8} exit={1} frames={2}" -f $s.name, $p.ExitCode, $n)
}
