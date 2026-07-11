# =============================================================================
# 墨香书阁 (InkFiction) — Windows 11 全自动启动脚本
# 用法: .\start.ps1 [-NoInstall] [-BackendOnly] [-FrontendOnly] [-Help]
# 首次运行: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# =============================================================================
param(
    [switch]$NoInstall,
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host ""
    Write-Host "墨香书阁 全自动启动脚本" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法: .\start.ps1 [选项]"
    Write-Host ""
    Write-Host "  -NoInstall      跳过依赖安装"
    Write-Host "  -BackendOnly    只启动后端 http://127.0.0.1:8000"
    Write-Host "  -FrontendOnly   只启动前端 http://127.0.0.1:5173"
    Write-Host "  -Help           显示帮助"
    Write-Host ""
    exit 0
}

# =============================================================================
# 路径
# =============================================================================
$ROOT     = $PSScriptRoot
$BACKEND  = Join-Path $ROOT "novel_backend"
$FRONTEND = Join-Path $ROOT "novel_frontend"
$VENV     = Join-Path $BACKEND ".venv"
$PYTHON   = "python"

# =============================================================================
# 输出函数
# =============================================================================
function info($s) { Write-Host "[*] $s" -ForegroundColor Cyan }
function ok($s)   { Write-Host "[+] $s" -ForegroundColor Green }
function fail($s) { Write-Host "[x] $s" -ForegroundColor Red; exit 1 }

# =============================================================================
# 1. 环境检查
# =============================================================================
info "检查运行环境..."

$pyCheck = & python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    fail "未检测到 Python，请安装 Python 3.10+ 并添加到 PATH"
}
ok "Python $pyCheck"

$nodeCheck = & node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    fail "未检测到 Node.js，请安装 Node.js 18+ 并添加到 PATH"
}
ok "Node.js $nodeCheck"

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
    & $PYTHON -m pip install --upgrade pip -q 2>&1 | Out-Null
    & $PYTHON -m pip install -r "$BACKEND\requirements-windows.txt" -q 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { fail "pip install 失败" }
    ok "后端依赖安装完成"
}

# =============================================================================
# 4. 前端依赖
# =============================================================================
if (-not $BackendOnly -and -not $NoInstall) {
    $nodeModules = Join-Path $FRONTEND "node_modules"
    if (Test-Path $nodeModules) {
        ok "前端依赖已存在，跳过安装"
    }
    if (-not (Test-Path $nodeModules)) {
        info "安装前端依赖 (npm)..."
        Push-Location $FRONTEND
        & npm install 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            fail "npm install 失败"
        }
        Pop-Location
        ok "前端依赖安装完成"
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
# 6. 启动服务
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
    $cmd = "`$host.UI.RawUI.WindowTitle = 'InkFiction - 后端'; cd '$BACKEND'; & '$PYTHON' manage.py runserver 0.0.0.0:8000; pause"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
    Start-Sleep -Seconds 2
    ok "Django 后端已启动"
}

if (-not $BackendOnly) {
    $cmd = "`$host.UI.RawUI.WindowTitle = 'InkFiction - 前端'; cd '$FRONTEND'; npm run dev; pause"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
    Start-Sleep -Seconds 3
    ok "Vue 前端已启动"
}

Write-Host ""
info "关闭窗口即可停止服务。"