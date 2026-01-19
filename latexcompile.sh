#!/bin/zsh

# ==============================================================================
#
#   texcompile.sh - 专业级 LaTeX 交互式编译脚本 (旗舰版 v5.2)
#
#   更新日志 v5.2:
#   1. 修复: 配置文件生成向导中的换行符问题 (生成真正的换行而非 literal \n)。
#   2. 修复: 增强配置解析器，解决因换行符(CRLF)或文件尾缺失换行导致的读取失败问题。
#   3. 优化: 使用 Zsh 原生数组处理文件流，解析更稳健。
#
# ==============================================================================


# --- Script Metadata / 脚本元数据 ---
readonly SCRIPT_VERSION="6.0"
readonly SCRIPT_DIR="${0:a:h}"  # 💡 Zsh特性: 获取脚本所在目录的绝对路径

# --- Load External Modules / 加载外部模块 ---
source "${SCRIPT_DIR}/themes.sh" 2>/dev/null || {
    echo "Error: themes.sh not found in ${SCRIPT_DIR}"
    exit 1
}

source "${SCRIPT_DIR}/ui_components.sh" 2>/dev/null || {
    echo "Error: ui_components.sh not found in ${SCRIPT_DIR}"
    exit 1
}

# --- Global Config Variables / 全局配置变量 ---
CONFIG_FILE=".latexcfg"          # 项目配置 (批量编译)
USER_CONFIG="$HOME/.latexrc"      # 用户全局配置
HISTORY_FILE="$HOME/.latex_history"  # 编译历史记录

# 用户配置变量 (从 .latexrc 读取)
CFG_DEFAULT_ENGINE="xelatex"
CFG_AUTO_CLEANUP=false
CFG_EDITOR="nvim"
CFG_AUTO_OPEN_PDF=true
CFG_ACTIVE_THEME="nord"
CFG_ENABLE_HISTORY=true
CFG_MAX_HISTORY=10
CFG_PDF_VIEWER=""

# 项目批量编译配置 (兼容v5.2格式)
typeset -A CFG_TARGETS
CFG_TARGET_COUNT=0
HAS_CONFIG=false

# OS 相关变量
CURRENT_OS="unknown"
OPEN_CMD=""

# --- User Config Management / 用户配置管理 ---

detect_os() {
    local kernel_name=$(uname -s)
    case "$kernel_name" in
        Darwin*)
            CURRENT_OS="macOS"
            OPEN_CMD="open"
            ;;
        Linux*)
            # 检测是否为 WSL (Windows Subsystem for Linux)
            if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
                CURRENT_OS="WSL"
                # WSL 下优先尝试 wslview (wslu)，否则使用 explorer.exe
                if command -v wslview &> /dev/null; then
                    OPEN_CMD="wslview"
                else
                    OPEN_CMD="explorer.exe"
                fi
            else
                CURRENT_OS="Linux"
                OPEN_CMD="xdg-open"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            CURRENT_OS="Windows (Git Bash)"
            OPEN_CMD="start"
            ;;
        *)
            CURRENT_OS="Unknown"
            OPEN_CMD=""
            ;;
    esac
}

# 初始化用户配置文件
init_user_config() {
    if [[ ! -f "$USER_CONFIG" ]]; then
        print_info "Creating default user config at ${USER_CONFIG}..."
        cp "${SCRIPT_DIR}/.latexrc.template" "$USER_CONFIG" 2>/dev/null || {
            echo "Warning: Could not create user config. Using defaults."
            return 1
        }
    fi
}

