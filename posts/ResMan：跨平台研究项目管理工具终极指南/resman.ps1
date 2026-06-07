# =============================================================================
# 研究项目管理集成脚本 (Windows PowerShell版)
# 功能: Git同步、数据备份、日志记录、项目管理
# 作者: Maoye
# 日期: 2025-07-22
# 版本: Windows PowerShell 1.0.0
# =============================================================================

# 解析命令行参数
$Operation = ""
$ProjectName = ""

if ($args.Count -gt 0) {
    $Operation = $args[0]
}
if ($args.Count -gt 1) {
    $ProjectName = $args[1]
}

# 脚本配置
$SCRIPT_VERSION = "1.0.0"
# 配置文件路径
$CONFIG_FILE = "$env:USERPROFILE\.research_config.json"

# 初始化配置函数
function Initialize-Config {
    Write-Host "欢迎使用研究项目管理工具！" -ForegroundColor Green
    Write-Host "首次运行需要配置工作目录。" -ForegroundColor Yellow
    Write-Host ""
    
    # 获取研究根目录
    $defaultPath = "$env:USERPROFILE\research"
    $researchRoot = Read-Host "请输入研究项目根目录路径 (默认: $defaultPath)"
    if ([string]::IsNullOrWhiteSpace($researchRoot)) {
        $researchRoot = $defaultPath
    }
    
    # 创建目录（如果不存在）
    if (-not (Test-Path $researchRoot)) {
        try {
            New-Item -ItemType Directory -Path $researchRoot -Force | Out-Null
            Write-Host "已创建目录: $researchRoot" -ForegroundColor Green
        } catch {
            Write-Host "无法创建目录: $researchRoot，请检查权限。" -ForegroundColor Red
            exit 1
        }
    }
    
    # 获取备份目录
    $defaultBackupPath = "$researchRoot\_backup"
    $backupRoot = Read-Host "请输入备份目录路径 (默认: $defaultBackupPath)"
    if ([string]::IsNullOrWhiteSpace($backupRoot)) {
        $backupRoot = $defaultBackupPath
    }
    
    # 创建目录（如果不存在）
    if (-not (Test-Path $backupRoot)) {
        try {
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
            Write-Host "已创建备份目录: $backupRoot" -ForegroundColor Green
        } catch {
            Write-Host "无法创建备份目录: $backupRoot，请检查权限。" -ForegroundColor Red
            exit 1
        }
    }
    
    # 保存配置
    $config = @{
        RESEARCH_ROOT = $researchRoot
        BACKUP_ROOT = $backupRoot
        BACKUP_KEEP_DAYS = 30
        MAX_FILE_SIZE_MB = 100
        DEFAULT_REMOTE = "origin"
        LOG_LEVEL = "INFO"
        ENABLE_COLOR = $true
        GIT_AUTO_PUSH = $true
        CREATED_DATE = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    try {
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path $CONFIG_FILE -Encoding UTF8
        Write-Host "配置已保存到: $CONFIG_FILE" -ForegroundColor Green
        Write-Host "您可以随时编辑此文件来修改配置。" -ForegroundColor Cyan
        Write-Host ""
        return $config
    } catch {
        Write-Host "保存配置失败: $_" -ForegroundColor Red
        exit 1
    }
}

# 加载配置
function Load-Config {
    if (-not (Test-Path $CONFIG_FILE)) {
        return Initialize-Config
    }
    
    try {
        $config = Get-Content -Path $CONFIG_FILE -Encoding UTF8 | ConvertFrom-Json
        
        # 验证必要的配置项
        if (-not $config.RESEARCH_ROOT -or -not $config.BACKUP_ROOT) {
            Write-Host "配置文件损坏，重新初始化..." -ForegroundColor Yellow
            return Initialize-Config
        }
        
        # 验证目录是否存在
        if (-not (Test-Path $config.RESEARCH_ROOT)) {
            Write-Host "研究根目录不存在: $($config.RESEARCH_ROOT)" -ForegroundColor Red
            Write-Host "重新配置..." -ForegroundColor Yellow
            return Initialize-Config
        }
        
        return $config
    } catch {
        Write-Host "读取配置文件失败，重新初始化..." -ForegroundColor Yellow
        return Initialize-Config
    }
}

# 加载配置
$config = Load-Config
$RESEARCH_ROOT = $config.RESEARCH_ROOT
$BACKUP_ROOT = $config.BACKUP_ROOT

# 设置默认值
$BACKUP_KEEP_DAYS = 30
$DEFAULT_REMOTE = "origin"

# 颜色配置
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    White = "White"
}

