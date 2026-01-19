# LaTeX Compiler Pro v6.0 - 完整使用教程

## 📚 目录

1. [快速开始](#快速开始)
2. [基础使用](#基础使用)
3. [高级功能详解](#高级功能详解)
4. [实战案例](#实战案例)
5. [常见问题](#常见问题)
6. [最佳实践](#最佳实践)

---

## 快速开始

### 第一次使用

```bash
# 1. 进入脚本目录
cd /home/yyt/Downloads/sh

# 2. 运行脚本（首次会自动创建配置）
./latexcompile-standalone.sh

# 3. 会出现主菜单，选择你需要的功能
```

**首次运行会自动创建**：

- `~/.latexrc` - 全局配置文件
- `~/.latex_templates/` - 自定义模板目录

---

## 基础使用

### 场景1：编译单个LaTeX文件

**方法1：命令行快速编译**

```bash
# 使用默认引擎（xelatex）
./latexcompile-standalone.sh document.tex

# 指定引擎
./latexcompile-standalone.sh document.tex -e pdflatex
./latexcompile-standalone.sh document.tex -e lualatex
```

**方法2：交互式编译**

```bash
./latexcompile-standalone.sh

# 选择菜单：3) [+] Compile interactively
# 1. 选择要编译的.tex文件
# 2. 选择编译模式（推荐Auto - XeLaTeX）
# 3. 等待编译完成
# 4. 选择是否打开PDF
```

---

### 场景2：反复修改调试

**使用Quick Recompile功能**：

```bash
# 第一次编译你的文件
./latexcompile-standalone.sh

选择：3) [+] Compile interactively
选择文件：paper.tex
选择引擎：XeLaTeX
[编译成功]

# 修改文件内容后...

./latexcompile-standalone.sh

选择：1) [>>>] Quick Recompile (paper.tex)
[直接使用XeLaTeX重新编译，无需重复选择]

# 再次修改后...
选择：1) [>>>] Quick Recompile
[继续快速编译]
```

**好处**：每次只需选一个选项，节省时间！

---

### 场景3：从模板开始新文档

```bash
./latexcompile-standalone.sh

# 选择：4) [T] Generate Template

可选模板：
1) Article (学术论文) - 适合发表论文
2) Beamer (演示幻灯片) - 适合做presentation
3) Book (书籍/论文) - 适合毕业论文
4) Homework (作业模板) - 适合提交作业
5) Letter (信件) - 正式信函
6) CV/Resume (简历) - 求职简历

# 选择模板类型：1
# 输入文件名：my_paper
# 是否立即编译：y

# 结果：生成my_paper.tex并编译成PDF
```

---

## 高级功能详解

### 1. 模板管理系统 📚

#### 保存自定义模板

**场景**：你花了很多时间调整好了一个论文模板，想在以后的论文中重复使用

```bash
# Step 1: 编辑好你的模板文件
vim my_perfect_article.tex

# Step 2: 保存为模板
./latexcompile-standalone.sh
选择：5) [M] Manage Templates
选择：2) Save current file as template
选择文件：my_perfect_article.tex
模板名称：thesis_template

[保存到 ~/.latex_templates/thesis_template.tex]
```

#### 使用自定义模板

```bash
./latexcompile-standalone.sh
选择：5) [M] Manage Templates
选择：4) Use custom template
选择模板：thesis_template
新文件名：chapter1

[创建 chapter1.tex，内容复制自模板]
是否编译：y
```

#### 管理模板库

```bash
# 查看所有自定义模板
选择：5) [M] Manage Templates → 3) List custom templates

# 删除不需要的模板
选择：5) [M] Manage Templates → 5) Delete custom template
```

---

### 2. 项目工作区管理 🗂️

#### 保存工作区

**场景**：你在管理多个LaTeX项目，想快速切换

```bash
# 在第一个项目目录
cd ~/Documents/thesis/
./latexcompile-standalone.sh
选择：6) [W] Workspace Manager
选择：2) Add current directory
工作区名称：Thesis2024

# 在第二个项目目录
cd ~/Work/paper-neurips/
./latexcompile-standalone.sh
选择：6) [W] Workspace Manager
选择：2) Add current directory
工作区名称：NeurIPS Paper

# 在第三个项目
cd ~/Teaching/slides/
./latexcompile-standalone.sh
选择：6) [W] Workspace Manager
选择：2) Add current directory
工作区名称：Course Slides
```

#### 切换工作区

```bash
# 从任意位置切换到某个项目
./latexcompile-standalone.sh
选择：6) [W] Workspace Manager
选择：3) Switch to workspace
选择：NeurIPS Paper

[自动cd到 ~/Work/paper-neurips/]
[自动重新加载该项目的.latexcfg配置]

# 现在可以直接编译该项目的文件
```

#### 查看所有工作区

```bash
选择：6) [W] Workspace Manager → 1) List workspaces

输出：
1) Thesis2024
   ~/Documents/thesis/
   
2) NeurIPS Paper
   ~/Work/paper-neurips/
   
3) Course Slides
   ~/Teaching/slides/
```

---

### 3. 依赖包检测 🔍

**场景**：编译失败，提示缺少某个包

```bash
./latexcompile-standalone.sh
选择：9) [?] Check Package Dependencies
选择文件：main.tex

输出：
Found 12 packages:

[OK] amsmath
[OK] graphicx
[OK] hyperref
[X]  algorithm2e (not found)
[OK] booktabs
...

Found 1 missing package(s)
Install with: sudo dnf install 'tex(algorithm2e.sty)'
```

**解决方案**：

```bash
# 根据提示安装
sudo dnf install 'tex(algorithm2e.sty)'
```

---

### 4. 错误诊断 🔧

**场景**：编译失败，不知道哪里出错

```bash
./latexcompile-standalone.sh
选择：10) [!] Diagnose Errors
选择日志：main.log

智能诊断输出：

[!] Missing Files:
  ./images/figure1.png not found
  
[!] Undefined Commands:
  l.25: \undefinedcommand
  → 可能是拼写错误或缺少宏包

[!] Undefined References:
  Reference `sec:intro' undefined
  → 可能需要再编译一次或检查\label
```

**常见错误和解决方案**：

1. **缺失文件** → 检查文件路径是否正确
2. **未定义命令** → 检查拼写或添加对应宏包
3. **未定义引用** → 再编译一次（LaTeX需要多次编译）
4. **缺失宏包** → 使用"Check Package Dependencies"功能

---

### 5. 字数统计 📊

```bash
./latexcompile-standalone.sh
选择：8) [=] Word Count & Statistics
选择文件：thesis.tex

输出（如果安装了texcount）：
Words in text: 8542
Words in headers: 123
Words in float captions: 245
Number of math inlines: 67
Number of math displayed: 34

输出（如果没有texcount）：
Basic Statistics:
Total lines:   542
Code lines:    489
Comments:      53
Approx words:  8500

Tip: Install texcount for accurate counting
```

---

### 6. 批量编译（多文件项目）

**适合场景**：毕业论文，多个章节分别编译

#### Step 1: 创建项目配置

```bash
cd ~/Documents/thesis/

# 项目结构：
# thesis/
#   ├── main.tex
#   ├── chapter1.tex
#   ├── chapter2.tex
#   └── references.bib

./latexcompile-standalone.sh
选择：13) [*] Create/Update Config

--- Configuring Target #1 ---
选择TeX文件：main.tex
选择引擎：xelatex
选择bib工具：biber

是否添加更多文件：y

--- Configuring Target #2 ---
选择TeX文件：chapter1.tex
选择引擎：xelatex
选择bib工具：none

是否添加更多文件：y

--- Configuring Target #3 ---
选择TeX文件：chapter2.tex
选择引擎：xelatex
选择bib工具：none

是否添加更多文件：n

[创建 .latexcfg 文件]
```

#### Step 2: 批量编译

```bash
./latexcompile-standalone.sh

# 主菜单会显示：2) [F] Compile with project config

选择：2

选项：
[ALL] Compile ALL Targets
Target #1: main.tex (xelatex)
Target #2: chapter1.tex (xelatex)
Target #3: chapter2.tex (xelatex)
[Back]

# 选择 [ALL] 
[依次编译所有文件]
```

---

## 实战案例

### 案例1：撰写学术论文

```bash
# 1. 从模板开始
./latexcompile-standalone.sh
选择：[T] Generate Template → 1) Article
文件名：neurips_paper

# 2. 编辑内容
vim neurips_paper.tex

# 3. 第一次编译
选择：[+] Compile interactively
文件：neurips_paper.tex
引擎：XeLaTeX

# 4. 反复修改-编译
# 每次修改后：
选择：[>>>] Quick Recompile

# 5. 检查字数（会议要求8页）
选择：[=] Word Count

# 6. 保存为模板供下次使用
选择：[M] Manage Templates
→ Save current file as template
模板名：neurips_template
```

---

### 案例2：准备课程幻灯片

```bash
# 1. 生成Beamer模板
选择：[T] Generate Template → 2) Beamer
文件名：lecture1

# 2. 编辑幻灯片内容
vim lecture1.tex

# 3. 实时预览模式编译
选择：[+] Compile interactively
选择：[Live] Preview Mode (XeLaTeX)

# LaTeX会监视文件变化，自动重新编译
# Ctrl+C 停止监视

# 4. 保存课程目录为工作区
选择：[W] Workspace Manager
→ Add current directory
名称：Course2024
```

---

### 案例3：管理毕业论文

```bash
# 项目结构：
# thesis/
#   ├── main.tex
#   ├── chapters/
#   │   ├── ch1_intro.tex
#   │   ├── ch2_method.tex
#   │   └── ch3_results.tex
#   ├── figures/
#   └── references.bib

# Step 1: 创建项目配置
选择：[*] Create/Update Config
配置main.tex（包含biber）

# Step 2: 保存工作区
选择：[W] Workspace Manager
→ Add current directory
名称：Master Thesis

# Step 3: 日常工作流
# 编辑某章节后：
选择：[>>>] Quick Recompile (main.tex)

# 检查依赖
选择：[?] Check Package Dependencies

# 查看编译历史
选择：[@] Compilation History

# Step 4: 清理辅助文件（提交前）
选择：[~] Clean auxiliary files
```

---

## 常见问题

### Q1: 编译中文文档失败？

**A**: 确保使用XeLaTeX引擎，并在文档中添加：

```latex
\usepackage{xeCJK}
\setCJKmainfont{Noto Serif CJK SC}
```

---

### Q2: 提示找不到texcount？

**A**: 字数统计是可选功能，安装或使用fallback：

```bash
# 安装（推荐）
sudo dnf install texcount

# 或使用脚本的基础统计（无需安装）
```

---

### Q3: PDF打开失败？

**A**: 检查配置：

```bash
# 编辑 ~/.latexrc
[General]
auto_open_pdf = true

[PDF]
viewer = zathura  # 或 evince, okular等
```

---

### Q4: 如何更换主题？

**A**:

```bash
选择：[#] Settings & Themes
→ Change Theme
选择喜欢的主题（nord/dracula/sakura等）
[自动保存]
```

---

### Q5: Quick Recompile显示文件不存在？

**A**: 历史记录中的文件已被删除或移动

```bash
# 清除历史
rm ~/.latex_history

# 或直接用交互式编译
选择：[+] Compile interactively
```

---

## 最佳实践

### ✅ 推荐工作流

**单文档项目**：

```
新建 → 模板生成 → 编辑 → Quick Recompile (循环)
```

**多文档项目**：

```
新建 → 创建Config → 保存工作区 → 批量编译
```

**多项目管理**：

```
每个项目保存为工作区 → 用Workspace Manager快速切换
```

---

### ⚡ 效率技巧

1. **使用别名**：

```bash
echo "alias texc='~/Downloads/sh/latexcompile-standalone.sh'" >> ~/.zshrc
source ~/.zshrc

# 之后只需
texc
```

1. **保存常用模板**：
自己调整好的模板保存到模板库，避免重复劳动

2. **善用工作区**：
多个项目用工作区管理，避免频繁cd

3. **定期清理**：
编译成功后使用Clean功能，节省磁盘空间

---

### 🎨 美化技巧

**选择合适的主题**：

- `nord` - 冷色调，适合长时间使用
- `dracula` - 暗黑炫彩，适合夜间工作
- `sakura` - 温暖粉嫩，视觉舒适
- `matrix` - 绿色主题，极客风格

```bash
选择：[#] Settings & Themes → Change Theme
```

---

### 📝 编写规范

**推荐引擎**：

- 中文文档：XeLaTeX
- 英文文档：PDFLaTeX或XeLaTeX
- 复杂图形：LuaLaTeX

**文献管理**：

- 现代文档：biber + biblatex
- 传统文档：bibtex

---

## 快速参考卡

| 功能 | 快捷操作 | 适用场景 |
|------|---------|---------|
| 快速编译 | `./latexcompile-standalone.sh file.tex` | 单文件快速测试 |
| 重编译 | 菜单选1 | 反复修改调试 |
| 生成模板 | 菜单选4 | 新建文档 |
| 切换项目 | 菜单选6 | 多项目管理 |
| 清理文件 | 菜单选15 | 提交前清理 |

---

**祝LaTeX编写愉快！** 🎓✨
