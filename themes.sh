#!/bin/zsh

# ==============================================================================
#   themes.sh - LaTeX Compiler Theme Definitions
#   包含预设主题配色方案和主题加载函数
# ==============================================================================

# --- Theme Definitions / 主题定义 ---
# Format: THEME_NAME[COLOR_ROLE]="R,G,B"

# 1. Default Theme (原始配色)
typeset -A THEME_DEFAULT=(
    [PRIMARY]="0,122,204"       # 蓝色
    [SUCCESS]="0,150,0"         # 绿色
    [WARNING]="255,193,7"       # 黄色
    [ERROR]="220,53,69"         # 红色
    [ACCENT]="156,39,176"       # 紫色
    [CYAN]="23,162,184"         # 青色
)

# 2. Nord Theme (北欧极光)
typeset -A THEME_NORD=(
    [PRIMARY]="136,192,208"     # 北欧蓝 #88C0D0
    [SUCCESS]="163,190,140"     # 极光绿 #A3BE8C
    [WARNING]="235,203,139"     # 暖黄 #EBCB8B
    [ERROR]="191,97,106"        # 暮光红 #BF616A
    [ACCENT]="180,142,173"      # 紫罗兰 #B48EAD
    [CYAN]="129,161,193"        # 霜冻蓝 #81A1C1
)

# 3. Dracula Theme (吸血鬼)
typeset -A THEME_DRACULA=(
    [PRIMARY]="189,147,249"     # Dracula紫 #BD93F9
    [SUCCESS]="80,250,123"      # 翠绿 #50FA7B
    [WARNING]="241,250,140"     # 亮黄 #F1FA8C
    [ERROR]="255,85,85"         # 血红 #FF5555
    [ACCENT]="255,121,198"      # 粉红 #FF79C6
    [CYAN]="139,233,253"        # 青色 #8BE9FD
)

# 4. Sakura Theme (樱花)
typeset -A THEME_SAKURA=(
    [PRIMARY]="255,182,193"     # 樱花粉 #FFB6C1
    [SUCCESS]="152,251,152"     # 嫩绿 #98FB98
    [WARNING]="255,218,185"     # 蜜桃橙 #FFDAB9
    [ERROR]="255,105,180"       # 玫瑰红 #FF69B4
    [ACCENT]="221,160,221"      # 梅花紫 #DDA0DD
    [CYAN]="175,238,238"        # 粉蓝 #AFEEEE
)

# 5. Matrix Theme (黑客帝国)
typeset -A THEME_MATRIX=(
    [PRIMARY]="0,255,0"         # 矩阵绿 #00FF00
    [SUCCESS]="50,205,50"       # 石灰绿 #32CD32
    [WARNING]="173,255,47"      # 黄绿 #ADFF2F
    [ERROR]="0,255,127"         # 春绿 #00FF7F
    [ACCENT]="124,252,0"        # 草绿 #7CFC00
    [CYAN]="127,255,212"        # 碧绿 #7FFFD4
)

# 6. Gruvbox Theme (复古暖色)
typeset -A THEME_GRUVBOX=(
    [PRIMARY]="251,184,108"     # 橙色 #FBB86C
    [SUCCESS]="184,187,38"      # 绿色 #B8BB26
    [WARNING]="250,189,47"      # 黄色 #FABD2F
    [ERROR]="251,73,52"         # 红色 #FB4934
    [ACCENT]="211,134,155"      # 紫色 #D3869B
    [CYAN]="142,192,124"        # 青色 #8EC07C
)

# 7. Monokai Theme (经典暗黑)
typeset -A THEME_MONOKAI=(
    [PRIMARY]="102,217,239"     # 亮蓝 #66D9EF
    [SUCCESS]="166,226,46"      # 亮绿 #A6E22E
    [WARNING]="253,151,31"      # 橙色 #FD971F
    [ERROR]="249,38,114"        # 粉红 #F92672
    [ACCENT]="174,129,255"      # 紫色 #AE81FF
    [CYAN]="102,217,239"        # 青色 #66D9EF
)

# --- Color Application Functions / 颜色应用函数 ---

