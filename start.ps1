# =============================================================================
# InkFiction 全自动启动脚本 (Windows 11 / PowerShell)
# 一键启动 Django 后端 + Vue 前端开发服务器
# =============================================================================
param(
    [switch]$NoInstall,     # 跳过依赖安装
    [switch]$BackendOnly,   # 只启动后端
    [switch]$FrontendOnly,  # 只启动前端
    [switch]$Help           # 显示帮助
)

if ($Help) {
    @"
用法: .\start.ps1 [选项]

选项:
    -NoInstall      跳过 pip/npm 依赖安装
    -BackendOnly    只启动 Django 后端
    -FrontendOnly   只启动 Vue 前端
    -Help           显示此帮助

示例:
    .\start.ps1                    # 完整启动（打开两个窗口）
    .\start.ps1 -NoInstall         # 跳过安装，直接启动
    .\start.ps1 -BackendOnly       # 仅启动后端

环境要求:
    Python 3.10+   https://python.org
    Node.js 18+    https://nodejs.org
"@ | Write-Host
    exit 0
}

# =============================================================================
# 路径配置
# =============================================================================
$ROOT_DIR     = $PSScriptRoot
$BACKEND_DIR  = Join-Path $ROOT_DIR "novel_backend"
$FRONTEND_DIR = Join-Path $ROOT_DIR "novel_frontend"
$VENV_DIR     = Join-Path $BACKEND_DIR ".venv"
$PYTHON       = "python"
$BACKEND_PORT = 8000
$FRONTEND_PORT = 5173

# 颜色输出
function Write-Info    ($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Success ($msg) { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn    ($msg) { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Error   ($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# =============================================================================
# 1. 环境检查
# =============================================================================
Write-Info "检查环境..."

$pyVersion = & $PYTHON --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Python 未安装或未添加到 PATH。请先安装 Python 3.10+"
    exit 1
}
Write-Success "Python: $pyVersion"

$nodeVersion = & node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Node.js 未安装或未添加到 PATH。请先安装 Node.js 18+"
    exit 1
}
Write-Success "Node.js: $nodeVersion"

# =============================================================================
# 2. 虚拟环境
# =============================================================================
if (-not $FrontendOnly) {
    if (-not (Test-Path $VENV_DIR)) {
        Write-Info "创建 Python 虚拟环境..."
        & $PYTHON -m venv $VENV_DIR
        if ($LASTEXITCODE -ne 0) { Write-Error "创建虚拟环境失败"; exit 1 }
    }
    $PYTHON = Join-Path $VENV_DIR "Scripts\python.exe"
    Write-Success "虚拟环境: $VENV_DIR"
}

# =============================================================================
# 3. 安装后端依赖
# =============================================================================
if (-not $FrontendOnly -and -not $NoInstall) {
    Write-Info "安装后端依赖 (pip)..."
    & $PYTHON -m pip install -r (Join-Path $BACKEND_DIR "requirements.txt") -q
    if ($LASTEXITCODE -ne 0) { Write-Error "pip install 失败"; exit 1 }
    Write-Success "后端依赖安装完成"
}

# =============================================================================
# 4. 安装前端依赖
# =============================================================================
if (-not $BackendOnly -and -not $NoInstall) {
    Write-Info "安装前端依赖 (npm)..."
    Push-Location $FRONTEND_DIR
    & npm install --silent 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Error "npm install 失败"; Pop-Location; exit 1 }
    Pop-Location
    Write-Success "前端依赖安装完成"
}

# =============================================================================
# 5. 数据库迁移
# =============================================================================
if (-not $FrontendOnly) {
    Write-Info "检查数据库迁移..."
    Push-Location $BACKEND_DIR
    & $PYTHON manage.py migrate --run-syncdb 2>$null | Out-Null
    Pop-Location
    Write-Success "数据库已就绪"
}

# =============================================================================
# 6. 启动服务
# =============================================================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  InkFiction 开发服务器即将启动" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

if (-not $FrontendOnly) {
    Write-Host "  后端: http://127.0.0.1:$BACKEND_PORT" -ForegroundColor Cyan
}
if (-not $BackendOnly) {
    Write-Host "  前端: http://127.0.0.1:$FRONTEND_PORT" -ForegroundColor Cyan
}
Write-Host "========================================`n" -ForegroundColor Magenta

# 启动后端（独立窗口）
if (-not $FrontendOnly) {
    $backendCmd = "`$host.UI.RawUI.WindowTitle = 'InkFiction - Django 后端'; cd '$BACKEND_DIR'; & '$PYTHON' manage.py runserver 0.0.0.0:$BACKEND_PORT; Read-Host '按回车键关闭'"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
    Start-Sleep -Seconds 2
    Write-Success "Django 后端已启动"
}

# 启动前端（独立窗口）
if (-not $BackendOnly) {
    $frontendCmd = "`$host.UI.RawUI.WindowTitle = 'InkFiction - Vue 前端'; cd '$FRONTEND_DIR'; npm run dev; Read-Host '按回车键关闭'"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
    Start-Sleep -Seconds 3
    Write-Success "Vue 前端已启动"
}

Write-Info "关闭对应的 PowerShell 窗口即可停止服务。"
