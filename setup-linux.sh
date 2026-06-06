#!/bin/bash
# VS Code C++ GDB One-Click Setup v2.0 — Linux
set -e

# ── ANSI colors ──────────────────────────────────────
r='\033[91m'; g='\033[92m'; y='\033[93m'; b='\033[96m'
m='\033[95m'; w='\033[97m'; dim='\033[90m'; bo='\033[1m'
rst='\033[0m'

ok()  { echo -e "  ${g}OK${rst}  $*"; }
wrn() { echo -e "  ${y}!!${rst}  $*"; }
bad() { echo -e "  ${r}FAIL${rst} $*"; }

tw() {
    local t="$1"; local d="${2:-12}"
    for ((i=0; i<${#t}; i++)); do
        echo -n "${t:$i:1}"; sleep "0.0$d" 2>/dev/null || sleep 0.02
    done
}

spin() {
    local msg="$1"; local sec="${2:-2}"; local n=$((sec * 12))
    local s=('|' '/' '-' '\')
    for ((i=0; i<n; i++)); do
        echo -ne "\r  ${dim}$msg ${s[$((i%4))]}${rst}  "
        sleep 0.085
    done
    printf "\r%*s\r" $(( ${#msg} + 8 )) ""
}

section() {
    echo ""
    echo -e "  ${bo}${b}>>  $*${rst}"
    printf "  ${dim}%0.s-" {1..48}
    echo -e "${rst}"
}

bar() {
    local pct=$1; local w=${2:-28}
    local n=$((pct * w / 100)); local u=$((w - n))
    printf "\r  ${b}%*s${dim}%*s${rst}  %3d%% " "$n" "$(printf '#%.0s' $(seq 1 $n))" "$u" "$(printf '.%.0s' $(seq 1 $u))" "$pct"
}

# ══════════════════════════════════════════════════════
clear
echo ""
echo -e "${dim}  +-------------------------------------------------------+${rst}"
echo -e "${dim}  |${rst}                                                       ${dim}|${rst}"
echo -e "${dim}  |${rst}   ${bo}${y}V${w}S ${g}C${w}ode ${b}C++ ${m}GDB${rst}  --  ${w}One-Click Setup v2.0${rst}        ${dim}|${rst}"
echo -e "${dim}  |${rst}                                                       ${dim}|${rst}"
echo -e "${dim}  +-------------------------------------------------------+${rst}"
echo ""
tw "  ${dim}Initializing...${rst}" 18
echo ""

# ══════════════════════════════════════════════════════
section "PRE-FLIGHT"

# Detect package manager
PKG=""
for pm in apt dnf pacman zypper; do
    command -v $pm &>/dev/null && { PKG=$pm; break; }
done
if [ -z "$PKG" ]; then
    bad "No supported package manager found (apt/dnf/pacman/zypper)"
    echo "  Install g++ and gdb manually then re-run."
    exit 1
fi
ok "Package manager: $PKG"

# ══════════════════════════════════════════════════════
section "SCAN"

need_install=true
need_gdb_only=false

for ((i=0; i<=100; i+=4)); do bar $i; sleep 0.02; done
bar 100; sleep 0.1; echo ""

if command -v gdb &>/dev/null && command -v g++ &>/dev/null; then
    echo ""
    echo -e "  ${g}  +----------------------------------------+${rst}"
    echo -e "  ${g}  |  ALL COMPONENTS ALREADY INSTALLED     |${rst}"
    echo -e "  ${g}  +----------------------------------------+${rst}"
    echo ""
    need_install=false
elif command -v g++ &>/dev/null; then
    wrn "GCC found -- installing GDB only"
    need_gdb_only=true
else
    echo -e "  ${dim}Starting fresh installation...${rst}"
fi

# ══════════════════════════════════════════════════════
if $need_install; then
    section "INSTALL GCC + GDB"
    echo -e "  ${dim}Installing build-essential + gdb ...${rst}"
    echo ""

    case $PKG in
        apt)
            spin "Updating package lists" 4
            sudo apt update -qq
            spin "Installing GCC + GDB" 6
            sudo apt install -y build-essential gdb
            ;;
        dnf)
            spin "Installing GCC + GDB" 6
            sudo dnf install -y gcc-c++ gdb make
            ;;
        pacman)
            spin "Installing GCC + GDB" 6
            sudo pacman -S --noconfirm gcc gdb make
            ;;
        zypper)
            spin "Installing GCC + GDB" 6
            sudo zypper install -y gcc-c++ gdb make
            ;;
    esac
    ok "GCC + GDB installed"
fi

if $need_gdb_only; then
    section "INSTALL GDB"
    spin "Installing GDB" 5
    case $PKG in
        apt) sudo apt install -y gdb ;;
        dnf) sudo dnf install -y gdb ;;
        pacman) sudo pacman -S --noconfirm gdb ;;
        zypper) sudo zypper install -y gdb ;;
    esac
    ok "GDB installed"
