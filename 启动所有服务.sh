#!/bin/bash
# TradingAgents-CN 完整启动脚本（后端 + 前端 + ngrok 暴露前端）

echo "🚀 正在启动 TradingAgents-CN 服务（后端 + 前端 + ngrok）..."
echo ""

# 进入项目目录
cd "$(dirname "$0")"

# 检查 ngrok 是否安装
if ! command -v ngrok >/dev/null 2>&1; then
  echo "❌ ngrok 未安装，请先安装 ngrok"
  exit 1
fi

# 检查虚拟环境
if [ ! -d "venv" ]; then
  echo "❌ 虚拟环境不存在，请先创建虚拟环境"
  exit 1
fi

# 激活虚拟环境
source venv/bin/activate

# 🔧 PDF 导出依赖：wkhtmltopdf（优先使用项目内置版本，避免系统未安装）
WKHTML_LOCAL="$(pwd)/tools/wkhtmltopdf/root/bin/wkhtmltopdf"
if [ -x "$WKHTML_LOCAL" ]; then
  export WKHTMLTOPDF_PATH="$WKHTML_LOCAL"
  # wkhtmltopdf 依赖的动态库（项目内置）
  export DYLD_LIBRARY_PATH="$(pwd)/tools/wkhtmltopdf/root/lib:${DYLD_LIBRARY_PATH}"
fi

# 清理旧的进程
echo "🧹 清理旧的进程..."
pkill -f "uvicorn app.main:app" 2>/dev/null
pkill -f "vite.*--port 3000" 2>/dev/null
pkill -f "ngrok http" 2>/dev/null
sleep 2

# 启动后端服务（后台运行）
echo "📡 启动后端服务 (http://localhost:8000)..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > logs/backend.out 2>&1 &
BACKEND_PID=$!
echo "   ✓ 后端服务已启动 (PID: $BACKEND_PID)"

# 等待后端启动
sleep 3

# 启动前端服务（后台运行）
echo "🌐 启动前端服务 (http://localhost:3000)..."
cd frontend
if command -v yarn >/dev/null 2>&1; then
  yarn dev --host 0.0.0.0 --port 3000 > ../logs/frontend.out 2>&1 &
else
  npm run dev -- --host 0.0.0.0 --port 3000 > ../logs/frontend.out 2>&1 &
fi
FRONTEND_PID=$!
cd ..
echo "   ✓ 前端服务已启动 (PID: $FRONTEND_PID)"

# 等待前端启动
sleep 5

# 启动 ngrok 隧道（只暴露前端）
echo "🔗 启动 ngrok 隧道（暴露前端端口 3000）..."
ngrok http 3000 --log=stdout --log-format=json > logs/ngrok.out 2>&1 &
NGROK_PID=$!
echo "   ✓ ngrok 隧道已启动 (PID: $NGROK_PID)"

# 等待 ngrok 启动
sleep 5

echo ""
echo "✅ 所有服务已启动！"
echo ""
echo "📍 本地访问地址："
echo "   后端 API: http://localhost:8000"
echo "   前端页面: http://localhost:3000"
echo "   API 文档: http://localhost:8000/docs"
echo ""

# 获取 ngrok 公网地址
echo "🌍 获取 ngrok 公网地址..."
sleep 3
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    if tunnels:
        url = tunnels[0].get('public_url', '')
        print(url)
    else:
        print('')
except:
    print('')
" 2>/dev/null)

if [ -n "$NGROK_URL" ]; then
  echo "   ✓ 前端公网地址: $NGROK_URL"
else
  echo "   ⚠ 正在获取公网地址，请稍候..."
  echo "   您可以访问 http://127.0.0.1:4040 查看 ngrok 状态"
  NGROK_URL="http://127.0.0.1:4040"
fi

echo ""
echo "💡 提示："
echo "   - 前端已配置代理，通过前端地址即可访问所有功能"
echo "   - ngrok Web UI: http://127.0.0.1:4040"
echo "   - 查看后端日志: tail -f logs/backend.out"
echo "   - 查看前端日志: tail -f logs/frontend.out"
echo "   - 查看 ngrok 日志: tail -f logs/ngrok.out"
echo ""
echo "🛑 停止所有服务:"
echo "   pkill -f 'uvicorn app.main:app' && pkill -f 'vite.*--port 3000' && pkill -f 'ngrok http'"
echo ""

# 保持脚本运行，等待用户中断
trap "echo ''; echo '正在停止服务...'; pkill -f 'uvicorn app.main:app'; pkill -f 'vite.*--port 3000'; pkill -f 'ngrok http'; exit 0" INT TERM

echo "服务正在运行中，按 Ctrl+C 停止所有服务..."
wait
