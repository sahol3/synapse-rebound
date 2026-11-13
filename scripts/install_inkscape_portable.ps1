# Inkscape 1.4.4 as a portable folder on D: (admin-extract of the official MSI; the normal install fails with 1603 while C: is full).
$d = 'D:\CLAUDE-CODE\haven-dhaka\tools'
$msi = "$d\_ink\inkscape.msi"
if (-not (Test-Path $msi)) {
  New-Item -ItemType Directory -Force "$d\_ink" | Out-Null
  Invoke-WebRequest 'https://media.inkscape.org/dl/resources/file/inkscape-1.4.4_2026-05-05_dcaf3e7-x64.signed_xMx7DJV.msi' -OutFile $msi -UseBasicParsing
}
for ($i = 1; $i -le 40; $i++) {
  $p = Start-Process msiexec.exe -ArgumentList '/a', "`"$msi`"", '/qn', "TARGETDIR=`"$d\inkscape`"" -Wait -PassThru
  if ($p.ExitCode -eq 0) { break }
  Write-Output "attempt $i exit $($p.ExitCode)"
  Start-Sleep 30
}
$exe = Get-ChildItem "$d\inkscape" -Recurse -Filter inkscape.com -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($exe) { Remove-Item -Recurse -Force "$d\_ink"; Remove-Item "$d\inkscape\*.msi" -ErrorAction SilentlyContinue; Write-Output "INKSCAPE_OK $exe"; & $exe --version } else { Write-Output 'INKSCAPE_FAIL' }
