#!/bin/bash
# TradingAgents-CN 完整启动脚本（后端 + 前端 + cpolar 暴露前端）

echo "🚀 正在启动 TradingAgents-CN 服务（后端 + 前端 + cpolar）..."
echo ""

# 进入项目目录
cd "$(dirname "$0")"

# 确保日志目录存在
mkdir -p logs

# pid 文件路径（便于稳定启停）
BACKEND_PID_FILE="logs/backend.pid"
FRONTEND_PID_FILE="logs/frontend.pid"
NGROK_PID_FILE="logs/ngrok.pid"
CPOLAR_PID_FILE="logs/cpolar.pid"

stop_all() {
  echo ''
  echo '正在停止服务...'
  if [ -f "$BACKEND_PID_FILE" ]; then kill "$(cat "$BACKEND_PID_FILE")" 2>/dev/null || true; fi
  if [ -f "$FRONTEND_PID_FILE" ]; then kill "$(cat "$FRONTEND_PID_FILE")" 2>/dev/null || true; fi
  if [ -f "$NGROK_PID_FILE" ]; then kill "$(cat "$NGROK_PID_FILE")" 2>/dev/null || true; fi
  if [ -f "$CPOLAR_PID_FILE" ]; then kill "$(cat "$CPOLAR_PID_FILE")" 2>/dev/null || true; fi
  pkill -f 'uvicorn app.main:app' 2>/dev/null || true
  pkill -f 'vite.*--port 3000' 2>/dev/null || true
  pkill -f 'ngrok http' 2>/dev/null || true
  pkill -f 'cpolar http' 2>/dev/null || true
  exit 0
}

# 检查 cpolar 是否安装
if ! command -v cpolar >/dev/null 2>&1; then
  echo "❌ cpolar 未安装，请先安装 cpolar"
  exit 1
fi

# 检查虚拟环境
if [ ! -d "venv" ]; then
  echo "❌ 虚拟环境不存在，请先创建虚拟环境"
  exit 1
fi

# 激活虚拟环境
source venv/bin/activate

# 加载 .env（导出为环境变量，确保后端能拿到 Redis/Mongo/JWT 等配置）
# 说明：某些环境未安装 python-dotenv 时，.env 不会自动进入 os.environ，
# 但项目启动校验/数据库连接依赖环境变量，因此这里做一次显式加载。
if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

# 🔧 PDF 导出依赖：wkhtmltopdf（优先使用项目内置版本，避免系统未安装）
WKHTML_LOCAL="$(pwd)/tools/wkhtmltopdf/root/bin/wkhtmltopdf"
if [ -x "$WKHTML_LOCAL" ]; then
  export WKHTMLTOPDF_PATH="$WKHTML_LOCAL"
  # wkhtmltopdf 依赖的动态库（项目内置）
  export DYLD_LIBRARY_PATH="$(pwd)/tools/wkhtmltopdf/root/lib:${DYLD_LIBRARY_PATH}"
fi

# 清理旧的进程
echo "🧹 清理旧的进程..."
# 优先按 pid 精准停止，避免误伤系统其他项目；pid 不存在再用 pkill 兜底
if [ -f "$BACKEND_PID_FILE" ]; then kill "$(cat "$BACKEND_PID_FILE")" 2>/dev/null || true; fi
if [ -f "$FRONTEND_PID_FILE" ]; then kill "$(cat "$FRONTEND_PID_FILE")" 2>/dev/null || true; fi
if [ -f "$NGROK_PID_FILE" ]; then kill "$(cat "$NGROK_PID_FILE")" 2>/dev/null || true; fi
if [ -f "$CPOLAR_PID_FILE" ]; then kill "$(cat "$CPOLAR_PID_FILE")" 2>/dev/null || true; fi

pkill -f "uvicorn app.main:app" 2>/dev/null || true
pkill -f "vite.*--port 3000" 2>/dev/null || true
pkill -f "ngrok http" 2>/dev/null || true
pkill -f "cpolar http" 2>/dev/null || true
sleep 2