# 读取用户配置 (.latexrc)
load_user_config() {
    [[ ! -f "$USER_CONFIG" ]] && return
    
    # 💡 简单的INI解析器 (仅支持key=value格式)
    local current_section=""
    while IFS='=' read -r key value; do
        # 移除首尾空格
        key="${key## }"
        key="${key%% }"
        value="${value## }"
        value="${value%% }"
        
        # 跳过注释和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # 检测section标题 [Section]
        if [[ "$key" =~ ^\[(.*)\]$ ]]; then
            current_section="${match[1]}"
            continue
        fi
        
        # 根据section解析配置
        case "$current_section" in
            General)
                case "$key" in
                    default_engine) CFG_DEFAULT_ENGINE="$value" ;;
                    auto_cleanup) [[ "$value" == "true" ]] && CFG_AUTO_CLEANUP=true || CFG_AUTO_CLEANUP=false ;;
                    editor) CFG_EDITOR="$value" ;;
                    auto_open_pdf) [[ "$value" == "true" ]] && CFG_AUTO_OPEN_PDF=true || CFG_AUTO_OPEN_PDF=false ;;
                esac
                ;;
            Theme)
                [[ "$key" == "active_theme" ]] && CFG_ACTIVE_THEME="$value"
                ;;
            Features)
                case "$key" in
                    enable_history) [[ "$value" == "true" ]] && CFG_ENABLE_HISTORY=true || CFG_ENABLE_HISTORY=false ;;
                    max_history) CFG_MAX_HISTORY="$value" ;;
                esac
                ;;
            PDF)
                [[ "$key" == "viewer" ]] && CFG_PDF_VIEWER="$value"
                ;;
        esac
    done < "$USER_CONFIG"
    
    # 加载用户选择的主题
    load_theme "$CFG_ACTIVE_THEME"
}

# --- Helper Functions / 辅助功能函数 ---

# 编译后自动打开 PDF
open_pdf() {
    local pdf_file="$1"
    if [[ ! -f "$pdf_file" ]]; then
        return
    fi

    # 根据配置决定是否自动打开
    if [[ "$CFG_AUTO_OPEN_PDF" == "false" ]]; then
        return
    fi

    if ! prompt_confirm "Open generated PDF (${CURRENT_OS})?" "y"; then
        return
    fi

    # 优先使用用户配置的查看器
    local viewer_cmd="${CFG_PDF_VIEWER:-$OPEN_CMD}"
    
    if [[ -n "$viewer_cmd" ]]; then
        print_info "Opening with: ${viewer_cmd}"
        $viewer_cmd "$pdf_file" &>/dev/null &
    else
        print_warning "Could not detect PDF viewer on ${CURRENT_OS}"
    fi
}

