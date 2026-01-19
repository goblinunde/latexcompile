#!/bin/zsh

# ==============================================================================
#   ui_components.sh - Modern UI Components for LaTeX Compiler
#   提供Box边框、图标、进度条等现代化UI组件
# ==============================================================================

# 依赖: 需要先加载 themes.sh 以获取颜色变量

# --- ASCII符号定义 (终端安全) ---
readonly ICON_CHECK="[OK]"
readonly ICON_CROSS="[X]"
readonly ICON_LIGHTNING="*"
readonly ICON_FILE="[F]"
readonly ICON_FOLDER="[D]"
readonly ICON_ROCKET=">>>"
readonly ICON_SETTINGS="[*]"
readonly ICON_PALETTE="[#]"
readonly ICON_CLEAN="[~]"
readonly ICON_STATS="[=]"
readonly ICON_HISTORY="[@]"
readonly ICON_TEMPLATE="[+]"
readonly ICON_SEARCH="[?]"
readonly ICON_WARNING="[!]"
readonly ICON_INFO="[i]"
readonly ICON_BULLET="*"
readonly ICON_ARROW="->"
readonly ICON_DOOR="[Q]"

# Box Drawing Characters
readonly BOX_TL="╭"  # Top Left
readonly BOX_TR="╮"  # Top Right
readonly BOX_BL="╰"  # Bottom Left
readonly BOX_BR="╯"  # Bottom Right
readonly BOX_H="─"   # Horizontal
readonly BOX_V="│"   # Vertical

readonly BOX2_TL="┌"
readonly BOX2_TR="┐"
readonly BOX2_BL="└"
readonly BOX2_BR="┘"
readonly BOX2_H="─"
readonly BOX2_V="│"

# --- 辅助函数 ---

# 获取终端宽度
get_term_width() {
    tput cols 2>/dev/null || echo 80
}

# 重复字符n次
repeat_char() {
    local char="$1"
    local count="$2"
    printf "%${count}s" | tr ' ' "$char"
}

