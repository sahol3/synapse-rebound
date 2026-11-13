# Records the menu and stages at several window sizes with Godot's movie writer, to check that
# the game fills any window (no bars) with whole-number pixel scales.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\capture_sizes.ps1 [-Tag sizes]
# Output: tools\_frames\<tag>\<WxH>\<shot>\f########.png (gitignored scratch).
# Then:   py scripts\check_sizes.py <tag>
param([string]$Tag = 'sizes', [int]$Fps = 30)
$root = 'D:\CLAUDE-CODE\haven-dhaka'
$godot = "$root\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) { $godot = "$root\tools\bin\godot.cmd" }
$sizes = @('1152x648', '1366x768', '1920x1080', '1024x768', '960x540', '2560x1080')
$shots = @(
  @{ name = 'menu';   user = @();            frames = 60 },
  @{ name = 'stage1'; user = @('--stage=1'); frames = 150 },
  @{ name = 'stage3'; user = @('--stage=3'); frames = 120 }
)
foreach ($size in $sizes) {
  foreach ($s in $shots) {
    $dir = "$root\tools\_frames\$Tag\$size\$($s.name)"
    New-Item -ItemType Directory -Force $dir | Out-Null
    Get-ChildItem $dir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force
    $a = @('--path', "$root\game", '--write-movie', "$dir\f.png", '--fixed-fps', "$Fps", '--quit-after', "$($s.frames)", '--resolution', $size)
    if ($s.user.Count -gt 0) { $a += '--'; $a += $s.user }
    $p = Start-Process -FilePath $godot -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$dir\out.txt" -RedirectStandardError "$dir\err.txt"
    $n = (Get-ChildItem $dir -Filter *.png).Count
    Write-Output ("{0,-10} {1,-7} exit={2} frames={3}" -f $size, $s.name, $p.ExitCode, $n)
  }
}