# 增强的清理函数
clstex() {
    local target_files=()
    local extensions=(
        aux log out toc lof lot synctex.gz fls fdb_latexmk
        bbl blg bcf bit idx ilg ind glo gls glg run.xml dvi ptc
        nav snm vrb thm xdy
    )
    
    if (( $# > 0 )); then
        for base_name in "$@"; do
            base_name="${base_name%.tex}"
            for ext in "${extensions[@]}"; do
                if [[ -f "${base_name}.${ext}" ]]; then
                    target_files+=("${base_name}.${ext}")
                fi
            done
        done
    else
        for ext in "${extensions[@]}"; do
            target_files+=(*."${ext}"(N))
        done
    fi

    if (( ${#target_files[@]} == 0 )); then
        echo -e "${C_GREEN}==> No LaTeX auxiliary files found to clean.${C_RESET}"
        return 0
    fi

    echo -e "${C_YELLOW}==> The following ${C_BOLD}${#target_files[@]}${C_RESET}${C_YELLOW} files will be deleted:${C_RESET}"
    if (( ${#target_files[@]} > 10 )); then
        print -l "${target_files[@]:0:10}"
        echo "... and $((${#target_files[@]} - 10)) more."
    else
        print -l "${target_files[@]}"
    fi

    print -n "${C_RED}${C_BOLD}Are you sure? [y/n] ${C_RESET}"
    read -q REPLY
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        rm -f "${target_files[@]}"
        echo -e "\n${C_GREEN}==> Cleanup complete! Removed ${C_BOLD}${#target_files[@]}${C_RESET}${C_GREEN} files.${C_RESET}"
    else
        echo -e "\n${C_BLUE}==> Operation canceled.${C_RESET}"
    fi
}

# 编译失败时显示日志
show_log_error() {
    local log_file="$1"
    if [[ ! -f "$log_file" ]]; then return; fi
    
    print -n "${C_RED}View end of log file ${log_file} to locate errors? [y/n] ${C_RESET}"
    read -q REPLY
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo -e "${C_YELLOW}--- Last 25 lines of ${log_file} ---${C_RESET}"
        tail -n 25 "${log_file}"
        echo -e "${C_YELLOW}------------------------------------${C_RESET}"
    fi
}

# --- Parsing Config / 配置文件解析 ---

read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${C_CYAN}Reading configuration from ${CONFIG_FILE}...${C_RESET}"
        
        # 重置配置
        CFG_TARGETS=()
        CFG_TARGET_COUNT=0
        local max_idx=0

        # V5.1 FIX: 使用 Zsh 原生数组读取，彻底解决换行符和 read 循环退出的问题
        # 1. cat 读取内容
        # 2. tr -d '\r' 删除 Windows 回车符
        # 3. "${(@f)...}" 按行分割到 lines 数组
        local file_content=$(cat "$CONFIG_FILE" | tr -d '\r')
        local -a lines=("${(@f)file_content}")

        for line in "${lines[@]}"; do
            # 忽略注释和空行 (更加健壮的正则)
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line//[[:space:]]/}" ]] && continue
            
            # 分割 key 和 value (使用参数扩展，不依赖 IFS)
            local key="${line%%=*}"
            local value="${line#*=}"
            
            # Trim spaces
            key="${key#"${key%%[![:space:]]*}"}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}" 
            value="${value%"${value##*[![:space:]]}"}" 
            
            # Remove quotes
            value=${value#[\"\']}
            value=${value%[\"\']}

            # 解析逻辑
            if [[ "$key" == "MAIN_FILE" ]]; then
                # 兼容旧版配置
                if [[ -z "${CFG_TARGETS[1,FILE]}" ]]; then
                    CFG_TARGETS[1,FILE]="$value"
                    [[ $max_idx -lt 1 ]] && max_idx=1
                fi
            elif [[ "$key" == "ENGINE" ]]; then
                 if [[ -z "${CFG_TARGETS[1,ENGINE]}" ]]; then
                    CFG_TARGETS[1,ENGINE]="$value"
                fi
            elif [[ "$key" == "BIB_TOOL" ]]; then
                 if [[ -z "${CFG_TARGETS[1,BIB_TOOL]}" ]]; then
                    CFG_TARGETS[1,BIB_TOOL]="$value"
                fi
            # 新版批量解析: TARGET_n_KEY
            elif [[ "$key" =~ ^TARGET_([0-9]+)_(FILE|ENGINE|BIB_TOOL)$ ]]; then
                local idx=${match[1]}
                local field=${match[2]}
                CFG_TARGETS[$idx,$field]="$value"
                if (( idx > max_idx )); then max_idx=$idx; fi
            fi
        done

        CFG_TARGET_COUNT=$max_idx

        if (( CFG_TARGET_COUNT > 0 )); then
            HAS_CONFIG=true
            echo -e "  -> Detected ${C_BOLD}${CFG_TARGET_COUNT}${C_RESET} compilation targets."
        else
            echo -e "${C_RED}  -> Config file found but no valid targets detected. Check syntax.${C_RESET}"
            HAS_CONFIG=false
        fi
    else
        HAS_CONFIG=false
    fi
}

# --- Config Generator / 配置文件生成向导 ---

generate_config_template() {
    echo -e "\n${C_PURPLE}=== Generate Batch Project Configuration (.latexcfg) ===${C_RESET}"
    echo -e "${C_CYAN}This wizard creates a config file supporting multiple files with individual settings.${C_RESET}"

    local files=(*.tex(N))
    if (( ${#files[@]} == 0 )); then
        echo -e "${C_RED}No .tex files found! Cannot generate config.${C_RESET}"
        return
    fi

    local temp_config_content=""
    local idx=1
    
    while true; do
        echo -e "\n${C_BOLD}--- Configuring Target #${idx} ---${C_RESET}"
        
        # 1. Select File
        local selected_file=""
        echo -e "${C_BOLD}Select TeX file for Target #${idx}:${C_RESET}"
        select f in "${files[@]}"; do
            if [[ -n "$f" ]]; then selected_file="$f"; break; fi
        done

        # 2. Select Engine
        local selected_engine=""
        echo -e "${C_BOLD}Select engine for ${selected_file}:${C_RESET}"
        select e in "xelatex" "pdflatex" "lualatex"; do
            if [[ -n "$e" ]]; then selected_engine="$e"; break; fi
        done

        # 3. Select Bib Tool
        local selected_bib=""
        echo -e "${C_BOLD}Select bib tool for ${selected_file}:${C_RESET}"
        select b in "none" "biber" "bibtex"; do
            if [[ -n "$b" ]]; then selected_bib="$b"; break; fi
        done
        [[ "$selected_bib" == "none" ]] && selected_bib=""

        # Append to config buffer (V5.2 Fix: Use $'\n' for real newlines)
        temp_config_content+=$'\n'"TARGET_${idx}_FILE = \"${selected_file}\""
        temp_config_content+=$'\n'"TARGET_${idx}_ENGINE = \"${selected_engine}\""
        temp_config_content+=$'\n'"TARGET_${idx}_BIB_TOOL = \"${selected_bib}\""

        # 4. Continue?
        echo -e "\n${C_BLUE}Do you want to add another file? [y/n]${C_RESET}"
        read -q REPLY
        echo
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            break
        fi
        ((idx++))
    done

    # Write File
    echo -e "\n${C_YELLOW}Writing to ${CONFIG_FILE}...${C_RESET}"
    
    cat > "$CONFIG_FILE" <<EOF
# LaTeX Project Configuration (Batch Mode)
# Generated by texcompile.sh

# This format is compatible with Bash, Zsh, and PowerShell (ConvertFrom-StringData).
# Format: TARGET_{index}_{KEY} = "VALUE"
${temp_config_content}
EOF

    echo -e "${C_GREEN}Configuration file created successfully!${C_RESET}"
    read_config # Reload config immediately
}

# --- Compilation Logic / 编译逻辑 ---

# 核心编译执行器 (Latexmk)
compile_latexmk() {
    local engine_flag="$1"
    local base_name="$2"
    local do_clean="$3" # "autoclean" or empty
    local tex_file="${base_name}.tex"
    
    # 提取引擎名称用于历史记录
    local engine_name="xelatex"
    case "$engine_flag" in
        -pdf) engine_name="pdflatex" ;;
        -lualatex) engine_name="lualatex" ;;
    esac
    
    show_compile_status "$tex_file" "$engine_name" 1
    
    local cmd=(latexmk "$engine_flag" -synctex=1 -file-line-error -interaction=nonstopmode -halt-on-error)
    "${cmd[@]}" "$tex_file"

    if [ $? -eq 0 ]; then
        print_success "Successfully compiled: ${base_name}.pdf"
        save_to_history "$tex_file" "$engine_name" "true"
        open_pdf "${base_name}.pdf"
        
        if [[ "$do_clean" == "autoclean" ]] || [[ "$CFG_AUTO_CLEANUP" == "true" ]]; then
            latexmk -c "$tex_file"
        else
             if prompt_confirm "Run cleanup (latexmk -c)?" "n"; then
                 latexmk -c "$tex_file"
             fi
        fi
    else 
        print_error "Latexmk compilation failed!"
        save_to_history "$tex_file" "$engine_name" "false"
        show_log_error "${base_name}.log"
        return 1
    fi
}

# 辅助：根据配置执行单个任务
run_target_task() {
    local idx="$1"
    local filename="${CFG_TARGETS[$idx,FILE]}"
    local engine="${CFG_TARGETS[$idx,ENGINE]}"
    local bib="${CFG_TARGETS[$idx,BIB_TOOL]}" # 目前主要给 manual chain 用，latexmk 会自动探测

    if [[ -z "$filename" ]]; then
        echo -e "${C_RED}Error: Target #$idx is missing filename.${C_RESET}"
        return
    fi
    
    local base_name="${filename%.tex}"
    local flag="-${engine}" # xelatex -> -xelatex
    if [[ "$engine" == "pdflatex" ]]; then flag="-pdf"; fi
    
    # 目前默认使用 latexmk，若需支持配置中的 bib_tool 强制手动链，可在此扩展
    compile_latexmk "$flag" "$base_name"
}

# 批量执行所有配置
compile_all_targets() {
    echo -e "\n${C_PURPLE}=== Starting Batch Compilation (${CFG_TARGET_COUNT} targets) ===${C_RESET}"
    for ((i=1; i<=CFG_TARGET_COUNT; i++)); do
        echo -e "\n${C_CYAN}>>> Processing Target #$i${C_RESET}"
        run_target_task "$i"
    done
    echo -e "\n${C_GREEN}=== Batch Compilation Finished ===${C_RESET}"
}

# 使用配置编译 - 菜单
compile_with_config() {
    if (( CFG_TARGET_COUNT == 0 )); then
        echo -e "${C_RED}No targets defined in config.${C_RESET}"
        return
    fi

    # 如果只有一个目标，直接编译
    if (( CFG_TARGET_COUNT == 1 )); then
        run_target_task 1
        return
    fi

    # 如果有多个目标，显示选择菜单
    echo -e "\n${C_BOLD}Multi-target config detected. Choose action:${C_RESET}"
    
    # 构造菜单数组
    local target_menu=("!! Compile ALL Targets !!")
    for ((i=1; i<=CFG_TARGET_COUNT; i++)); do
        local fname="${CFG_TARGETS[$i,FILE]}"
        local eng="${CFG_TARGETS[$i,ENGINE]}"
        target_menu+=("Target #$i: $fname ($eng)")
    done
    target_menu+=("!! Go Back !!")

    select t_choice in "${target_menu[@]}"; do
        case "$t_choice" in
            "!! Go Back !!") return ;;
            "!! Compile ALL Targets !!") compile_all_targets; break ;;
            *)
                # 提取 Target 编号
                if [[ "$t_choice" =~ Target\ #([0-9]+) ]]; then
                    local t_idx=${match[1]}
                    run_target_task "$t_idx"
                    break
                else
                    echo -e "${C_RED}Invalid selection.${C_RESET}"
                fi
                ;;
        esac
    done
}

# 手动编译链 (Manual Chain - 备用方案)
compile_manual_chain() {
    local compiler="$1"
    local bib_tool="$2"
    local base_name="$3"
    
    echo -e "\n${C_PURPLE}===== Manual Chain: ${compiler} -> ${bib_tool} -> ${compiler} x2 =====${C_RESET}"
    
    echo -e "${C_YELLOW}[1/4] Running ${compiler} (Pass 1)...${C_RESET}"
    $compiler -interaction=nonstopmode -halt-on-error "${base_name}.tex" || { show_log_error "${base_name}.log"; return 1; }

    if [[ "$bib_tool" != "none" ]]; then
        echo -e "${C_YELLOW}[2/4] Running ${bib_tool}...${C_RESET}"
        if [[ "$bib_tool" == "biber" ]]; then
            biber "${base_name}"
        elif [[ "$bib_tool" == "bibtex" ]]; then
            bibtex "${base_name}"
        fi
        if [ $? -ne 0 ]; then echo -e "${C_RED}Warning: ${bib_tool} exited with errors.${C_RESET}"; fi
    else
        echo -e "${C_YELLOW}[2/4] Skipping bibliography step...${C_RESET}"
    fi

    echo -e "${C_YELLOW}[3/4] Running ${compiler} (Pass 2)...${C_RESET}"
    $compiler -interaction=nonstopmode -halt-on-error "${base_name}.tex" > /dev/null
    
    echo -e "${C_YELLOW}[4/4] Running ${compiler} (Pass 3)...${C_RESET}"
    $compiler -interaction=nonstopmode -halt-on-error "${base_name}.tex"
    
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}===== Manual Compilation Success =====${C_RESET}"
        open_pdf "${base_name}.pdf"
    else
        echo -e "${C_RED}Error: Final compilation pass failed!${C_RESET}"
        show_log_error "${base_name}.log"
    fi
}

# 实时预览 (pvc)
compile_pvc() {
    local engine_flag="$1"
    local base_name="$2"
    echo -e "\n${C_BLUE}===== Starting live preview for ${C_BOLD}${base_name}.tex${C_RESET}${C_BLUE} =====${C_RESET}"
    echo -e "${C_YELLOW}Watching for file changes... Press Ctrl+C to stop.${C_RESET}"
    latexmk "${engine_flag}" -pvc -synctex=1 -interaction=nonstopmode -halt-on-error "${base_name}.tex"
}

# 交互式选择逻辑 (非 Config 模式)
interactive_compile_logic() {
    local files=(*.tex(N)) 
    if (( ${#files[@]} == 0 )); then echo -e "${C_RED}Error: No .tex files found.${C_RESET}"; return; fi
    
    local targets=()
    echo -e "${C_BOLD}Select a TeX file to compile:${C_RESET}"
    local menu_items=("${files[@]}" "!! Compile All !!" "!! Go Back !!")
    
    select file_choice in "${menu_items[@]}"; do
        case "$file_choice" in 
            "!! Go Back !!") return ;; 
            "!! Compile All !!") targets=("${files[@]}"); break ;; 
            *) if [[ -n "$file_choice" ]]; then targets=("$file_choice"); break; fi ;;
        esac
    done

    echo -e "\n${C_BOLD}Select Compilation Mode:${C_RESET}"
    local modes=(
        "Auto: Latexmk (XeLaTeX) [Recommended]"
        "Auto: Latexmk (PDFLaTeX)"
        "Auto: Latexmk (LuaLaTeX)"
        "Live: Preview Mode (XeLaTeX)"
        "Manual: XeLaTeX + Biber"
        "Manual: XeLaTeX + BibTeX"
        "Manual: PDFLaTeX + BibTeX"
        "!! Go Back !!"
    )

    select mode in "${modes[@]}"; do
        case "$mode" in
            "!! Go Back !!") return ;;
            "Auto: Latexmk (XeLaTeX) [Recommended]")
                for t in "${targets[@]}"; do compile_latexmk "-xelatex" "${t%.tex}"; done; break ;;
            "Auto: Latexmk (PDFLaTeX)")
                for t in "${targets[@]}"; do compile_latexmk "-pdf" "${t%.tex}"; done; break ;;
            "Auto: Latexmk (LuaLaTeX)")
                for t in "${targets[@]}"; do compile_latexmk "-lualatex" "${t%.tex}"; done; break ;;
            "Live: Preview Mode (XeLaTeX)")
                compile_pvc "-xelatex" "${targets[0]%.tex}"; break ;;
            "Manual: XeLaTeX + Biber")
                for t in "${targets[@]}"; do compile_manual_chain "xelatex" "biber" "${t%.tex}"; done; break ;;
            "Manual: XeLaTeX + BibTeX")
                for t in "${targets[@]}"; do compile_manual_chain "xelatex" "bibtex" "${t%.tex}"; done; break ;;
            "Manual: PDFLaTeX + BibTeX")
                for t in "${targets[@]}"; do compile_manual_chain "pdflatex" "bibtex" "${t%.tex}"; done; break ;;
            *) echo -e "${C_RED}Invalid selection.${C_RESET}" ;;
        esac
    done
}

# --- Settings & History Management / 设置和历史管理 ---

# 保存编译历史记录
save_to_history() {
    [[ "$CFG_ENABLE_HISTORY" == "false" ]] && return
    
    local file="$1"
    local engine="$2"
    local success="$3"
    local timestamp=$(date -Iseconds)
    
    # 创建历史条目
    local entry="${timestamp}|${file}|${engine}|${success}"
    
    # 读取现有历史 (最多保留MAX_HISTORY条)
    local -a history_lines=()
    [[ -f "$HISTORY_FILE" ]] && history_lines=("${(@f)$(cat "$HISTORY_FILE")}")
    
    # 添加新条目并限制数量
    history_lines=("$entry" "${history_lines[@]}")
    history_lines=("${history_lines[@]:0:$CFG_MAX_HISTORY}")
    
    # 写回文件
    printf '%s\n' "${history_lines[@]}" > "$HISTORY_FILE"
}

# 显示编译历史
show_history() {
    if [[ ! -f "$HISTORY_FILE" ]] || [[ ! -s "$HISTORY_FILE" ]]; then
        print_warning "No compilation history found."
        return
    fi
    
    draw_header "Compilation History" "Last ${CFG_MAX_HISTORY} compilations"
    
    local -a history_lines=("${(@f)$(cat "$HISTORY_FILE")}")
    local i=1
    
    for line in "${history_lines[@]}"; do
        IFS='|' read -r timestamp file engine success <<< "$line"
        local status_icon="${ICON_CHECK}"
        local status_color="$C_SUCCESS"
        [[ "$success" == "false" ]] && status_icon="${ICON_CROSS}" && status_color="$C_ERROR"
        
        echo -e "  ${C_DIM}${i}.${C_RESET} ${status_color}${status_icon}${C_RESET} ${C_ACCENT}${file}${C_RESET} ${C_DIM}(${engine})${C_RESET} - ${C_DIM}${timestamp}${C_RESET}"
        ((i++))
    done
    
    echo ""
}

# 快速重编译 (最近一次)
quick_recompile() {
    if [[ ! -f "$HISTORY_FILE" ]] || [[ ! -s "$HISTORY_FILE" ]]; then
        print_error "No compilation history available."
        return
    fi
    
    # 读取最近一条记录
    local last_entry=$(head -n 1 "$HISTORY_FILE")
    IFS='|' read -r timestamp file engine success <<< "$last_entry"
    
    if [[ ! -f "$file" ]]; then
        print_error "File ${file} no longer exists."
        return
    fi
    
    print_info "Recompiling: ${C_ACCENT}${file}${C_RESET} with ${C_PRIMARY}${engine}${C_RESET}"
    
    local base_name="${file%.tex}"
    local flag="-${engine}"
    [[ "$engine" == "pdflatex" ]] && flag="-pdf"
    
    compile_latexmk "$flag" "$base_name"
}

# 字数统计 (需要texcount)
word_count_report() {
    if ! command -v texcount &>/dev/null; then
        print_error "texcount not installed. Install it with: sudo dnf install texcount"
        return
    fi
    
    local files=(*.tex(N))
    if (( ${#files[@]} == 0 )); then
        print_error "No .tex files found."
        return
    fi
    
    echo ""
    print_info "Select a file for word count:"
    select file in "${files[@]}" "!! Cancel !!"; do
        [[ "$file" == "!! Cancel !!" ]] && return
        if [[ -n "$file" ]]; then
            draw_header "Word Count Report" "$file"
            texcount -brief -q "$file"
            echo ""
            break
        fi
    done
}

# 主题选择器
theme_selector() {
    while true; do
        draw_header "Theme Selector" "Choose your color scheme"
        list_themes
        
        local themes=(default nord dracula sakura matrix gruvbox monokai "Preview Current" "!! Back !!")
        select theme in "${themes[@]}"; do
            case "$theme" in
                "!! Back !!") return ;;
                "Preview Current")
                    preview_theme "$CFG_ACTIVE_THEME"
                    break
                    ;;
                "")
                    print_error "Invalid selection"
                    break
                    ;;
                *)
                    CFG_ACTIVE_THEME="$theme"
                    load_theme "$theme"
                    preview_theme "$theme"
                    
                    # 保存到配置文件
                    if [[ -f "$USER_CONFIG" ]]; then
                        sed -i "s/^active_theme = .*/active_theme = ${theme}/" "$USER_CONFIG"
                        print_success "Theme saved to ${USER_CONFIG}"
                    fi
                    break
                    ;;
            esac
        done
    done
}