# 居中文本
center_text() {
    local text="$1"
    local width="${2:-$(get_term_width)}"
    # 移除ANSI颜色代码以计算实际文本长度
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local padding=$(( (width - text_len) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# --- Box 绘制函数 ---

# 绘制简单边框Box
# 用法: draw_box "Title" "Content line 1" "Content line 2" ...
draw_box() {
    local title="$1"
    shift
    local -a content_lines=("$@")
    
    local term_width=$(get_term_width)
    local box_width=$((term_width > 60 ? 60 : term_width - 4))
    local inner_width=$((box_width - 4))
    
    # Top border with title
    echo -e "${C_ACCENT}${BOX_TL}${BOX_H}${BOX_H} ${C_BOLD}${title}${C_RESET}${C_ACCENT} $(repeat_char "$BOX_H" $((box_width - ${#title} - 5)))${BOX_TR}${C_RESET}"
    
    # Content lines
    for line in "${content_lines[@]}"; do
        local clean_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local padding=$((inner_width - ${#clean_line}))
        echo -e "${C_ACCENT}${BOX_V}${C_RESET}  ${line}$(repeat_char ' ' $padding)${C_ACCENT}${BOX_V}${C_RESET}"
    done
    
    # Bottom border
    echo -e "${C_ACCENT}${BOX_BL}$(repeat_char "$BOX_H" $((box_width - 2)))${BOX_BR}${C_RESET}"
}

# 绘制双线边框Box (用于重要信息)
draw_box_double() {
    local title="$1"
    shift
    local -a content_lines=("$@")
    
    local term_width=$(get_term_width)
    local box_width=$((term_width > 60 ? 60 : term_width - 4))
    
    # Top border
    echo -e "${C_PRIMARY}${BOX2_TL}${BOX2_H} ${C_BOLD}${title}${C_RESET}${C_PRIMARY} $(repeat_char "$BOX2_H" $((box_width - ${#title} - 5)))${BOX2_TR}${C_RESET}"
    
    # Content
    for line in "${content_lines[@]}"; do
        local clean_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local padding=$((box_width - ${#clean_line} - 4))
        echo -e "${C_PRIMARY}${BOX2_V}${C_RESET}  ${line}$(repeat_char ' ' $padding)${C_PRIMARY}${BOX2_V}${C_RESET}"
    done
    
    # Bottom border
    echo -e "${C_PRIMARY}${BOX2_BL}$(repeat_char "$BOX2_H" $((box_width - 2)))${BOX2_BR}${C_RESET}"
}

# --- 标题栏函数 ---

# 绘制装饰性标题栏
draw_header() {
    local title="$1"
    local subtitle="$2"
    local term_width=$(get_term_width)
    
    echo ""
    echo -e "${C_PRIMARY}$(repeat_char '━' $term_width)${C_RESET}"
    center_text "${C_BOLD}${C_ACCENT}${ICON_LIGHTNING}${C_RESET} ${C_BOLD}${title}${C_RESET} ${C_ACCENT}${ICON_LIGHTNING}${C_RESET}"
    if [[ -n "$subtitle" ]]; then
        center_text "${C_DIM}${subtitle}${C_RESET}"
    fi
    echo -e "${C_PRIMARY}$(repeat_char '━' $term_width)${C_RESET}"
    echo ""
}

# 绘制分隔线
draw_separator() {
    local char="${1:-━}"
    local color="${2:-$C_PRIMARY}"
    local term_width=$(get_term_width)
    echo -e "${color}$(repeat_char "$char" $term_width)${C_RESET}"
}

# --- 进度条函数 ---

# 绘制进度条
# 用法: draw_progress <current> <total> <label>
draw_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-Progress}"
    
    local percent=$((current * 100 / total))
    local bar_width=40
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))
    
    local bar="["
    bar+="${C_SUCCESS}$(repeat_char '█' $filled)${C_RESET}"
    bar+="${C_DIM}$(repeat_char '░' $empty)${C_RESET}"
    bar+="]"
    
    echo -e "${label}: ${bar} ${C_BOLD}${percent}%${C_RESET} (${current}/${total})"
}

# 编译进度动画 (简化版，用于快速反馈)
show_compile_status() {
    local file="$1"
    local engine="$2"
    local pass="${3:-1}"
    
    echo ""
    draw_separator "═" "$C_CYAN"
    echo -e "${C_BOLD}Compiling:${C_RESET} ${C_ACCENT}${file}${C_RESET} ${C_DIM}with${C_RESET} ${C_PRIMARY}${engine}${C_RESET}"
    draw_progress "$pass" 4 "Pass"
    draw_separator "═" "$C_CYAN"
    echo ""
}

# --- 状态消息函数 ---

# 成功消息
print_success() {
    echo -e "${C_SUCCESS}${ICON_CHECK}${C_RESET} ${C_BOLD}$@${C_RESET}"
}

# 错误消息
print_error() {
    echo -e "${C_ERROR}${ICON_CROSS}${C_RESET} ${C_BOLD}$@${C_RESET}"
}

# 警告消息
print_warning() {
    echo -e "${C_WARNING}${ICON_WARNING}${C_RESET}  ${C_BOLD}$@${C_RESET}"
}

# 信息消息
print_info() {
    echo -e "${C_CYAN}${ICON_INFO}${C_RESET}  $@"
}

# 带图标的普通消息
print_with_icon() {
    local icon="$1"
    shift
    echo -e "${icon}  $@"
}

# --- 菜单绘制函数 ---

# 绘制现代化菜单
# 用法: draw_menu "Menu Title" "${menu_items[@]}"
draw_menu() {
    local title="$1"
    shift
    local -a items=("$@")
    
    echo ""
    draw_box_double "$title"
    echo ""
    
    local i=1
    for item in "${items[@]}"; do
        # 提取图标 (如果以emoji开头)
        local display_item="$item"
        echo -e "  ${C_ACCENT}${i})${C_RESET} ${display_item}"
        ((i++))
    done
    echo ""
}

# --- 确认提示函数 ---

# 美化的yes/no提示
prompt_confirm() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt="${C_WARNING}❯${C_RESET} ${message} "
    if [[ "$default" == "y" ]]; then
        prompt+="${C_DIM}[Y/n]${C_RESET} "
    else
        prompt+="${C_DIM}[y/N]${C_RESET} "
    fi
    
    echo -en "$prompt"
    read -q REPLY
    echo
    
    if [[ -z "$REPLY" ]]; then
        [[ "$default" == "y" ]] && return 0 || return 1
    fi
    
    [[ "$REPLY" =~ ^[Yy]$ ]] && return 0 || return 1
}

# --- 加载动画 ---

# 旋转加载动画 (后台任务指示器)
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " ${C_CYAN}%c${C_RESET} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
}

# --- Logo 显示 ---

# 显示ASCII Logo (可选)
show_logo() {
    local version="${1:-v6.0}"
    echo ""
    echo -e "${C_ACCENT}"
    cat << 'EOF'
    ╔╦╗╔═╗═╗ ╦  ╔═╗┌─┐┌┬┐┌─┐┬┬  ┌─┐┬─┐
     ║ ║╣ ╔╩╦╝  ║  │ ││││├─┘││  ├┤ ├┬┘
     ╩ ╚═╝╩ ╚═  ╚═╝└─┘┴ ┴┴  ┴┴─┘└─┘┴└─
EOF
    echo -e "${C_RESET}"
    center_text "${C_DIM}Professional LaTeX Compilation Tool ${version}${C_RESET}"
    echo ""
}

# --- 表格绘制 ---

# 简单两列表格
draw_table_2col() {
    local -a rows=("$@")
    local max_key_len=0
    
    # 找出最长的key
    for row in "${rows[@]}"; do
        local key="${row%%:*}"
        [[ ${#key} -gt $max_key_len ]] && max_key_len=${#key}
    done
    
    # 绘制表格
    for row in "${rows[@]}"; do
        local key="${row%%:*}"
        local value="${row#*:}"
        local padding=$((max_key_len - ${#key} + 2))
        echo -e "  ${C_ACCENT}${key}${C_RESET}$(repeat_char ' ' $padding): ${C_BOLD}${value}${C_RESET}"
    done
}
