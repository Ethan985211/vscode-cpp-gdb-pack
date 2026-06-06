# VS Code C++ Debug — Portable Pack

Windows / Linux / macOS 三平台一键调试环境。

## 快速开始

| 平台 | 第一步 | 第二步 | 第三步 |
|------|--------|--------|--------|
| **Windows** | 双击 `setup.bat` | 重启 VS Code | 打开文件夹 → 打开 .cpp → F5 |
| **Linux** | `bash setup-linux.sh` | 重启 VS Code | 打开文件夹 → 打开 .cpp → F5 |
| **macOS** | `bash setup-mac.sh` | 重启 VS Code | 打开文件夹 → 打开 .cpp → F5 |

## 安装内容

| | Windows | Linux | macOS |
|---|---------|-------|-------|
| 编译器 | GCC 16 (MSYS2) | g++ (apt/dnf/pacman) | clang++ (Xcode) |
| 调试器 | GDB 17 | GDB | LLDB |
| 扩展 | ms-vscode.cpptools | ms-vscode.cpptools | ms-vscode.cpptools |

## 文件结构

```
├── setup.bat              Windows 安装脚本（动画版）
├── setup.ps1              Windows PowerShell 脚本
├── setup-linux.sh         Linux 安装脚本（动画版）
├── setup-mac.sh           macOS 安装脚本（动画版）
├── .vscode/               自动生成，无需手动修改
│   ├── launch.json        调试配置
│   └── tasks.json         编译任务
├── demo.cpp               示例代码
└── README.md              本说明文档
```

## 日常使用

1. VS Code → 打开文件夹 → 选本目录
2. 打开 `.cpp` 文件
3. 按 **F5** → 自动编译 + 启动调试

## 调试快捷键

| 按键 | 功能 |
|------|------|
| **F5** | 编译 + 启动调试 |
| **F9** | 当前行切换断点 |
| **F10** | 逐行跳过 |
| **F11** | 进入函数 |
| **Shift+F11** | 跳出函数 |
| **Ctrl+Shift+B** | 仅编译 |

## 平台注意事项

**Windows**
- 源文件名请用英文（GDB 不支持中文路径，如 `洛谷.cpp` 会报错）
- 代码末尾加 `system("pause");` 防止控制台一闪而过
- `externalConsole: true` 使用独立控制台窗口

**Linux**
- 自动检测 apt / dnf / pacman / zypper 包管理器
- 输出显示在 VS Code 内置终端（`externalConsole: false`）
- 首次使用需 `chmod +x setup-linux.sh`

**macOS**
- 使用 LLDB 调试器（免代码签名，开箱即用）
- 首次运行会弹出 Xcode CLI Tools 安装窗口，点击"安装"后等待完成
- 调试快捷键与 GDB 一致，无需额外学习
- 首次使用需 `chmod +x setup-mac.sh`

## 常见问题

| 现象 | 原因 | 解决 |
|------|------|------|
| `xxx.exe does not exist` | 编译失败或文件名含中文 | Ctrl+S 保存 → 确认文件名英文 → 再 F5 |
| 改了代码结果没变 | 旧进程锁定 exe，编译静默失败 | 关闭上次调试窗口 → 再 F5 |
| 窗口一闪而过 (Win) | 程序执行完自动退出 | `main()` 末尾加 `system("pause");` |
| GDB / LLDB 未找到 | PATH 未生效 | 重启电脑 → 重运行 setup 脚本 |
| 断点灰色不生效 | 编译时没加 `-g` | 检查 tasks.json 中是否包含 `-g` |
| Linux/Mac 权限拒绝 | `.sh` 缺少执行权限 | `chmod +x setup-*.sh` |
| macOS 无法验证开发者 | Gatekeeper 拦截 | 系统设置 → 隐私与安全性 → 仍要打开 |