# 设置菜单
settings_menu() {
    while true; do
        draw_header "Settings & Configuration" "Customize your experience"
        
        # 显示当前配置
        echo -e "${C_ACCENT}${ICON_SETTINGS}  Current Settings:${C_RESET}\n"
        draw_table_2col \
            "Theme:${CFG_ACTIVE_THEME}" \
            "Default Engine:${CFG_DEFAULT_ENGINE}" \
            "Auto Cleanup:${CFG_AUTO_CLEANUP}" \
            "Auto Open PDF:${CFG_AUTO_OPEN_PDF}" \
            "History Enabled:${CFG_ENABLE_HISTORY}"
        
        echo ""
        local menu_items=(
            "${ICON_PALETTE}  Change Theme"
            "${ICON_SETTINGS}  Edit Config File"
            "${ICON_FILE}  Reset to Defaults"
            "${ICON_DOOR}  Back to Main Menu"
        )
        
        select choice in "${menu_items[@]}"; do
            case "$choice" in
                *"Change Theme") theme_selector; break ;;
                *"Edit Config File")
                    if [[ -f "$USER_CONFIG" ]]; then
                        ${CFG_EDITOR:-nvim} "$USER_CONFIG"
                        load_user_config  # 重新加载
                        print_success "Config reloaded!"
                    fi
                    break
                    ;;
                *"Reset to Defaults")
                    if prompt_confirm "Reset all settings to defaults?" "n"; then
                        rm -f "$USER_CONFIG"
                        init_user_config
                        load_user_config
                        print_success "Settings reset to defaults"
                    fi
                    break
                    ;;
                *"Back to Main Menu") return ;;
                *) print_error "Invalid selection"; break ;;
            esac
        done
    done
}