fi

# ══════════════════════════════════════════════════════
section "VERIFY"

gdb_ok=false; gcc_ok=false
gdb_ver=$(gdb --version 2>/dev/null | head -1) && gdb_ok=true || true
gcc_ver=$(g++ --version 2>/dev/null | head -1) && gcc_ok=true || true

if $gdb_ok; then
    echo -e "  ${w}GDB${rst} : ${g}$gdb_ver${rst}"
else
    echo -e "  ${w}GDB${rst} : ${r}NOT FOUND${rst}"
fi

if $gcc_ok; then
    echo -e "  ${w}GCC${rst} : ${g}$gcc_ver${rst}"
else
    echo -e "  ${w}GCC${rst} : ${r}NOT FOUND${rst}"
fi

# ══════════════════════════════════════════════════════
section "VS CODE EXTENSION"

if command -v code &>/dev/null; then
    code --install-extension ms-vscode.cpptools --force &>/dev/null
    ok "C++ extension installed"
else
    wrn "VS Code CLI not found -- install 'C/C++' extension manually"
fi

# ══════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$SCRIPT_DIR/.vscode"

cat > "$SCRIPT_DIR/.vscode/launch.json" << 'LAUNCH'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "(gdb) Launch",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/${fileBasenameNoExtension}",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb",
            "setupCommands": [
                { "description": "Enable pretty-printing", "text": "-enable-pretty-printing", "ignoreFailures": true },
                { "description": "Set Disassembly Flavor to Intel", "text": "-gdb-set disassembly-flavor intel", "ignoreFailures": true }
            ],
            "preLaunchTask": "g++ build"
        }
    ]
}
LAUNCH

cat > "$SCRIPT_DIR/.vscode/tasks.json" << 'TASKS'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "g++ build",
            "type": "shell",
            "command": "g++",
            "args": ["-g", "-O0", "${file}", "-o", "${workspaceFolder}/${fileBasenameNoExtension}"],
            "group": { "kind": "build", "isDefault": true },
            "presentation": { "reveal": "always", "panel": "shared" },
            "problemMatcher": ["$gcc"]
        }
    ]
}
TASKS
ok "Config files generated"

# ══════════════════════════════════════════════════════
echo ""
echo -e "${g}  +--------------------------------------------------------+${rst}"
echo -e "${g}  |${rst}                                                        ${g}|${rst}"
echo -e "${g}  |${rst}   ${bo}${w}SETUP COMPLETE${rst}                                        ${g}|${rst}"
echo -e "${g}  |${rst}                                                        ${g}|${rst}"
echo -e "${g}  |${rst}   ${w}Open folder${rst} -> ${w}open .cpp${rst} -> ${y}${bo}F5${rst}                                ${g}|${rst}"
echo -e "${g}  |${rst}                                                        ${g}|${rst}"
echo -e "${g}  +--------------------------------------------------------+${rst}"
echo ""

if $gdb_ok; then echo -e "  ${dim}GDB : $gdb_ver${rst}"; fi
if $gcc_ok; then echo -e "  ${dim}GCC : $gcc_ver${rst}"; fi
echo ""

# celebration
cols=("$r" "$y" "$g" "$m" "$b")
for ((i=0; i<15; i++)); do
    dots=$(printf '.%.0s' $(seq 1 $((i%3+1))))
    echo -ne "\r     ${cols[$((i%5))]}$dots${rst}   "
    sleep 0.06
done
echo -e "\r          "
echo ""
echo -e "  ${dim}If verification failed, restart then F5.${rst}"
echo ""
