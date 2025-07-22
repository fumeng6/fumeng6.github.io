#!/bin/bash

# =============================================================================
# 研究项目管理集成脚本
# 功能: Git同步、数据备份、日志记录、项目管理
# 作者: Maoye
# 日期: 2025-07-22
# =============================================================================

# 脚本配置
SCRIPT_VERSION="1.0.0"
RESEARCH_ROOT="$HOME/research"
BACKUP_ROOT="$HOME/research_backup"
CONFIG_FILE="$HOME/.research_config"

# 颜色输出配置
# 检测终端是否支持颜色
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    # 如果终端不支持颜色，使用空字符串
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# 帮助信息
show_help() {
    cat << EOF
研究管理集成脚本 v${SCRIPT_VERSION}

用法: $(basename "$0") [选项] [项目名称]

选项:
  -h, --help              显示帮助信息
  -l, --list              列出所有项目
  -n, --new PROJECT       创建新项目
  -s, --sync PROJECT      同步项目到Git（不包含大文件）
  -S, --sync-all PROJECT  同步项目到Git（包含小结果文件）
  -b, --backup [PROJECT]  备份项目（默认备份所有项目）
  -j, --journal PROJECT   添加研究日志条目
  -r, --report PROJECT    生成项目状态报告
  -c, --clean PROJECT     清理中间文件
  -a, --auto PROJECT      自动化流程（日志+同步+备份）
  
示例:
  $(basename "$0") -n injection-seismicity-2025    # 创建新项目
  $(basename "$0") -j injection-seismicity-2025    # 添加日志条目
  $(basename "$0") -a injection-seismicity-2025    # 执行完整工作流
  $(basename "$0") -b                               # 备份所有项目

EOF
}

# 日志记录函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 检查项目是否存在
check_project() {
    local project_name="$1"
    if [[ -z "$project_name" ]]; then
        log_error "项目名称不能为空"
        exit 1
    fi
    
    if [[ ! -d "$RESEARCH_ROOT/$project_name" ]]; then
        log_error "项目 $project_name 不存在"
        exit 1
    fi
}

# 初始化配置文件
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# 研究管理配置文件
GIT_AUTO_PUSH=true
BACKUP_KEEP_DAYS=30
LOG_LEVEL=INFO
DEFAULT_REMOTE=origin
MAX_FILE_SIZE_MB=100
ENABLE_COLOR=auto
EOF
        log_info "配置文件已创建: $CONFIG_FILE"
    fi
    
    # 加载配置
    source "$CONFIG_FILE"
    
    # 根据配置重新设置颜色
    if [[ "${ENABLE_COLOR:-auto}" == "false" ]]; then
        # 强制禁用颜色
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        NC=''
    elif [[ "${ENABLE_COLOR:-auto}" == "true" ]]; then
        # 强制启用颜色
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        NC='\033[0m'
    fi
    # auto模式使用之前的自动检测结果
}

# 获取文件大小（MB）
get_file_size_mb() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        du -m "$file_path" | cut -f1
    else
        echo 0
    fi
}

# 创建新项目
create_project() {
    local project_name="$1"
    local project_dir="$RESEARCH_ROOT/$project_name"
    
    if [[ -d "$project_dir" ]]; then
        log_error "项目 $project_name 已存在"
        exit 1
    fi
    
    log_info "创建项目: $project_name"
    
    # 创建目录结构
    mkdir -p "$project_dir"/{data/{raw,processed,intermediate},code,results/{figures,outcome,reports},docs}
    
    cd "$project_dir"
    
    # 创建README文件
    cat > README.md << EOF
# $project_name

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
创建时间: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    # 创建研究日志
    cat > research_log.md << EOF
# $project_name 研究日志

---

## $(date '+%Y-%m-%d')

### 项目初始化
- 创建项目结构
- 初始化Git仓库

---
EOF

    # 创建.gitignore
    cat > .gitignore << EOF
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
*$py.class
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
EOF

    # 创建数据处理追踪文件模板
    cat > data_lineage.json << EOF
{
  "project": "$project_name",
  "created": "$(date -Iseconds)",
  "data_pipeline": {
    "version": "1.0.0",
    "steps": []
  },
  "last_updated": "$(date -Iseconds)"
}
EOF

    # 初始化Git仓库
    git init
    git add .
    git commit -m "项目初始化: $project_name"
    
    log_info "项目 $project_name 创建完成"
    log_info "项目路径: $project_dir"
}

