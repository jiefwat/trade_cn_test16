#!/bin/bash
# TradingAgents-CN 前端启动脚本

echo "🎨 正在启动 TradingAgents-CN 前端服务..."
echo ""

# 进入前端目录
cd "$(dirname "$0")/frontend"

# 启动前端服务
echo "🌐 前端服务将在 http://localhost:3000 启动"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""

if command -v yarn >/dev/null 2>&1; then
  yarn dev --host 0.0.0.0 --port 3000
elif command -v npm >/dev/null 2>&1; then
  npm run dev -- --host 0.0.0.0 --port 3000
else
  echo "❌ 未找到 yarn 或 npm，请先安装 Node.js (包含 npm) 或 yarn"
  exit 1
fi