# --- Script Entry Point ---

detect_os
init_user_config
load_user_config  # 这会自动加载主题

if ! command -v latexmk &> /dev/null; then
    print_error "CRITICAL ERROR: 'latexmk' command not found."
    echo "Install it with: sudo dnf install latexmk"
    exit 1
fi

# CLI Mode
if [[ $# -gt 0 ]]; then
    main_file_arg=""
    engine_arg="xelatex" 
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -e|--engine) engine_arg="$2"; shift ;;
            -h|--help) echo "Usage: $0 [file.tex] [-e xelatex]"; exit 0 ;;
            *) main_file_arg="$1" ;;
        esac
        shift
    done
    [[ -z "$main_file_arg" ]] && { echo "Error: No file."; exit 1; }
    case "$engine_arg" in
        pdflatex) flag="-pdf" ;; lualatex) flag="-lualatex" ;; *) flag="-xelatex" ;;
    esac
    compile_latexmk "$flag" "${main_file_arg%.tex}" "autoclean"
    exit 0
fi

# Interactive Mode
read_config  # 读取项目配置 (.latexcfg)

# 显示欢迎Logo (只显示一次)
show_logo "v${SCRIPT_VERSION}"

while true; do
    draw_header "LaTeX Compiler Pro" "v${SCRIPT_VERSION} • ${CURRENT_OS} • Theme: ${CFG_ACTIVE_THEME}"
    
    # 构建动态菜单
    local menu_items=()
    
    # 如果有历史记录，显示快速重编译
    if [[ -f "$HISTORY_FILE" ]] && [[ -s "$HISTORY_FILE" ]]; then
        local last_entry=$(head -n 1 "$HISTORY_FILE")
        IFS='|' read -r timestamp file engine success <<< "$last_entry"
        menu_items+=("${ICON_ROCKET}  Quick Recompile (${file})")
    fi
    
    # 项目配置优先
    if $HAS_CONFIG; then
        menu_items+=("${ICON_FILE}  Compile with project config")
    fi
    
    # 核心功能
    menu_items+=(
        "${ICON_TEMPLATE}  Compile interactively"
        "${ICON_STATS}  Word Count & Statistics"
        "${ICON_HISTORY}  Compilation History"
        "${ICON_SETTINGS}  Create/Update Config (.latexcfg)"
        "${ICON_PALETTE}  Settings & Themes"
        "${ICON_CLEAN}  Clean auxiliary files"
        "${ICON_DOOR}  Quit"
    )

    select main_choice in "${menu_items[@]}"; do
        case "$main_choice" in
            *"Quick Recompile"*) quick_recompile; break ;;
            *"Compile with project config") compile_with_config; break ;;
            *"Compile interactively") interactive_compile_logic; break ;;
            *"Word Count"*) word_count_report; break ;;
            *"Compilation History") show_history; break ;;
            *"Create/Update Config"*) generate_config_template; break ;;
            *"Settings & Themes") settings_menu; break ;;
            *"Clean auxiliary files") clstex; break ;;
            *"Quit")
                echo ""
                print_success "Goodbye!"
                exit 0
                ;;
            *) print_error "Invalid selection" ;;
        esac
    done
done
