# =============================================================================
# 墨香书阁 (InkFiction) — Windows 11 全自动启动脚本
# 用法: .\start.ps1
# 首次运行请先执行: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# =============================================================================
param(
    [switch]$NoInstall,
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host @"

墨香书阁 全自动启动脚本

用法: .\start.ps1 [选项]

选项:
    -NoInstall      跳过依赖安装（二次启动更快）
    -BackendOnly    只启动 Django 后端 (http://127.0.0.1:8000)
    -FrontendOnly   只启动 Vue 前端 (http://127.0.0.1:5173)
    -Help           显示此帮助

首次运行: 脚本会自动创建虚拟环境、安装依赖、迁移数据库
后续运行: .\start.ps1 -NoInstall  跳过安装，直接启动

环境要求:
    Python 3.10+   https://www.python.org/downloads/
    Node.js 18+    https://nodejs.org/
"@
    exit 0
}

$ErrorActionPreference = "Stop"

# =============================================================================
# 路径
# =============================================================================
$ROOT     = $PSScriptRoot
$BACKEND  = Join-Path $ROOT "novel_backend"
$FRONTEND = Join-Path $ROOT "novel_frontend"
$VENV     = Join-Path $BACKEND ".venv"
$PYTHON   = "python"

# =============================================================================
# 控制台输出
# =============================================================================
function info($s) { Write-Host "[*] $s" -ForegroundColor Cyan }
function ok($s)   { Write-Host "[+] $s" -ForegroundColor Green }
function warn($s) { Write-Host "[!] $s" -ForegroundColor Yellow }
function fail($s) { Write-Host "[x] $s" -ForegroundColor Red; exit 1 }

# =============================================================================
# 1. 环境检查
# =============================================================================
info "检查运行环境..."

try { $v = & python --version 2>&1; ok "Python $v" }
catch { fail "未检测到 Python，请安装 Python 3.10+ 并添加到 PATH" }

try { $v = & node --version 2>&1; ok "Node.js $v" }
catch { fail "未检测到 Node.js，请安装 Node.js 18+ 并添加到 PATH" }

# =============================================================================
# 2. 虚拟环境
# =============================================================================
if (-not $FrontendOnly) {
    if (-not (Test-Path $VENV)) {
        info "创建虚拟环境 (.venv)..."
        & python -m venv $VENV
        if ($LASTEXITCODE -ne 0) { fail "虚拟环境创建失败" }
        ok "虚拟环境创建完成"
    }
    $PYTHON = Join-Path $VENV "Scripts\python.exe"
    ok "虚拟环境: $VENV"
}

# =============================================================================
# 3. 后端依赖
# =============================================================================
if (-not $FrontendOnly -and -not $NoInstall) {
    info "安装后端依赖 (pip)..."
    & $PYTHON -m pip install --upgrade pip -q 2>$null
    & $PYTHON -m pip install -r (Join-Path $BACKEND "requirements.txt") -q
    if ($LASTEXITCODE -ne 0) { fail "pip install 失败，请检查网络连接" }
    ok "后端依赖安装完成"
}

# =============================================================================
# 4. 前端依赖
# =============================================================================
if (-not $BackendOnly -and -not $NoInstall) {
    if (-not (Test-Path (Join-Path $FRONTEND "node_modules"))) {
        info "安装前端依赖 (npm)..."
        Push-Location $FRONTEND
        & npm install --silent 2>$null
        if ($LASTEXITCODE -ne 0) { Pop-Location; fail "npm install 失败，请检查网络连接" }
        Pop-Location
        ok "前端依赖安装完成"
    } else {
        ok "前端依赖已存在，跳过安装"
    }
}

# =============================================================================
# 5. 数据库迁移
# =============================================================================
if (-not $FrontendOnly) {
    info "数据库迁移..."
    Push-Location $BACKEND
    & $PYTHON manage.py migrate --run-syncdb 2>&1 | Out-Null
    Pop-Location
    ok "数据库已就绪 (SQLite3)"
}

# =============================================================================
# 6. 启动服务（独立窗口）
# =============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  墨香书阁 开发服务器" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
if (-not $FrontendOnly) { Write-Host "  后端 API : http://127.0.0.1:8000" -ForegroundColor Cyan }
if (-not $BackendOnly) { Write-Host "  前端页面 : http://127.0.0.1:5173" -ForegroundColor Cyan }
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

if (-not $FrontendOnly) {
    $backendCmd = "`$host.UI.RawUI.WindowTitle = 'InkFiction - 后端 :8000'; cd '$BACKEND'; & '$PYTHON' manage.py runserver 0.0.0.0:8000; pause"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
    Start-Sleep 2
    ok "Django 后端已启动（新窗口）"
}

if (-not $BackendOnly) {
    $frontendCmd = "`$host.UI.RawUI.WindowTitle = 'InkFiction - 前端 :5173'; cd '$FRONTEND'; npm run dev; pause"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
    Start-Sleep 3
    ok "Vue 前端已启动（新窗口）"
}

Write-Host ""
info "关闭后端/前端窗口即可停止服务。"
info "首次启动后端窗口可能需要几秒编译。"