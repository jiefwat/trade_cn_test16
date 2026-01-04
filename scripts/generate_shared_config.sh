#!/bin/bash
# 生成可分享的 host 配置脚本

echo "=========================================="
echo "TradingAgents-CN 共享 Host 配置生成器"
echo "=========================================="
echo ""

# 获取本机 IP
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null)
fi
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="YOUR_SERVER_IP"
fi

echo "检测到服务器 IP: $LOCAL_IP"
echo ""

# 询问配置类型
echo "请选择配置类型:"
echo "1) 开发环境（允许所有来源，方便测试）"
echo "2) 生产环境（限制来源，更安全）"
read -p "请输入选项 [1/2] (默认: 1): " CONFIG_TYPE
CONFIG_TYPE=${CONFIG_TYPE:-1}

echo ""
read -p "请输入前端访问端口 [3000]: " FRONTEND_PORT
FRONTEND_PORT=${FRONTEND_PORT:-3000}

echo ""
read -p "请输入后端 API 端口 [8000]: " BACKEND_PORT
BACKEND_PORT=${BACKEND_PORT:-8000}

echo ""
read -p "是否允许所有来源访问？(y/n, 默认: y): " ALLOW_ALL
ALLOW_ALL=${ALLOW_ALL:-y}

# 生成配置
CONFIG_FILE=".env.shared"
cat > "$CONFIG_FILE" << EOCONFIG
# ========================================
# TradingAgents-CN 共享访问配置
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# ========================================

# 后端服务配置
HOST=0.0.0.0
PORT=$BACKEND_PORT

# CORS 配置
EOCONFIG

if [ "$ALLOW_ALL" = "y" ]; then
    echo 'ALLOWED_ORIGINS=["*"]' >> "$CONFIG_FILE"
else
    echo "ALLOWED_ORIGINS=[\"http://$LOCAL_IP:$FRONTEND_PORT\", \"http://localhost:$FRONTEND_PORT\"]" >> "$CONFIG_FILE"
fi

if [ "$CONFIG_TYPE" = "2" ]; then
    echo 'ALLOWED_HOSTS=["*"]' >> "$CONFIG_FILE"
    echo 'DEBUG=false' >> "$CONFIG_FILE"
else
    echo 'ALLOWED_HOSTS=["*"]' >> "$CONFIG_FILE"
    echo 'DEBUG=true' >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" << EOCONFIG

# ========================================
# 访问地址
# ========================================
# 本地访问:
# - 前端: http://localhost:$FRONTEND_PORT
# - 后端 API: http://localhost:$BACKEND_PORT/api
#
# 局域网访问:
# - 前端: http://$LOCAL_IP:$FRONTEND_PORT
# - 后端 API: http://$LOCAL_IP:$BACKEND_PORT/api
#
# API 文档: http://$LOCAL_IP:$BACKEND_PORT/docs
EOCONFIG

echo ""
echo "✅ 配置文件已生成: $CONFIG_FILE"
echo ""
echo "📋 配置摘要:"
echo "   - 服务器 IP: $LOCAL_IP"
echo "   - 前端端口: $FRONTEND_PORT"
echo "   - 后端端口: $BACKEND_PORT"
echo "   - 允许所有来源: $ALLOW_ALL"
echo ""
echo "📝 使用方法:"
echo "   1. 查看配置文件: cat $CONFIG_FILE"
echo "   2. 合并到 .env: cat $CONFIG_FILE >> .env"
echo "   3. 或直接使用: cp $CONFIG_FILE .env"
echo ""
echo "🌐 分享地址:"
echo "   - 前端: http://$LOCAL_IP:$FRONTEND_PORT"
echo "   - 后端: http://$LOCAL_IP:$BACKEND_PORT/api"
echo ""