# 启动后端服务（后台运行）
echo "📡 启动后端服务 (http://localhost:8000)..."
# 注意：默认不开启 --reload，避免触发 Linux inotify 监听上限导致的
# `OS file watch limit reached (MaxFilesWatch)` 报错。
# 如需本地开发热重载，可在运行前设置：export UVICORN_RELOAD=1
UVICORN_RELOAD_ARGS=""
if [ "${UVICORN_RELOAD:-0}" = "1" ] || [ "${UVICORN_RELOAD:-0}" = "true" ]; then
  UVICORN_RELOAD_ARGS="--reload"
  # 在 inotify 限制较小的环境下用轮询方式避免崩溃
  export WATCHFILES_FORCE_POLLING=true
fi
# 用 nohup 让子进程在脚本意外退出（例如 ssh 断开）时也能保活
nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 $UVICORN_RELOAD_ARGS > logs/backend.out 2>&1 &
BACKEND_PID=$!
echo "$BACKEND_PID" > "$BACKEND_PID_FILE"
echo "   ✓ 后端服务已启动 (PID: $BACKEND_PID)"

# 等待后端启动
sleep 3

# 启动前端服务（后台运行）
echo "🌐 启动前端服务 (http://localhost:3000)..."
cd frontend
if command -v yarn >/dev/null 2>&1; then
  nohup yarn dev --host 0.0.0.0 --port 3000 > ../logs/frontend.out 2>&1 &
else
  nohup npm run dev -- --host 0.0.0.0 --port 3000 > ../logs/frontend.out 2>&1 &
fi
FRONTEND_PID=$!
echo "$FRONTEND_PID" > "../$FRONTEND_PID_FILE"
cd ..
echo "   ✓ 前端服务已启动 (PID: $FRONTEND_PID)"

# 等待前端启动
sleep 5

# 启动 cpolar 隧道（只暴露前端）
echo "🔗 启动 cpolar 隧道（暴露前端端口 3000）..."
# 已通过 `cpolar authtoken <token>` 完成授权（token 存在 /root/.cpolar/cpolar.yml，不进入 git）

# cpolar 本地 Web UI 默认为 4040（不同版本可能不同），这里不依赖 UI，仅取 stdout
nohup cpolar http 3000 --log=stdout --log-level=info > logs/cpolar.out 2>&1 &
CPOLAR_PID=$!
echo "$CPOLAR_PID" > "$CPOLAR_PID_FILE"
echo "   ✓ cpolar 隧道已启动 (PID: $CPOLAR_PID)"

# 等待 cpolar 启动
sleep 5

echo ""
echo "✅ 所有服务已启动！"
echo ""
echo "📍 本地访问地址："
echo "   后端 API: http://localhost:8000"
echo "   前端页面: http://localhost:3000"
echo "   API 文档: http://localhost:8000/docs"
echo ""

# 获取 cpolar 公网地址（优先从日志中解析，避免依赖 cpolar API）
echo "🌍 获取 cpolar 公网地址..."
sleep 2
CPOLAR_URL=$(python3 - <<'PY'\nimport re\nfrom pathlib import Path\np = Path('logs/cpolar.out')\nif not p.exists():\n    print('')\n    raise SystemExit(0)\ntext = p.read_text(errors='ignore')\n# 常见格式里会出现 http(s)://xxxx.cpolar.cn\nm = re.findall(r'https?://[a-zA-Z0-9\\-\\.]+\\.cpolar\\.(?:cn|com)(?::\\d+)?', text)\nprint(m[-1] if m else '')\nPY\n)

if [ -n "$CPOLAR_URL" ]; then
  echo "   ✓ 前端公网地址: $CPOLAR_URL"
else
  echo "   ⚠ 未能从日志解析到公网地址，请查看 logs/cpolar.out"
fi

echo ""
echo "💡 提示："
echo "   - 前端已配置代理，通过前端地址即可访问所有功能"
echo "   - 查看后端日志: tail -f logs/backend.out"
echo "   - 查看前端日志: tail -f logs/frontend.out"
echo "   - 查看 cpolar 日志: tail -f logs/cpolar.out"
echo ""
echo "🛑 停止所有服务:"
echo "   pkill -f 'uvicorn app.main:app' && pkill -f 'vite.*--port 3000' && pkill -f 'cpolar http'"
echo ""

# 保持脚本运行，等待用户中断
trap stop_all INT TERM

echo "服务正在运行中，按 Ctrl+C 停止所有服务..."
wait