# 日志记录函数
function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Green
}

function Write-LogWarn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Colors.Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
}

function Write-LogDebug {
    param([string]$Message)
    Write-Host "[DEBUG] $Message" -ForegroundColor $Colors.Blue
}

# 显示版本信息
function Show-Version {
    Write-Host @"
   ____           __  __            
  |  _ \ ___  ___|  \/  | __ _ _ __  
  | |_) / _ \/ __| |\/| |/ _`` | '_ \ 
  |  _ <  __/\__ \ |  | | (_| | | | |
  |_| \_\___||___/_|  |_|\__,_|_| |_|

研究管理集成脚本 (Windows PowerShell版)
版本: $SCRIPT_VERSION
作者: Maoye
日期: 2025-07-31

功能特性:
- 项目结构化管理
- Git版本控制集成
- 自动化备份系统
- 研究日志记录
- 项目状态报告
- 中间文件清理

"@ -ForegroundColor $Colors.Green
}

# 显示帮助信息
function Show-Help {
    Write-Host @"
研究管理集成脚本 (Windows版) v$SCRIPT_VERSION

用法: resman <操作> [项目名称]

操作:
  -h, --help              显示帮助信息
  -v, --version           显示版本信息
  -l, --list              列出所有项目
  -n, --new               创建新项目
  -i, --init              将现有文件夹标记为项目
  -s, --sync              同步项目到Git（不包含大文件）
  -sa, --sync-all         同步项目到Git（包含小结果文件）
  -b, --backup            备份项目（默认备份所有项目）
  -j, --journal           添加研究日志条目
  -r, --report            生成项目状态报告
  -c, --clean             清理中间文件
  -a, --auto              自动化流程（日志+同步+备份）
  
Git 增强功能:
  -gs, --git-status       检查Git配置信息
  
示例:
  resman -n "injection-seismicity-2025"       # 创建新项目（本地Git初始化）
  resman -i "existing-folder"                 # 标记现有文件夹为项目（可选Git初始化）
  resman -j "injection-seismicity-2025"       # 添加日志条目
  resman -a "injection-seismicity-2025"       # 执行完整工作流
  resman -b                                    # 备份所有项目
  resman -gs                                  # 检查Git配置信息

"@ -ForegroundColor $Colors.White
}

# 检查项目是否存在
function Test-Project {
    param([string]$ProjectName)
    
    if ([string]::IsNullOrEmpty($ProjectName)) {
        Write-LogError "项目名称不能为空"
        exit 1
    }
    
    $ProjectPath = Join-Path $RESEARCH_ROOT $ProjectName
    if (-not (Test-Path $ProjectPath)) {
        Write-LogError "项目 $ProjectName 不存在"
        exit 1
    }
    
    # 检查项目标识文件
    $ProjectMarkerFile = Join-Path $ProjectPath ".resman"
    if (-not (Test-Path $ProjectMarkerFile)) {
        Write-LogError "文件夹 $ProjectName 不是有效的研究项目（缺少 .resman 标识文件）"
        Write-Host "使用 'resman -i $ProjectName' 将其标记为项目" -ForegroundColor $Colors.Yellow
        exit 1
    }
    
    return $ProjectPath
}

# 获取文件大小（MB）
function Get-FileSizeMB {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $Size = (Get-Item $FilePath).Length
        return [math]::Round($Size / 1MB, 2)
    }
    return 0
}