# 将RGB转换为ANSI 24位真彩色转义序列
rgb_to_ansi() {
    local rgb="$1"
    local r g b
    IFS=',' read -r r g b <<< "$rgb"
    echo "\033[38;2;${r};${g};${b}m"
}

# 背景色版本
rgb_to_ansi_bg() {
    local rgb="$1"
    local r g b
    IFS=',' read -r r g b <<< "$rgb"
    echo "\033[48;2;${r};${g};${b}m"
}

# 加载主题并设置全局颜色变量
load_theme() {
    local theme_name="$1"
    theme_name="${theme_name:u}"  # 转大写
    
    # 动态构造主题数组名
    local theme_array_name="THEME_${theme_name}"
    
    # 检查主题是否存在
    if ! typeset -p "$theme_array_name" &>/dev/null; then
        echo "⚠️  Theme '${theme_name}' not found, using DEFAULT"
        theme_array_name="THEME_DEFAULT"
    fi
    
    # 使用nameref获取主题数组
    local -A theme_data
    # 💡 Zsh动态关联数组引用技巧
    eval "theme_data=(\${(kv)${theme_array_name}})"
    
    # 设置全局颜色变量
    C_PRIMARY=$(rgb_to_ansi "${theme_data[PRIMARY]}")
    C_SUCCESS=$(rgb_to_ansi "${theme_data[SUCCESS]}")
    C_WARNING=$(rgb_to_ansi "${theme_data[WARNING]}")
    C_ERROR=$(rgb_to_ansi "${theme_data[ERROR]}")
    C_ACCENT=$(rgb_to_ansi "${theme_data[ACCENT]}")
    C_CYAN=$(rgb_to_ansi "${theme_data[CYAN]}")
    
    # 保持兼容旧变量名
    C_RED="$C_ERROR"
    C_GREEN="$C_SUCCESS"
    C_YELLOW="$C_WARNING"
    C_BLUE="$C_PRIMARY"
    C_PURPLE="$C_ACCENT"
    
    # 通用样式
    C_BOLD='\033[1m'
    C_DIM='\033[2m'
    C_ITALIC='\033[3m'
    C_UNDERLINE='\033[4m'
    C_RESET='\033[0m'
    
    export C_PRIMARY C_SUCCESS C_WARNING C_ERROR C_ACCENT C_CYAN
    export C_RED C_GREEN C_YELLOW C_BLUE C_PURPLE
    export C_BOLD C_DIM C_ITALIC C_UNDERLINE C_RESET
}

# 主题预览函数
preview_theme() {
    local theme_name="$1"
    load_theme "$theme_name"
    
    echo ""
    echo -e "${C_BOLD}═══ Theme Preview: ${theme_name} ═══${C_RESET}"
    echo ""
    echo -e "  ${C_PRIMARY}●${C_RESET} PRIMARY   - Main UI elements"
    echo -e "  ${C_SUCCESS}●${C_RESET} SUCCESS   - Compilation success messages"
    echo -e "  ${C_WARNING}●${C_RESET} WARNING   - Warning and prompts"
    echo -e "  ${C_ERROR}●${C_RESET} ERROR     - Error messages"
    echo -e "  ${C_ACCENT}●${C_RESET} ACCENT    - Decorative highlights"
    echo -e "  ${C_CYAN}●${C_RESET} CYAN      - Information text"
    echo ""
    echo -e "${C_PRIMARY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo ""
}

# 列出所有可用主题
list_themes() {
    echo ""
    echo -e "${C_BOLD}Available Themes:${C_RESET}"
    echo ""
    echo "  1. default   - Original color scheme"
    echo "  2. nord      - Nordic aurora theme (cool tones)"
    echo "  3. dracula   - Dracula vampire theme (purple/pink)"
    echo "  4. sakura    - Cherry blossom theme (warm pink)"
    echo "  5. matrix    - Matrix hacker theme (green)"
    echo "  6. gruvbox   - Retro warm color theme"
    echo "  7. monokai   - Classic dark theme"
    echo ""
}

# 默认加载Default主题
load_theme "default"
