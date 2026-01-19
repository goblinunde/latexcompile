# LaTeX Compiler Pro - 功能说明

## 📋 主菜单选项详解

### 1️⃣ [>>>] Quick Recompile (文件名)

**快速重编译上次文件，无需重新选择**

- **功能**：记住上次编译的文件和引擎配置，一键重新编译
- **适用场景**：反复修改文档内容时，省去重复选择的步骤
- **工作原理**：基于 `~/.latex_history` 编译历史记录
- **优势**：节省时间，提高效率

**示例流程**：

```
1. 首次编译 main.tex (选择XeLaTeX)
2. 修改文档内容
3. 选择 Quick Recompile → 自动用XeLaTeX重编译 main.tex
```

---

### 2️⃣ [F] Compile with project config

**使用 .latexcfg 批量编译多个文件**

- **功能**：读取项目配置文件，批量编译多个TeX文件
- **配置文件**：`.latexcfg` (当前目录)
- **适用场景**：大型项目，包含多个章节或文档
- **支持**：每个文件可设置不同的引擎和文献工具

**配置示例**：

```ini
TARGET_1_FILE = "chapter1.tex"
TARGET_1_ENGINE = "xelatex"
TARGET_1_BIB_TOOL = "biber"

TARGET_2_FILE = "chapter2.tex"
TARGET_2_ENGINE = "pdflatex"
TARGET_2_BIB_TOOL = "bibtex"
```

---

### 3️⃣ [+] Compile interactively

**交互式选择文件和编译引擎**

- **功能**：手动选择要编译的TeX文件和编译模式
- **灵活性**：每次都可以选择不同的引擎和选项
- **编译模式**：
  - Auto (推荐): Latexmk自动处理
  - Live: 实时预览模式
  - Manual: 手动控制每一步

**支持的引擎**：

- XeLaTeX (推荐中文文档)
- PDFLaTeX (经典引擎)
- LuaLaTeX (现代引擎)

---

### 4️⃣ [=] Word Count & Statistics

**统计文档字数、公式和图表数量**

- **功能**：使用 `texcount` 工具分析LaTeX文档
- **统计项**：
  - 正文字数
  - 标题字数
  - 数学公式数量
  - 图表数量
  - 章节数量

**前置条件**：

```bash
sudo dnf install texcount
```

---

### 5️⃣ [@] Compilation History

**查看最近的编译记录（成功/失败）**

- **功能**：显示最近10次编译的详细记录
- **信息包含**：
  - 编译时间戳
  - 文件名
  - 使用的引擎
  - 成功/失败状态
- **存储位置**：`~/.latex_history`

**显示格式**：

```
1. [OK] main.tex (xelatex) - 2026-01-19T17:00:00
2. [X]  report.tex (pdflatex) - 2026-01-19T16:30:00
```

---

### 6️⃣ [*] Create/Update Config (.latexcfg)

**创建项目配置文件，支持批量编译**

- **功能**：交互式向导，创建项目批量编译配置
- **步骤**：
  1. 选择要编译的TeX文件
  2. 为每个文件选择引擎
  3. 选择文献处理工具
  4. 保存到 `.latexcfg`
- **可选**：添加多个编译目标

---

### 7️⃣ [#] Settings & Themes

**修改主题、引擎等全局配置**

- **主题切换**：7种预设主题实时预览
- **全局设置**：
  - 默认编译引擎
  - 自动清理选项
  - PDF自动打开
  - 编译历史启用
  - PDF查看器
- **配置文件**：`~/.latexrc`

**预设主题**：

- default, nord, dracula, sakura, matrix, gruvbox, monokai

---

### 8️⃣ [~] Clean auxiliary files

**清理 .aux .log 等辅助文件**

- **功能**：删除LaTeX编译产生的辅助文件
- **清理文件类型**：
  - `.aux`, `.log`, `.out`, `.toc`
  - `.synctex.gz`, `.fls`, `.fdb_latexmk`
  - `.bbl`, `.blg`, `.bcf`
  - 等30+种辅助文件
- **安全确认**：删除前显示文件列表，需要确认

---

### 9️⃣ [Q] Quit

**退出程序**

- **功能**：安全退出脚本
- **保留**：所有配置和历史记录

---

## 🔧 配置文件说明

### ~/.latexrc (用户全局配置)

```ini
[General]
default_engine = xelatex      # 默认引擎
auto_cleanup = false          # 编译后自动清理
auto_open_pdf = true          # 自动打开PDF

[Theme]
active_theme = nord           # 当前主题

[Features]
enable_history = true         # 启用历史
max_history = 10              # 历史条目数
```

### .latexcfg (项目批量编译配置)

```ini
TARGET_1_FILE = "main.tex"
TARGET_1_ENGINE = "xelatex"
TARGET_1_BIB_TOOL = "biber"
```

### ~/.latex_history (编译历史记录)

```
格式：时间戳|文件|引擎|成功/失败
2026-01-19T17:00:00+08:00|main.tex|xelatex|true
```

---

## 💡 使用技巧

### 快速工作流

1. 首次编译：使用 **Compile interactively** 选择配置
2. 后续修改：使用 **Quick Recompile** 快速重编译
3. 大型项目：使用 **Create Config** 设置批量编译

### 最佳实践

- 经常使用 **Clean** 清理辅助文件
- 定期查看 **History** 了解编译状态
- 根据喜好切换 **Themes** 提升体验
