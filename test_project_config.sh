#!/bin/bash

# 项目配置验证测试脚本
# Tests the project-level configuration override functionality

echo "=== Testing Project Configuration System ==="
echo ""

# 测试场景 1: 无项目配置
echo "Test 1: No project config (should use global)"
cd /tmp
rm -f .latexcfg 2>/dev/null
echo -e "[Theme]\nactive_theme = nord" > ~/.latexrc_test
echo "Expected: Uses global theme 'nord'"
echo ""

# 测试场景 2: 项目配置覆盖主题
echo "Test 2: Project config overrides theme"
cat > .latexcfg << 'EOF'
[Theme]
active_theme = matrix

[Targets]
MAIN_FILE = test.tex
EOF

echo "Expected: Project theme 'matrix' should override global 'nord'"
echo "✓ Created .latexcfg with matrix theme"
echo ""

# 测试场景 3: 项目配置包含多个覆盖
echo "Test 3: Multiple project overrides"
cat > .latexcfg << 'EOF'
[General]
default_engine = lualatex
auto_cleanup = true

[Theme]
active_theme = dracula

[Features]
enable_history = false

[Targets]
MAIN_FILE = thesis.tex
ENGINE = xelatex
EOF

echo "Expected: All project settings should override global"
echo "✓ Created .latexcfg with multiple overrides"
echo ""

# 清理
rm -f .latexcfg ~/.latexrc_test

echo "=== Test Configuration Files Created ==="
echo ""
echo "To test manually:"
echo "1. Copy .latexcfg.example to .latexcfg in your project directory"
echo "2. Run: ./latexcompile-standalone.sh"
echo "3. Select 'Project Info' → 'Project Summary'"
echo "4. Verify that configuration sources are displayed correctly"
echo ""
echo "Expected output should show:"
echo "  - Project config: [OK] .latexcfg found"
echo "  - Overrides: theme, engine, cleanup, editor"
echo "  - Active Settings with (project) or (global) indicators"