# 列出所有项目
list_projects() {
    log_info "当前研究项目:"
    echo
    
    if [[ ! -d "$RESEARCH_ROOT" ]]; then
        log_warn "研究根目录不存在: $RESEARCH_ROOT"
        return
    fi
    
    local count=0
    for project_dir in "$RESEARCH_ROOT"/*; do
        if [[ -d "$project_dir" ]]; then
            local project_name=$(basename "$project_dir")
            local last_modified=$(stat -c %y "$project_dir" 2>/dev/null | cut -d' ' -f1)
            
            # 检查Git状态
            local git_status=""
            if [[ -d "$project_dir/.git" ]]; then
                cd "$project_dir"
                local uncommitted=$(git status --porcelain 2>/dev/null | wc -l)
                if [[ $uncommitted -gt 0 ]]; then
                    git_status="${YELLOW}(${uncommitted} 未提交)${NC}"
                else
                    git_status="${GREEN}(已同步)${NC}"
                fi
            else
                git_status="${RED}(无Git)${NC}"
            fi
            
            # 使用echo -e来正确处理颜色转义序列
            echo -e "  $(printf "%-30s %s " "$project_name" "$last_modified")$git_status"
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        log_warn "未找到任何项目"
    else
        echo
        log_info "共找到 $count 个项目"
    fi
}

# 添加研究日志
add_journal_entry() {
    local project_name="$1"
    check_project "$project_name"
    
    local project_dir="$RESEARCH_ROOT/$project_name"
    local log_file="$project_dir/research_log.md"
    
    echo
    echo -e "${BLUE}添加研究日志条目${NC}"
    echo "项目: $project_name"
    echo "日期: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    # 获取用户输入
    echo "请输入今日工作内容 (按Ctrl+D结束):"
    local work_content=$(cat)
    
    if [[ -z "$work_content" ]]; then
        log_warn "工作内容为空，取消添加"
        return
    fi
    
    # 获取Git信息
    cd "$project_dir"
    local git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "无Git提交")
    local changed_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "无变更文件")
    
    # 添加日志条目
    cat >> "$log_file" << EOF

## $(date '+%Y-%m-%d %H:%M:%S')

### 工作内容
$work_content

### 技术信息
- Git提交: $git_commit
- 修改文件: 
$(echo "$changed_files" | sed 's/^/  - /')

---
EOF

    log_info "研究日志已更新"
}

# Git同步功能
sync_to_git() {
    local project_name="$1"
    local include_results="$2"
    check_project "$project_name"
    
    local project_dir="$RESEARCH_ROOT/$project_name"
    cd "$project_dir"
    
    if [[ ! -d ".git" ]]; then
        log_error "项目未初始化Git仓库"
        exit 1
    fi
    
    log_info "同步项目到Git: $project_name"
    
    # 添加代码和文档
    git add code/ docs/ README.md research_log.md data_lineage.json
    
    # 添加处理后的数据
    git add data/processed/
    
    if [[ "$include_results" == "true" ]]; then
        log_info "检查结果文件大小..."
        
        # 添加小于限制大小的结果文件
        find results/ -type f | while read -r file; do
            local size_mb=$(get_file_size_mb "$file")
            if [[ $size_mb -lt ${MAX_FILE_SIZE_MB:-100} ]]; then
                git add "$file"
                log_debug "添加结果文件: $file (${size_mb}MB)"
            else
                log_warn "跳过大文件: $file (${size_mb}MB)"
            fi
        done
    else
        # 只添加图表和报告
        git add results/figures/ results/reports/
    fi
    
    # 检查是否有变更
    if git diff --staged --quiet; then
        log_info "没有需要提交的变更"
        return
    fi
    
    # 提交变更
    echo
    echo "请输入提交信息 (留空使用默认信息):"
    read -r commit_message
    
    if [[ -z "$commit_message" ]]; then
        commit_message="研究进展更新: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    git commit -m "$commit_message"
    
    # 推送到远程仓库
    if [[ "${GIT_AUTO_PUSH:-true}" == "true" ]]; then
        local remote="${DEFAULT_REMOTE:-origin}"
        local current_branch=$(git branch --show-current)
        
        if git remote | grep -q "$remote"; then
            log_info "推送到远程仓库..."
            if git push "$remote" "$current_branch" 2>/dev/null; then
                log_info "推送成功"
            else
                log_warn "推送失败，请检查远程仓库配置"
            fi
        else
            log_warn "远程仓库 $remote 不存在"
        fi
    fi
}

# 备份功能
backup_research() {
    local project_name="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # 创建备份目录
    mkdir -p "$BACKUP_ROOT/daily" "$BACKUP_ROOT/weekly"
    
    local daily_backup="$BACKUP_ROOT/daily/$timestamp"
    local weekly_backup="$BACKUP_ROOT/weekly/$(date +%Y_week_%U)"
    
    if [[ -n "$project_name" ]]; then
        # 备份单个项目
        check_project "$project_name"
        log_info "备份项目: $project_name"
        
        local project_dir="$RESEARCH_ROOT/$project_name"
        mkdir -p "$daily_backup"
        
        # 增量备份
        rsync -av --link-dest="$BACKUP_ROOT/latest/$project_name" \
              "$project_dir/" "$daily_backup/$project_name/"
        
        # 周备份（每周一）
        if [[ $(date +%u) -eq 1 ]]; then
            mkdir -p "$weekly_backup"
            rsync -av "$project_dir/" "$weekly_backup/$project_name/"
            log_info "周备份完成"
        fi
        
    else
        # 备份所有项目
        log_info "备份所有项目..."
        
        for project_dir in "$RESEARCH_ROOT"/*; do
            if [[ -d "$project_dir" ]]; then
                local proj_name=$(basename "$project_dir")
                log_debug "备份: $proj_name"
                
                mkdir -p "$daily_backup"
                rsync -av --link-dest="$BACKUP_ROOT/latest/$proj_name" \
                      "$project_dir/" "$daily_backup/$proj_name/"
            fi
        done
        
        # 周备份
        if [[ $(date +%u) -eq 1 ]]; then
            log_info "执行周备份..."
            mkdir -p "$weekly_backup"
            rsync -av "$RESEARCH_ROOT/" "$weekly_backup/"
        fi
    fi
    
    # 更新最新备份链接
    rm -rf "$BACKUP_ROOT/latest"
    ln -s "$daily_backup" "$BACKUP_ROOT/latest"
    
    # 清理旧备份
    local keep_days=${BACKUP_KEEP_DAYS:-30}
    find "$BACKUP_ROOT/daily" -maxdepth 1 -type d -mtime +$keep_days -exec rm -rf {} \;
    find "$BACKUP_ROOT/weekly" -maxdepth 1 -type d -mtime +90 -exec rm -rf {} \;
    
    log_info "备份完成: $daily_backup"
}

# 生成项目报告
generate_report() {
    local project_name="$1"
    check_project "$project_name"
    
    local project_dir="$RESEARCH_ROOT/$project_name"
    cd "$project_dir"
    
    log_info "生成项目状态报告: $project_name"
    
    local report_file="$project_dir/project_status_$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOF
# $project_name 项目状态报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 项目结构
\`\`\`
$(tree -I '__pycache__|.git|.ipynb_checkpoints' || find . -type d | head -20)
\`\`\`

## 文件统计
EOF

    # 统计各目录文件数量
    for dir in data/raw data/processed data/intermediate code results/figures results/outcome results/reports docs; do
        if [[ -d "$dir" ]]; then
            local count=$(find "$dir" -type f | wc -l)
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "- **$dir**: $count 个文件, $size" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## Git状态
EOF
    
    if [[ -d ".git" ]]; then
        echo "- **分支**: $(git branch --show-current)" >> "$report_file"
        echo "- **最新提交**: $(git log -1 --oneline)" >> "$report_file"
        echo "- **未提交变更**: $(git status --porcelain | wc -l) 个文件" >> "$report_file"
    else
        echo "- 未初始化Git仓库" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## 最近活动
EOF
    
    # 最近修改的文件
    echo "### 最近修改文件 (7天内)" >> "$report_file"
    find . -type f -mtime -7 -not -path './.git/*' | head -10 | while read -r file; do
        echo "- $file" >> "$report_file"
    done
    
    log_info "报告已生成: $report_file"
}

# 清理中间文件
clean_intermediate() {
    local project_name="$1"
    check_project "$project_name"
    
    local project_dir="$RESEARCH_ROOT/$project_name"
    
    log_info "清理项目中间文件: $project_name"
    
    # 清理中间数据
    rm -rf "$project_dir/data/intermediate"/*.tmp
    rm -rf "$project_dir/data/intermediate"/*.temp
    
    # 清理Python缓存
    find "$project_dir" -name "__pycache__" -type d -exec rm -rf {} +
    find "$project_dir" -name "*.pyc" -delete
    
    # 清理Jupyter检查点
    find "$project_dir" -name ".ipynb_checkpoints" -type d -exec rm -rf {} +
    
    log_info "清理完成"
}

# 自动化工作流
auto_workflow() {
    local project_name="$1"
    check_project "$project_name"
    
    log_info "执行自动化工作流: $project_name"
    
    echo
    log_info "步骤 1: 添加研究日志"
    add_journal_entry "$project_name"
    
    echo
    log_info "步骤 2: 同步到Git"
    sync_to_git "$project_name" "false"
    
    echo
    log_info "步骤 3: 备份项目"
    backup_research "$project_name"
    
    echo
    log_info "自动化工作流完成"
}

# 主函数
main() {
    # 初始化配置
    init_config
    
    # 创建必要目录
    mkdir -p "$RESEARCH_ROOT" "$BACKUP_ROOT"
    
    # 解析命令行参数
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_projects
            ;;
        -n|--new)
            create_project "$2"
            ;;
        -s|--sync)
            sync_to_git "$2" "false"
            ;;
        -S|--sync-all)
            sync_to_git "$2" "true"
            ;;
        -b|--backup)
            backup_research "$2"
            ;;
        -j|--journal)
            add_journal_entry "$2"
            ;;
        -r|--report)
            generate_report "$2"
            ;;
        -c|--clean)
            clean_intermediate "$2"
            ;;
        -a|--auto)
            auto_workflow "$2"
            ;;
        "")
            show_help
            exit 1
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"