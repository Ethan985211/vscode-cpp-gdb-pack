#!/bin/bash
# VS Code C++ LLDB One-Click Setup v2.0 — macOS
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
echo -e "${dim}  |${rst}   ${bo}${y}V${w}S ${g}C${w}ode ${b}C++ ${m}LLDB${rst}  --  ${w}One-Click Setup v2.0${rst}       ${dim}|${rst}"
echo -e "${dim}  |${rst}                                                       ${dim}|${rst}"
echo -e "${dim}  +-------------------------------------------------------+${rst}"
echo ""
tw "  ${dim}Initializing...${rst}" 18
echo ""

# ══════════════════════════════════════════════════════
section "PRE-FLIGHT"

# Check macOS
if [ "$(uname)" != "Darwin" ]; then
    bad "This script is for macOS only."
    exit 1
fi
ok "macOS detected"

# ══════════════════════════════════════════════════════
section "SCAN"

need_install=true

for ((i=0; i<=100; i+=4)); do bar $i; sleep 0.02; done
bar 100; sleep 0.1; echo ""

if command -v clang++ &>/dev/null && command -v lldb &>/dev/null; then
    echo ""
    echo -e "  ${g}  +----------------------------------------+${rst}"
    echo -e "  ${g}  |  ALL COMPONENTS ALREADY INSTALLED     |${rst}"
    echo -e "  ${g}  +----------------------------------------+${rst}"
    echo ""
    need_install=false
else
    echo -e "  ${dim}Starting installation...${rst}"
fi

# ══════════════════════════════════════════════════════
if $need_install; then
    section "INSTALL XCODE CLI TOOLS"

    if xcode-select -p &>/dev/null; then
        ok "Xcode CLI tools already installed"
    else
        echo -e "  ${w}Installing Xcode Command Line Tools...${rst}"
        echo -e "  ${dim}(A dialog may appear -- click 'Install' then wait)${rst}"
        echo ""
        xcode-select --install 2>/dev/null || true

        spin "Waiting for installation" 8
        # Wait up to 5 minutes for install to complete
        for ((i=0; i<30; i++)); do
            if xcode-select -p &>/dev/null; then break; fi
            sleep 10
        done

        if xcode-select -p &>/dev/null; then
            ok "Xcode CLI tools installed"
        else
            bad "Installation timed out -- try again or install manually"
            exit 1
        fi
    fi
fi

# ══════════════════════════════════════════════════════
section "VERIFY"

clang_ok=false; lldb_ok=false
clang_ver=$(clang++ --version 2>/dev/null | head -1) && clang_ok=true || true
lldb_ver=$(lldb --version 2>/dev/null | head -1) && lldb_ok=true || true

if $clang_ok; then
    echo -e "  ${w}clang++${rst} : ${g}$clang_ver${rst}"
else
    echo -e "  ${w}clang++${rst} : ${r}NOT FOUND${rst}"
fi

if $lldb_ok; then
    echo -e "  ${w}LLDB${rst}   : ${g}$lldb_ver${rst}"
else
    echo -e "  ${w}LLDB${rst}   : ${r}NOT FOUND${rst}"
fi

# ══════════════════════════════════════════════════════
section "VS CODE EXTENSION"

if command -v code &>/dev/null; then
    code --install-extension ms-vscode.cpptools --force &>/dev/null
    ok "C++ extension installed"
else
    # Check common macOS VS Code location
    if [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
        ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
        "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" --install-extension ms-vscode.cpptools --force &>/dev/null
        ok "C++ extension installed"
    else
        wrn "VS Code not found -- install 'C/C++' extension manually"
    fi
fi

# ══════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$SCRIPT_DIR/.vscode"

cat > "$SCRIPT_DIR/.vscode/launch.json" << 'LAUNCH'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "(lldb) Launch",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/${fileBasenameNoExtension}",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "lldb",
            "miDebuggerPath": "/usr/bin/lldb",
            "preLaunchTask": "clang++ build"
        }
    ]
}
LAUNCH

cat > "$SCRIPT_DIR/.vscode/tasks.json" << 'TASKS'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "clang++ build",
            "type": "shell",
            "command": "clang++",
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

if $clang_ok; then echo -e "  ${dim}clang++ : $clang_ver${rst}"; fi
if $lldb_ok;  then echo -e "  ${dim}LLDB    : $lldb_ver${rst}"; fi
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
echo -e "  ${dim}Note: macOS uses LLDB (not GDB) -- no code signing needed.${rst}"
echo ""
