# Takes one screenshot of the menu and stages in a real window at several sizes, to check that
# the game fills any window (no bars) with whole-number pixel scales.
# The movie writer cannot do this: it always records the design size (1152x648) whatever the window.
# The game saves the shot itself (Display.gd, `-- --shot=<abs.png> --shot-frame=N`) and quits.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\capture_sizes.ps1 [-Tag sizes]
# Output: tools\_frames\<tag>\<WxH>\<shot>\shot.png (gitignored scratch).
# Then:   py scripts\check_sizes.py <tag>
# A size larger than the monitor is clamped by Windows; check_sizes reports it as SIZE-WRONG.
param([string]$Tag = 'sizes')
$root = 'D:\CLAUDE-CODE\haven-dhaka'
$godot = "$root\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) { $godot = "$root\tools\bin\godot.cmd" }
$sizes = @('1152x648', '1366x768', '1600x900', '1024x768', '960x540', '1800x720')
$shots = @(
  @{ name = 'menu';   user = @();            frame = 90 },
  @{ name = 'stage1'; user = @('--stage=1'); frame = 200 },
  @{ name = 'stage3'; user = @('--stage=3'); frame = 200 }
)
foreach ($size in $sizes) {
  foreach ($s in $shots) {
    $dir = "$root\tools\_frames\$Tag\$size\$($s.name)"
    New-Item -ItemType Directory -Force $dir | Out-Null
    Get-ChildItem $dir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force
    $a = @('--path', "$root\game", '--windowed', '--resolution', $size, '--', "--shot=$dir\shot.png", "--shot-frame=$($s.frame)")
    $a += $s.user
    $p = Start-Process -FilePath $godot -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$dir\out.txt" -RedirectStandardError "$dir\err.txt"
    $n = (Get-ChildItem $dir -Filter *.png).Count
    Write-Output ("{0,-10} {1,-7} exit={2} shots={3}" -f $size, $s.name, $p.ExitCode, $n)
  }
}
