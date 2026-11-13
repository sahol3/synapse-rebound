# Tiled 1.12.2 as a portable folder (admin-extract of the official MSI, no elevation, nothing on C:).
# Retries while another Windows Installer session holds the lock (exit 1618).
$d = 'D:\CLAUDE-CODE\haven-dhaka\tools'
$msi = "$d\_tiled\tiled.msi"
if (-not (Test-Path $msi)) {
  New-Item -ItemType Directory -Force "$d\_tiled" | Out-Null
  Invoke-WebRequest 'https://github.com/mapeditor/tiled/releases/download/v1.12.2/Tiled-1.12.2_Windows-10%2B_x86_64.msi' -OutFile $msi -UseBasicParsing
}
for ($i = 1; $i -le 40; $i++) {
  $p = Start-Process msiexec.exe -ArgumentList '/a', "`"$msi`"", '/qn', "TARGETDIR=`"$d\tiled`"" -Wait -PassThru
  if ($p.ExitCode -eq 0) { break }
  Write-Output "attempt $i exit $($p.ExitCode)"
  Start-Sleep 30
}
$exe = Get-ChildItem "$d\tiled" -Recurse -Filter tiled.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($exe) { Remove-Item -Recurse -Force "$d\_tiled"; Remove-Item "$d\tiled\*.msi" -ErrorAction SilentlyContinue; Write-Output "TILED_OK $exe" } else { Write-Output 'TILED_FAIL' }