# 创建新项目
function New-ResearchProject {
    param([string]$ProjectName)
    
    $ProjectDir = Join-Path $RESEARCH_ROOT $ProjectName
    
    if (Test-Path $ProjectDir) {
        Write-LogError "项目 $ProjectName 已存在"
        exit 1
    }
    
    Write-LogInfo "创建项目: $ProjectName"
    
    # 注意: 本工具专注于本地研究流程管理，远程仓库需手动创建
    
    # 创建目录结构
    $Directories = @(
        "data\raw",
        "data\processed", 
        "data\intermediate",
        "code",
        "results\figures",
        "results\outcome",
        "results\reports",
        "docs"
    )
    
    foreach ($Dir in $Directories) {
        $FullPath = Join-Path $ProjectDir $Dir
        New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
    }
    
    Set-Location $ProjectDir
    
    # 创建README文件
    $ReadmeContent = @"
# $ProjectName

## 项目概述
[项目描述]

## 数据说明
- **raw/**: 原始数据，不可修改
- **processed/**: 预处理后的数据  
- **intermediate/**: 中间结果

## 代码结构
[代码模块说明]

## 实验记录
[实验版本和结果]

## 使用说明
[如何复现结果]

---
创建时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    $ReadmeContent | Set-Content "README.md" -Encoding UTF8
    
    # 创建研究日志
    $LogContent = @"
# $ProjectName 研究日志

---

## $(Get-Date -Format 'yyyy-MM-dd')

### 项目初始化
- 创建项目结构
- 初始化Git仓库

---
"@
    
    $LogContent | Set-Content "research_log.md" -Encoding UTF8
    
    # 创建.gitignore
    $GitignoreContent = @"
# 原始数据文件
data/raw/

# 大型中间文件
data/intermediate/*.h5
data/intermediate/*.hdf5
data/intermediate/*.nc
data/intermediate/*.mat

# 大型结果文件 (>100MB)
results/outcome/*.h5
results/outcome/*.hdf5
results/outcome/*.bin
results/outcome/*.dat

# 临时文件
*.tmp
*.temp
*~

# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
env/
venv/
.venv/

# Jupyter Notebook
.ipynb_checkpoints/

# IDE
.vscode/
.idea/
*.swp
*.swo

# 系统文件
.DS_Store
Thumbs.db
desktop.ini
"@
    
    $GitignoreContent | Set-Content ".gitignore" -Encoding UTF8
    
    # 创建数据处理追踪文件
    $DataLineage = @{
        project = $ProjectName
        created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        data_pipeline = @{
            version = "1.0.0"
            steps = @()
        }
        last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    $DataLineage | ConvertTo-Json -Depth 3 | Set-Content "data_lineage.json" -Encoding UTF8
    
    # 创建项目标识文件
    $ProjectMarker = @{
        project_name = $ProjectName
        created_date = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        created_by = $env:USERNAME
        resman_version = $SCRIPT_VERSION
        project_type = "research"
        description = "研究项目标识文件 - 请勿删除"
    }
    
    $ProjectMarker | ConvertTo-Json -Depth 2 | Set-Content ".resman" -Encoding UTF8
    
    # 使用本地Git初始化
    $GitInitSuccess = Initialize-Git -ProjectName $ProjectName -ProjectDir $ProjectDir
    if (-not $GitInitSuccess) {
        Write-LogWarn "Git初始化失败，但项目已创建。您可以稍后手动初始化Git"
    }
    
    Write-LogInfo "项目 $ProjectName 创建完成"
    Write-LogInfo "项目路径: $ProjectDir"
}

# 将现有文件夹标记为项目
function Initialize-ExistingProject {
    param([string]$FolderName)
    
    if ([string]::IsNullOrEmpty($FolderName)) {
        Write-LogError "请指定要标记的文件夹名称"
        exit 1
    }
    
    $FolderPath = Join-Path $RESEARCH_ROOT $FolderName
    
    # 检查文件夹是否存在
    if (-not (Test-Path $FolderPath)) {
        Write-LogError "文件夹不存在: $FolderPath"
        exit 1
    }
    
    # 检查是否已经是项目
    $MarkerFile = Join-Path $FolderPath ".resman"
    if (Test-Path $MarkerFile) {
        Write-LogWarn "文件夹 '$FolderName' 已经是一个项目"
        return
    }
    
    Write-LogInfo "将文件夹 '$FolderName' 标记为项目..."
    
    # 创建项目标识文件
    $ProjectInfo = @{
        name = $FolderName
        created_date = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        created_by = $env:USERNAME
        resman_version = $SCRIPT_VERSION
        project_type = "existing"
        description = "从现有文件夹转换的项目"
        initialized_date = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    
    $ProjectInfo | ConvertTo-Json -Depth 3 | Out-File $MarkerFile -Encoding UTF8
    Write-LogInfo "已创建项目标识文件: .resman"
    
    # 如果不存在README.md，创建一个基础的
    $ReadmeFile = Join-Path $FolderPath "README.md"
    if (-not (Test-Path $ReadmeFile)) {
        $ReadmeContent = @"
# $FolderName

## 项目描述
这是一个从现有文件夹转换的研究项目。

## 项目信息
- 项目名称: $FolderName
- 创建日期: $(Get-Date -Format "yyyy-MM-dd")
- 项目类型: 现有文件夹转换

## 目录结构
请根据需要组织您的项目文件。

## 使用说明
请在此处添加项目的使用说明和相关信息。
"@
        $ReadmeContent | Out-File $ReadmeFile -Encoding UTF8
        Write-LogInfo "已创建基础 README.md 文件"
    }
    
    # 如果不存在研究日志，创建一个
    $LogFile = Join-Path $FolderPath "research_log.md"
    if (-not (Test-Path $LogFile)) {
        $LogContent = @"
# $FolderName 研究日志

## $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 项目初始化

### 工作内容
- 将现有文件夹 '$FolderName' 标记为研究项目
- 创建项目标识文件和基础文档

### 备注
项目已纳入 resman 管理系统。

---
"@
        $LogContent | Out-File $LogFile -Encoding UTF8
        Write-LogInfo "已创建研究日志文件"
    }
    
    # 交互式Git初始化
    Set-Location $FolderPath
    if (-not (Test-Path ".git")) {
        Write-Host ""
        $InitGit = Read-Host "是否要初始化Git仓库? (y/N)"
        if ($InitGit -eq "y" -or $InitGit -eq "Y") {
            try {
                git init 2>$null
                git add . 2>$null
                git commit -m "项目初始化: 从现有文件夹转换" 2>$null
                Write-LogInfo "Git仓库已初始化"
                Write-LogInfo "如需远程仓库，请手动创建后使用 'git remote add origin <url>' 连接"
            } catch {
                Write-LogWarn "Git初始化失败: $_"
            }
        }
    }
    
    Write-LogInfo "文件夹 '$FolderName' 已成功标记为项目"
    Write-LogInfo "项目路径: $FolderPath"
    Write-LogInfo "现在可以使用 resman 命令管理此项目"
}

# 列出所有项目
function Get-ProjectList {
    Write-LogInfo "当前研究项目:"
    Write-Host ""
    
    if (-not (Test-Path $RESEARCH_ROOT)) {
        Write-LogWarn "研究根目录不存在: $RESEARCH_ROOT"
        return
    }
    
    $AllFolders = Get-ChildItem $RESEARCH_ROOT -Directory
    $Count = 0
    
    foreach ($Folder in $AllFolders) {
        $ProjectName = $Folder.Name
        $ProjectMarkerFile = Join-Path $Folder.FullName ".resman"
        
        # 只有包含.resman标识文件的文件夹才被认为是项目
        if (-not (Test-Path $ProjectMarkerFile)) {
            continue
        }
        
        $LastModified = $Folder.LastWriteTime.ToString("yyyy-MM-dd")
        
        # 检查Git状态
        $GitStatus = ""
        $GitDir = Join-Path $Folder.FullName ".git"
        
        if (Test-Path $GitDir) {
            Push-Location $Folder.FullName
            try {
                $Uncommitted = (git status --porcelain 2>$null | Measure-Object).Count
                if ($Uncommitted -gt 0) {
                    $GitStatus = "($Uncommitted 未提交)"
                } else {
                    $GitStatus = "(已同步)"
                }
            } catch {
                $GitStatus = "(Git错误)"
            }
            Pop-Location
        } else {
            $GitStatus = "(无Git)"
        }
        
        $ProjectInfo = "{0,-30} {1} {2}" -f $ProjectName, $LastModified, $GitStatus
        Write-Host "  $ProjectInfo"
        $Count++
    }
    
    if ($Count -eq 0) {
        Write-LogWarn "未找到任何项目"
        Write-Host ""
        Write-Host "提示: 只有包含 .resman 标识文件的文件夹才会被识别为项目" -ForegroundColor $Colors.Yellow
        Write-Host "使用 'resman -i [文件夹名]' 将现有文件夹标记为项目" -ForegroundColor $Colors.Yellow
    } else {
        Write-Host ""
        Write-LogInfo "共找到 $Count 个项目"
    }
}

# 添加研究日志
function Add-JournalEntry {
    param([string]$ProjectName)
    
    $ProjectDir = Test-Project $ProjectName
    $LogFile = Join-Path $ProjectDir "research_log.md"
    
    Write-Host ""
    Write-Host "添加研究日志条目" -ForegroundColor $Colors.Blue
    Write-Host "项目: $ProjectName"
    Write-Host "日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    
    # 获取用户输入
    Write-Host "请输入今日工作内容 (输入完成后按回车，然后输入 'END' 结束):"
    $WorkContent = @()
    do {
        $Line = Read-Host
        if ($Line -ne "END") {
            $WorkContent += $Line
        }
    } while ($Line -ne "END")
    
    $WorkContentText = $WorkContent -join "`n"
    
    if ([string]::IsNullOrEmpty($WorkContentText)) {
        Write-LogWarn "工作内容为空，取消添加"
        return
    }
    
    # 获取Git信息
    Set-Location $ProjectDir
    try {
        # 检查是否有Git仓库
        if (Test-Path ".git") {
            $GitCommit = git rev-parse --short HEAD 2>$null
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($GitCommit)) { 
                $GitCommit = "无Git提交" 
            }
            
            # 检查是否有足够的提交历史
            $CommitCount = git rev-list --count HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and $CommitCount -gt 1) {
                $ChangedFiles = git diff --name-only HEAD~1 HEAD 2>$null
                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($ChangedFiles)) {
                    $ChangedFiles = "无变更文件"
                }
            } else {
                $ChangedFiles = "首次提交或无历史记录"
            }
        } else {
            $GitCommit = "未初始化Git仓库"
            $ChangedFiles = "未初始化Git仓库"
        }
    } catch {
        $GitCommit = "Git信息获取失败"
        $ChangedFiles = "Git信息获取失败"
    }
    
    # 添加日志条目
    $LogEntry = @"

## $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

### 工作内容
$WorkContentText

### 技术信息
- Git提交: $GitCommit
- 修改文件: 
$($ChangedFiles -split "`n" | ForEach-Object { "  - $_" } | Out-String)

---
"@
    
    Add-Content $LogFile $LogEntry -Encoding UTF8
    Write-LogInfo "研究日志已更新"
}

# =============================================================================
# Git 增强管理功能
# =============================================================================









# 本地Git初始化（用于新项目）
function Initialize-Git {
    param(
        [string]$ProjectName,
        [string]$ProjectDir
    )
    
    Set-Location $ProjectDir
    
    # 初始化Git仓库
    try {
        git init 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-LogWarn "Git初始化失败"
            return $false
        }
        
        git add . 2>$null
        git commit -m "项目初始化: $ProjectName" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-LogWarn "初始提交失败"
            return $false
        }
        
        Write-LogInfo "本地Git仓库初始化成功"
        Write-LogInfo "如需远程仓库，请手动创建后使用 'git remote add origin <url>' 连接"
        
        return $true
    } catch {
        Write-LogError "Git初始化失败: $_"
        return $false
    }
}

# Git同步功能
function Sync-ToGit {
    param(
        [string]$ProjectName,
        [bool]$IncludeResults = $false
    )
    
    $ProjectDir = Test-Project $ProjectName
    Set-Location $ProjectDir
    
    if (-not (Test-Path ".git")) {
        Write-LogError "项目未初始化Git仓库"
        exit 1
    }
    
    Write-LogInfo "同步项目到Git: $ProjectName"
    
    # 添加代码和文档
    try {
        git add code/ docs/ README.md research_log.md data_lineage.json 2>$null
        # 添加处理后的数据
        git add data/processed/ 2>$null
    } catch {
        Write-LogWarn "添加文件到Git时出现错误: $_"
    }
    
    if ($IncludeResults) {
        Write-LogInfo "检查结果文件大小..."
        
        # 添加小于限制大小的结果文件
        $ResultFiles = Get-ChildItem "results" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($File in $ResultFiles) {
            $SizeMB = Get-FileSizeMB $File.FullName
            if ($SizeMB -lt $config.MAX_FILE_SIZE_MB) {
                git add $File.FullName
                Write-LogDebug "添加结果文件: $($File.Name) (${SizeMB}MB)"
            } else {
                Write-LogWarn "跳过大文件: $($File.Name) (${SizeMB}MB)"
            }
        }
    } else {
        # 只添加图表和报告
        git add results/figures/ results/reports/
    }
    
    # 检查是否有变更
    $StagedChanges = git diff --staged --name-only
    if (-not $StagedChanges) {
        Write-LogInfo "没有需要提交的变更"
        return
    }
    
    # 提交变更
    Write-Host ""
    $CommitMessage = Read-Host "请输入提交信息 (留空使用默认信息)"
    
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        $CommitMessage = "研究进展更新: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    
    try {
        git commit -m $CommitMessage 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-LogInfo "提交成功"
        } else {
            Write-LogWarn "提交失败"
            return
        }
    } catch {
        Write-LogError "提交过程中出现错误: $_"
        return
    }
    
    # 推送到远程仓库
    if ($config.GIT_AUTO_PUSH) {
        $Remote = $config.DEFAULT_REMOTE
        try {
            $CurrentBranch = git branch --show-current
            $RemoteExists = git remote | Where-Object { $_ -eq $Remote }
            
            if ($RemoteExists) {
                Write-LogInfo "推送到远程仓库..."
                git push $Remote $CurrentBranch 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-LogInfo "推送成功"
                } else {
                    Write-LogWarn "推送失败，请检查远程仓库配置"
                }
            } else {
                Write-LogWarn "远程仓库 $Remote 不存在"
            }
        } catch {
            Write-LogWarn "推送过程中出现错误"
        }
    }
}

# 备份功能
function Backup-Research {
    param([string]$ProjectName)
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # 创建备份目录
    $DailyBackupRoot = Join-Path $BACKUP_ROOT "daily"
    $WeeklyBackupRoot = Join-Path $BACKUP_ROOT "weekly"
    
    New-Item -ItemType Directory -Path $DailyBackupRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $WeeklyBackupRoot -Force | Out-Null
    
    $DailyBackup = Join-Path $DailyBackupRoot $Timestamp
    $WeeklyBackup = Join-Path $WeeklyBackupRoot "$(Get-Date -Format 'yyyy_week_')$((Get-Date).DayOfYear / 7 + 1)"
    
    if (-not [string]::IsNullOrEmpty($ProjectName)) {
        # 备份单个项目
        $ProjectDir = Test-Project $ProjectName
        Write-LogInfo "备份项目: $ProjectName"
        
        $BackupProjectDir = Join-Path $DailyBackup $ProjectName
        New-Item -ItemType Directory -Path $BackupProjectDir -Force | Out-Null
        
        # 使用robocopy进行增量备份
        robocopy $ProjectDir $BackupProjectDir /E /XO /R:3 /W:1 /NP | Out-Null
        
        # 周备份（每周一）
        if ((Get-Date).DayOfWeek -eq "Monday") {
            $WeeklyProjectDir = Join-Path $WeeklyBackup $ProjectName
            New-Item -ItemType Directory -Path $WeeklyProjectDir -Force | Out-Null
            robocopy $ProjectDir $WeeklyProjectDir /E /R:3 /W:1 /NP | Out-Null
            Write-LogInfo "周备份完成"
        }
    } else {
        # 备份所有项目
        Write-LogInfo "备份所有项目..."
        
        $Projects = Get-ChildItem $RESEARCH_ROOT -Directory
        foreach ($Project in $Projects) {
            $ProjectName = $Project.Name
            Write-LogDebug "备份: $ProjectName"
            
            $BackupProjectDir = Join-Path $DailyBackup $ProjectName
            New-Item -ItemType Directory -Path $BackupProjectDir -Force | Out-Null
            robocopy $Project.FullName $BackupProjectDir /E /XO /R:3 /W:1 /NP | Out-Null
        }
        
        # 周备份
        if ((Get-Date).DayOfWeek -eq "Monday") {
            Write-LogInfo "执行周备份..."
            New-Item -ItemType Directory -Path $WeeklyBackup -Force | Out-Null
            robocopy $RESEARCH_ROOT $WeeklyBackup /E /R:3 /W:1 /NP | Out-Null
        }
    }
    
    # 清理旧备份
    $KeepDays = $config.BACKUP_KEEP_DAYS
    $CutoffDate = (Get-Date).AddDays(-$KeepDays)
    
    Get-ChildItem $DailyBackupRoot -Directory | Where-Object { $_.LastWriteTime -lt $CutoffDate } | Remove-Item -Recurse -Force
    Get-ChildItem $WeeklyBackupRoot -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } | Remove-Item -Recurse -Force
    
    Write-LogInfo "备份完成: $DailyBackup"
}

# 生成项目报告
function New-ProjectReport {
    param([string]$ProjectName)
    
    $ProjectDir = Test-Project $ProjectName
    Set-Location $ProjectDir
    
    Write-LogInfo "生成项目状态报告: $ProjectName"
    
    $ReportFile = "project_status_$(Get-Date -Format 'yyyyMMdd').md"
    
    $ReportContent = @"
# $ProjectName 项目状态报告

**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 项目结构
``````
$(Get-ChildItem -Recurse -Directory | Where-Object { $_.Name -notmatch '__pycache__|\.git|\.ipynb_checkpoints' } | Select-Object -First 20 | ForEach-Object { $_.FullName.Replace($ProjectDir, '.') })
``````

## 文件统计
"@
    
    # 统计各目录文件数量
    $Directories = @("data\raw", "data\processed", "data\intermediate", "code", "results\figures", "results\outcome", "results\reports", "docs")
    foreach ($Dir in $Directories) {
        $DirPath = Join-Path $ProjectDir $Dir
        if (Test-Path $DirPath) {
            $FileCount = (Get-ChildItem $DirPath -Recurse -File | Measure-Object).Count
            $DirSize = "{0:N2} MB" -f ((Get-ChildItem $DirPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB)
            $ReportContent += "`n- **$Dir**: $FileCount 个文件, $DirSize"
        }
    }
    
    $ReportContent += @"

## Git状态
"@
    
    if (Test-Path ".git") {
        try {
            $CurrentBranch = git branch --show-current
            $LastCommit = git log -1 --oneline
            $UncommittedCount = (git status --porcelain | Measure-Object).Count
            
            $ReportContent += "`n- **分支**: $CurrentBranch"
            $ReportContent += "`n- **最新提交**: $LastCommit"
            $ReportContent += "`n- **未提交变更**: $UncommittedCount 个文件"
        } catch {
            $ReportContent += "`n- Git状态检查失败"
        }
    } else {
        $ReportContent += "`n- 未初始化Git仓库"
    }
    
    $ReportContent += @"

## 最近活动
### 最近修改文件 (7天内)
"@
    
    # 最近修改的文件
    $RecentFiles = Get-ChildItem -Recurse -File | Where-Object { 
        $_.LastWriteTime -gt (Get-Date).AddDays(-7) -and 
        $_.FullName -notmatch '\.git' 
    } | Select-Object -First 10
    
    foreach ($File in $RecentFiles) {
        $RelativePath = $File.FullName.Replace($ProjectDir, '.')
        $ReportContent += "`n- $RelativePath"
    }
    
    $ReportContent | Set-Content $ReportFile -Encoding UTF8
    Write-LogInfo "报告已生成: $ReportFile"
}

# 清理中间文件
function Clear-IntermediateFiles {
    param([string]$ProjectName)
    
    $ProjectDir = Test-Project $ProjectName
    
    Write-LogInfo "清理项目中间文件: $ProjectName"
    
    # 清理中间数据
    $IntermediateDir = Join-Path $ProjectDir "data\intermediate"
    if (Test-Path $IntermediateDir) {
        Get-ChildItem $IntermediateDir -Filter "*.tmp" | Remove-Item -Force
        Get-ChildItem $IntermediateDir -Filter "*.temp" | Remove-Item -Force
    }
    
    # 清理Python缓存
    Get-ChildItem $ProjectDir -Recurse -Directory -Name "__pycache__" | ForEach-Object {
        Remove-Item (Join-Path $ProjectDir $_) -Recurse -Force
    }
    Get-ChildItem $ProjectDir -Recurse -Filter "*.pyc" | Remove-Item -Force
    
    # 清理Jupyter检查点
    Get-ChildItem $ProjectDir -Recurse -Directory -Name ".ipynb_checkpoints" | ForEach-Object {
        Remove-Item (Join-Path $ProjectDir $_) -Recurse -Force
    }
    
    Write-LogInfo "清理完成"
}

# 自动化工作流
function Start-AutoWorkflow {
    param([string]$ProjectName)
    
    Test-Project $ProjectName | Out-Null
    
    Write-LogInfo "执行自动化工作流: $ProjectName"
    
    Write-Host ""
    Write-LogInfo "步骤 1: 添加研究日志"
    Add-JournalEntry $ProjectName
    
    Write-Host ""
    Write-LogInfo "步骤 2: 同步到Git"
    Sync-ToGit $ProjectName $false
    
    Write-Host ""
    Write-LogInfo "步骤 3: 备份项目"
    Backup-Research $ProjectName
    
    Write-Host ""
    Write-LogInfo "自动化工作流完成"
}


# 主函数
function Main {
    # 初始化配置和创建必要目录
    New-Item -ItemType Directory -Path $RESEARCH_ROOT -Force | Out-Null
    New-Item -ItemType Directory -Path $BACKUP_ROOT -Force | Out-Null
    
    # 验证项目名称格式（如果提供了项目名称）
    if (-not [string]::IsNullOrEmpty($ProjectName)) {
        if ($ProjectName -match '[<>:"/\\|?*]') {
            Write-LogError "项目名称包含无效字符: < > : `" / \\ | ? *"
            exit 1
        }
        if ($ProjectName.Length -gt 100) {
            Write-LogError "项目名称过长（最大100字符）"
            exit 1
        }
    }
    
    # 解析命令行参数
    switch ($Operation) {
        { $_ -in @("-h", "--help") } {
            Show-Help
            exit 0
        }
        { $_ -in @("-v", "--version") } {
            Show-Version
            exit 0
        }
        { $_ -in @("-l", "--list") } {
            Get-ProjectList
        }
        { $_ -in @("-n", "--new") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            New-ResearchProject $ProjectName
        }
        { $_ -in @("-i", "--init") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定文件夹名称"
                exit 1
            }
            Initialize-ExistingProject $ProjectName
        }
        { $_ -in @("-s", "--sync") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            Sync-ToGit $ProjectName $false
        }
        { $_ -in @("-sa", "--sync-all") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            Sync-ToGit $ProjectName $true
        }
        { $_ -in @("-b", "--backup") } {
            Backup-Research $ProjectName
        }
        { $_ -in @("-j", "--journal") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            Add-JournalEntry $ProjectName
        }
        { $_ -in @("-r", "--report") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            New-ProjectReport $ProjectName
        }
        { $_ -in @("-c", "--clean") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            Clear-IntermediateFiles $ProjectName
        }
        { $_ -in @("-a", "--auto") } {
            if ([string]::IsNullOrEmpty($ProjectName)) {
                Write-LogError "请指定项目名称"
                exit 1
            }
            Start-AutoWorkflow $ProjectName
        }
        { $_ -in @("-gs", "--git-status") } {
            Write-Host ""
            Write-LogInfo "Git 配置信息:"
            $gitUserName = git config --global user.name 2>$null
            $gitUserEmail = git config --global user.email 2>$null
            Write-Host "  用户名: $(if($gitUserName) { $gitUserName } else { '未配置' })" -ForegroundColor $Colors.Blue
            Write-Host "  邮箱: $(if($gitUserEmail) { $gitUserEmail } else { '未配置' })" -ForegroundColor $Colors.Blue
            Write-Host ""
            Write-LogInfo "注意: 本工具专注于本地研究流程管理，远程仓库需手动创建"
        }
        "" {
            # 无参数时显示简短提示
            Write-Host "研究管理集成脚本 (Windows版) v$SCRIPT_VERSION" -ForegroundColor $Colors.Green
            Write-Host ""
            Write-Host "用法: resman <操作> [项目名称]" -ForegroundColor $Colors.White
            Write-Host "使用 'resman -h' 查看详细帮助信息" -ForegroundColor $Colors.Yellow
            exit 1
        }
        default {
            Write-LogError "未知选项: $Operation"
            Write-Host "使用 'resman -h' 查看帮助信息" -ForegroundColor $Colors.Yellow
            exit 1
        }
    }
}

# 执行主函数
Main
