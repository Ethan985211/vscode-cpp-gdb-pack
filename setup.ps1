# VS Code C++ GDB One-Click Setup v2.0
$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "VS Code C++ GDB Setup"
[Console]::CursorVisible = $false

$e  = [char]27
$r  = "$e[91m"; $g  = "$e[92m"; $y  = "$e[93m"
$b  = "$e[96m"; $m  = "$e[95m"; $w  = "$e[97m"
$dim= "$e[90m"; $bo = "$e[1m";  $rst = "$e[0m"

function ok   { Write-Host "  ${g}OK${rst}  $args" }
function wrn  { Write-Host "  ${y}!!${rst}  $args" }
function bad  { Write-Host "  ${r}FAIL${rst} $args" }

function tw([string]$t, [int]$d=12) {
    foreach ($c in $t.ToCharArray()) { Write-Host -NoNewline $c; Start-Sleep -Milliseconds $d }
}

function spin([string]$msg, [int]$sec=2) {
    $s = @('|','/','-','\'); $n = $sec * 12
    for ($i=0; $i -lt $n; $i++) { Write-Host "`r  ${dim}$msg $($s[$i%4])${rst}" -NoNewline; Start-Sleep -Milliseconds 85 }
    Write-Host "`r$(' ' * ($msg.Length + 5))`r" -NoNewline
}

function bar([int]$pct, [int]$w=28) {
    $n = [Math]::Floor($pct * $w / 100); $u = $w - $n
    Write-Host "`r  ${b}$([string]::new('#',$n))${dim}$([string]::new('.',$u))${rst}  $pct% " -NoNewline
}

function section([string]$t) {
    Write-Host ""
    Write-Host "  ${bo}${b}>>  $t${rst}"
    Write-Host "  ${dim}$([string]::new('-',48))${rst}"
}

# ============================================================
Clear-Host
Write-Host ""
Write-Host "${dim}  +-------------------------------------------------------+${rst}"
Write-Host "${dim}  |${rst}                                                       ${dim}|${rst}"
Write-Host "${dim}  |${rst}   ${bo}${y}V${w}S ${g}C${w}ode ${b}C++ ${m}GDB${rst}  --  ${w}One-Click Setup v2.0${rst}        ${dim}|${rst}"
Write-Host "${dim}  |${rst}                                                       ${dim}|${rst}"
Write-Host "${dim}  +-------------------------------------------------------+${rst}"
Write-Host ""
tw "  ${dim}Initializing...${rst}" 18
Write-Host ""

# ============================================================
section "PRE-FLIGHT"

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($admin) { ok "Administrator" } else { wrn "Not Admin -- right-click -> Run as Admin" }

if (-not (Test-Path $env:TEMP)) { mkdir $env:TEMP -Force | Out-Null }
if (-not (Test-Path "C:\msys64")) { mkdir "C:\msys64" -Force | Out-Null }
ok "Directories"

# ============================================================
section "SCAN"

$gdbBin = "C:\msys64\ucrt64\bin\gdb.exe"
$gccBin = "C:\msys64\ucrt64\bin\g++.exe"
$doInstall = $true
$doGdbOnly = $false

for ($i=0; $i -le 100; $i+=3) { bar $i; Start-Sleep -Milliseconds 16 }
bar 100; Start-Sleep -Milliseconds 100; Write-Host ""

if ((Test-Path $gdbBin) -and (Test-Path $gccBin)) {
    Write-Host ""
    Write-Host "  ${g}  +----------------------------------------+${rst}"
    Write-Host "  ${g}  |  ALL COMPONENTS ALREADY INSTALLED     |${rst}"
    Write-Host "  ${g}  +----------------------------------------+${rst}"
    Write-Host ""
    $doInstall = $false
}
elseif (Test-Path $gccBin) {
    wrn "GCC found -- installing GDB only"
    $doGdbOnly = $true
}
else {
    Write-Host "  ${dim}Starting fresh installation...${rst}"
}

# ============================================================
# DOWNLOAD
# ============================================================
if ($doInstall) {
    section "DOWNLOAD"
    $url = "https://repo.msys2.org/distrib/msys2-x86_64-latest.exe"
    $dl  = "$env:TEMP\msys2-setup.exe"

    if ((Test-Path $dl) -and ((Get-Item $dl).Length -gt 80000000)) {
        ok "Cached $([Math]::Round((Get-Item $dl).Length/1MB,1)) MB"
    }
    else {
        Write-Host "  ${w}MSYS2 Installer${rst}  ${dim}(~90 MB)${rst}"
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $dl
            ok "Downloaded $([Math]::Round((Get-Item $dl).Length/1MB,1)) MB"
        }
        catch {
            bad "Download failed -- check network"
            [Console]::CursorVisible = $true; pause; exit 1
        }
    }

    # ============================================================
    # INSTALL MSYS2
    # ============================================================
    section "INSTALL MSYS2"
    Write-Host "  ${dim}Target: C:\msys64  (~320 MB)${rst}"
    Remove-Item "C:\msys64\var\lib\pacman\db.lck" -Force -ErrorAction SilentlyContinue
    spin "Installing MSYS2" 3

    try {
        & $dl install --root C:/msys64 --confirm-command 2>&1 | Out-Null
        ok "MSYS2 installed"
    }
    catch {
        wrn "Retrying..."
        Remove-Item "C:\msys64" -Recurse -Force -ErrorAction SilentlyContinue
        mkdir "C:\msys64" -Force | Out-Null
        try {
            & $dl install --root C:/msys64 --confirm-command 2>&1 | Out-Null
            ok "MSYS2 installed"
        }
        catch {
            bad "Install failed -- try rebooting"
            [Console]::CursorVisible = $true; pause; exit 1
        }
    }
}

