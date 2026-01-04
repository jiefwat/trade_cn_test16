#!/bin/bash
# TradingAgents-CN 启动脚本

echo "🚀 正在启动 TradingAgents-CN 后端服务..."
echo ""

# 进入项目目录
cd "$(dirname "$0")"

# 激活虚拟环境
source venv/bin/activate

# 🔧 PDF 导出依赖：wkhtmltopdf（优先使用项目内置版本，避免系统未安装）
WKHTML_LOCAL="$(pwd)/tools/wkhtmltopdf/root/bin/wkhtmltopdf"
if [ -x "$WKHTML_LOCAL" ]; then
  export WKHTMLTOPDF_PATH="$WKHTML_LOCAL"
  # wkhtmltopdf 依赖的动态库（项目内置）
  export DYLD_LIBRARY_PATH="$(pwd)/tools/wkhtmltopdf/root/lib:${DYLD_LIBRARY_PATH}"
fi

# 启动后端服务
echo "📡 后端服务将在 http://localhost:8000 启动"
echo "📚 API 文档地址: http://localhost:8000/docs"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
