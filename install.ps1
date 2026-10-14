# ============================================================================
#  dsh-config-backup · 一键恢复脚本（Windows）
# ----------------------------------------------------------------------------
#  作用：把本仓库的 DSH 全家桶配置恢复到当前 PC 的 ~/.dsh
#  包含：插件清单、profile 配置、agent-presets、skills、
#        jt-startup / boot-animation / status-rotator 配置
#  用法： 1) 安装 DSH（DeepSeek Harness Desktop 或 dsh CLI）
#         2) clone 本仓库  git clone https://github.com/levent-JT/dsh-config-backup
#         3) 以 PowerShell 运行  .\install.ps1
#         4) 重启 DSH
# ============================================================================

$ErrorActionPreference = 'Stop'
$Repo = $PSScriptRoot
$DSH_HOME = $env:DSH_HOME
if (-not $DSH_HOME) { $DSH_HOME = Join-Path $env:USERPROFILE '.dsh' }

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  dsh-config-backup 全家桶恢复" -ForegroundColor Cyan
Write-Host "  仓库: $Repo" -ForegroundColor DarkGray
Write-Host "  目标: $DSH_HOME" -ForegroundColor DarkGray
Write-Host "==============================================" -ForegroundColor Cyan

# ---------- 0) 前置检查 ----------
if (-not (Test-Path $DSH_HOME)) { New-Item -ItemType Directory -Force -Path $DSH_HOME | Out-Null }
$dshCmd = Get-Command dsh -ErrorAction SilentlyContinue
if (-not $dshCmd) {
    Write-Host "[!] 未找到 dsh 命令。请先安装 DeepSeek Harness Desktop 或 npm i -g @deepseek-ai/dsh" -ForegroundColor Yellow
    Write-Host "    安装后重跑本脚本。" -ForegroundColor Yellow
    exit 1
}

# ---------- 1) 配置文件 ----------
function Copy-Config([string]$rel) {
    $dst = Join-Path $DSH_HOME $rel
    $full = Join-Path $Repo "config\$rel"
    if (Test-Path $full) {
        $parent = Split-Path $dst -Parent
        if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        Copy-Item $full $dst -Recurse -Force
        Write-Host "  [配置] $rel" -ForegroundColor Green
    }
}

Write-Host "`n[1/4] 恢复配置文件..." -ForegroundColor Cyan
# profile 配置（package.json 只作为插件清单参考，插件本体由 dsh plugin add 安装）
Copy-Config 'profiles/desktop/cordis.yml'
Copy-Config 'profiles/desktop/cordis.patch.yml'
Copy-Config 'profiles/desktop/pnpm-workspace.yaml'
# 插件私有配置
Copy-Config 'boot-animation/selection.json'
Copy-Config 'status-rotator'
Copy-Config '.agent-presets'

# ---------- 2) 插件 ----------
Write-Host "`n[2/4] 安装插件..." -ForegroundColor Cyan
# 从备份的 package.json 解析插件清单
$pkgPath = Join-Path $Repo 'config/desktop/package.json'
$gitPlugins = @(
    # name -> source（github 或特殊源，独立于 npm registry）
    'dsh-ritual-startup' , 'github:levent-JT/dsh-ritual-animation'
)
if (Test-Path $pkgPath) {
    $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
    $deps = $pkg.dependencies
    foreach ($prop in $deps.PSObject.Properties) {
        $name = $prop.Name
        $spec = $prop.Value
        # 跳过宿主本体、本地路径（file:）、已在 git 源表里的
        if ($name -like '@deepseek-ai/*') { continue }
        if ($spec -like 'file:*') { continue }
        if ($gitPlugins -contains $name) { continue }
        Write-Host "  [插件] $name" -ForegroundColor Green
        dsh plugin --profile desktop add $name 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "    !! 安装失败: $name" -ForegroundColor Red }
    }
}
# 特殊源插件（git 仓库）
Write-Host "  [插件] $($gitPlugins[0])  ← git: $($gitPlugins[1])" -ForegroundColor Green
dsh plugin --profile desktop add $gitPlugins[1] 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "    !! 安装失败: $($gitPlugins[0])" -ForegroundColor Red }

# ---------- 3) Skills ----------
Write-Host "`n[3/4] 恢复全局 skills..." -ForegroundColor Cyan
$skillsSrc = Join-Path $Repo 'skills'
if (Test-Path $skillsSrc) {
    $skillsDst = Join-Path $DSH_HOME 'skills'
    if (-not (Test-Path $skillsDst)) { New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null }
    Get-ChildItem $skillsSrc -Directory | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $skillsDst $_.Name) -Recurse -Force
        Write-Host "  [skill] $($_.Name)" -ForegroundColor Green
    }
}

# ---------- 4) 完成 ----------
Write-Host "`n[4/4] 完成！" -ForegroundColor Cyan
Write-Host "  请重启 DSH（桌面端完全退出再打开；web 端重启 dsh 进程 + Ctrl+Shift+R 硬刷新）。"
Write-Host "  启动动画：DSH 设置页 → 启动动画"
Write-Host "  若本机是私有环境，需在 ~/.dsh/.credentials.yaml 重新配置登录凭据。"