# ============================================================
# INSTALL GDB
# ============================================================
if ($doInstall -or $doGdbOnly) {
    section "INSTALL GDB"
    $pkgs = @(
        "C:\msys64\var\lib\pacman",
        "C:\msys64\var\cache\pacman\pkg",
        "C:\msys64\var\log",
        "C:\msys64\tmp"
    )
    foreach ($d in $pkgs) {
        if (-not (Test-Path $d)) { mkdir $d -Force | Out-Null }
    }
    Remove-Item "C:\msys64\var\lib\pacman\db.lck" -Force -ErrorAction SilentlyContinue

    $ok = $false
    for ($t=1; $t -le 2; $t++) {
        spin "Installing GDB (attempt $t/2)" 4
        & C:\msys64\usr\bin\pacman.exe --noconfirm --disable-download-timeout -S mingw-w64-ucrt-x86_64-gdb 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $ok = $true; break }
        Remove-Item "C:\msys64\var\lib\pacman\db.lck" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $gdbBin) { ok "GDB" } else { bad "GDB failed" }
}

# ============================================================
# INSTALL GCC
# ============================================================
if ($doInstall) {
    section "INSTALL GCC"
    Remove-Item "C:\msys64\var\lib\pacman\db.lck" -Force -ErrorAction SilentlyContinue

    $ok = $false
    for ($t=1; $t -le 2; $t++) {
        spin "Installing GCC (attempt $t/2)" 4
        & C:\msys64\usr\bin\pacman.exe --noconfirm --disable-download-timeout -S mingw-w64-ucrt-x86_64-gcc 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $ok = $true; break }
        Remove-Item "C:\msys64\var\lib\pacman\db.lck" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $gccBin) { ok "GCC" } else { bad "GCC failed" }
}

# ============================================================
# CONFIGURE PATH
# ============================================================
section "CONFIGURE PATH"

$bin = "C:\msys64\ucrt64\bin"
$old = [Environment]::GetEnvironmentVariable("Path","User")
if ($old -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path","$bin;$old","User")
    ok "PATH updated"
}
else {
    ok "PATH already set"
}
$env:Path = "$bin;$env:Path"

# ============================================================
# VERIFY
# ============================================================
section "VERIFY"

$gdbOut = & gdb.exe --version 2>&1; $gdbOk = $?
$gccOut = & g++.exe --version 2>&1; $gccOk = $?

$gdbLine = if ($gdbOk) { "${g}$($gdbOut[0])${rst}" } else { "${r}NOT FOUND${rst}" }
$gccLine = if ($gccOk) { "${g}$($gccOut[0])${rst}" } else { "${r}NOT FOUND${rst}" }
Write-Host "  ${w}GDB${rst} : $gdbLine"
Write-Host "  ${w}GCC${rst} : $gccLine"

# ============================================================
# VS CODE EXTENSION
# ============================================================
section "VS CODE EXTENSION"

$vscode = Get-Command code -ErrorAction SilentlyContinue

if (-not $vscode) {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd",
        "D:\Microsoft VS Code\bin\code.cmd",
        "C:\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { $vscode = $p; break }
    }
}

if (-not $vscode) {
    # search entire file system (drives C-Z, depth 3, for VS Code\bin\code.cmd)
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
    foreach ($drive in $drives) {
        $found = Get-ChildItem -Path $drive.Root -Filter "code.cmd" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -like "*VS Code*" } |
                 Select-Object -First 1
        if ($found) { $vscode = $found.FullName; break }
    }
}

if (-not $vscode) {
    try {
        $item = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*VS Code*" } |
                Select-Object -First 1
        if ($item -and $item.InstallLocation) {
            $c = Join-Path $item.InstallLocation "bin\code.cmd"
            if (Test-Path $c) { $vscode = $c }
        }
    }
    catch { }
}

if ($vscode) {
    & $vscode --install-extension ms-vscode.cpptools --force 2>&1 | Out-Null
    ok "C++ extension installed"
}
else {
    wrn "VS Code not found -- install 'C/C++' extension manually"
}

# ============================================================
# FINALE
# ============================================================
Write-Host ""
Write-Host "${g}  +--------------------------------------------------------+${rst}"
Write-Host "${g}  |${rst}                                                        ${g}|${rst}"
Write-Host "${g}  |${rst}   ${bo}${w}SETUP COMPLETE${rst}                                        ${g}|${rst}"
Write-Host "${g}  |${rst}                                                        ${g}|${rst}"
Write-Host "${g}  |${rst}   ${w}Open folder${rst} -> ${w}open .cpp${rst} -> ${y}${bo}F5${rst}                                ${g}|${rst}"
Write-Host "${g}  |${rst}                                                        ${g}|${rst}"
Write-Host "${g}  +--------------------------------------------------------+${rst}"
Write-Host ""

if ($gdbOk) { Write-Host "  ${dim}GDB : $($gdbOut[0].Trim())${rst}" }
if ($gccOk) { Write-Host "  ${dim}GCC : $($gccOut[0].Trim())${rst}" }
Write-Host "  ${dim}PATH: C:\msys64\ucrt64\bin${rst}"
Write-Host ""

# celebration
$cols = @($r, $y, $g, $m, $b)
for ($i = 0; $i -lt 15; $i++) {
    Write-Host "`r     ${cols[$i%5]}$('.' * ($i % 3 + 1))${rst}   " -NoNewline
    Start-Sleep -Milliseconds 60
}
Write-Host "`r          "
Write-Host ""
Write-Host "  ${dim}If verification failed, restart PC then F5.${rst}"
Write-Host ""

[Console]::CursorVisible = $true
pause
