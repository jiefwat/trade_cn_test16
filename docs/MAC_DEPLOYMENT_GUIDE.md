# Mac 本地部署指南

本指南将帮助您在 Mac 上完成 TradingAgents-CN v1.0.0-preview 的本地部署。

## ✅ 前置检查清单

在开始之前，请确保您已安装以下软件：

- ✅ Python 3.10-3.12
- ✅ Node.js 18+
- ✅ Homebrew
- ✅ MongoDB 4.4+
- ✅ Redis 6.0+

## 📋 部署步骤

### 步骤 1: 检查系统环境

```bash
# 检查 Python 版本
python3 --version  # 应该是 3.10-3.12

# 检查 Node.js 版本
node --version  # 应该是 18+

# 检查 Homebrew
brew --version
```

### 步骤 2: 安装 MongoDB 和 Redis

#### 安装 MongoDB

```bash
# 使用 Homebrew 安装 MongoDB
brew tap mongodb/brew
brew install mongodb-community

# 启动 MongoDB 服务
brew services start mongodb-community
```

#### 安装 Redis

```bash
# 使用 Homebrew 安装 Redis
brew install redis

# 启动 Redis 服务
brew services start redis

# 设置 Redis 密码（可选，但推荐）
# 编辑配置文件: /opt/homebrew/etc/redis.conf (Apple Silicon) 或 /usr/local/etc/redis.conf (Intel)
# 添加: requirepass tradingagents123
# 然后重启: brew services restart redis
```

### 步骤 3: 克隆项目

```bash
# 克隆项目
git clone https://github.com/hsliuping/TradingAgents-CN.git
cd TradingAgents-CN
```

### 步骤 4: 配置后端环境

#### 4.1 创建 Python 虚拟环境

```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate
```

#### 4.2 安装 Python 依赖

```bash
# 配置清华镜像（可选，加速下载）
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 安装依赖
pip install -r requirements.txt
```

#### 4.3 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，配置以下关键参数：
```

**重要配置项：**

```env
# MongoDB 配置（如果未启用认证，用户名和密码可以为空）
MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_USERNAME=
MONGODB_PASSWORD=
MONGODB_DATABASE=tradingagents
MONGODB_AUTH_SOURCE=admin

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=tradingagents123  # 如果设置了密码
REDIS_DB=0

# API 配置
API_BASE_URL=http://localhost:8000
CORS_ORIGINS=["http://localhost:3000"]

# LLM 配置（根据需要配置）
OPENAI_API_KEY=your_openai_key
DEEPSEEK_API_KEY=your_deepseek_key
DASHSCOPE_API_KEY=your_dashscope_key
SILICONFLOW_API_KEY=your_siliconflow_key

# 其他配置
DEBUG=true
LOG_LEVEL=INFO
```

### 步骤 5: 配置前端环境

```bash
# 进入前端目录
cd frontend

# 安装依赖（使用 yarn 或 npm）
yarn install
# 或
npm install

# 返回项目根目录
cd ..
```

### 步骤 6: 初始化数据库

#### 6.1 确保 MongoDB 和 Redis 正在运行

```bash
# 检查 MongoDB
brew services list | grep mongodb

# 检查 Redis
brew services list | grep redis
```

#### 6.2 初始化数据库（重要！）

```bash
# 激活虚拟环境
source venv/bin/activate

# 执行数据库初始化脚本（必须执行！）
python scripts/import_config_and_create_user.py --host
```

**⚠️ 重要提示：**

- 此脚本会导入系统配置数据到 MongoDB
- 创建默认管理员用户（用户名：admin，密码：admin123）
- 初始化 LLM 提供商、市场分类等基础数据
- **如果不执行此步骤，系统将无法正常运行**

如果 MongoDB 未启用认证，脚本可能会报错。可以手动创建管理员用户：

```bash
# 连接 MongoDB（无认证）
mongosh

# 切换到 tradingagents 数据库
use tradingagents

# 创建管理员用户（如果不存在）
# 注意：这里创建的是应用用户，不是 MongoDB 管理员用户
# 应用用户会在初始化脚本中自动创建
```

### 步骤 7: 启动服务

#### 7.1 启动后端服务

**方式一：使用 uvicorn（推荐）**

```bash
# 激活虚拟环境
source venv/bin/activate

# 启动后端服务
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**方式二：使用 Python 模块**

```bash
# 激活虚拟环境
source venv/bin/activate

# 启动后端服务
python -m app.main
```

后端服务将在 `http://localhost:8000` 启动

### 📄 报告导出（PDF）依赖（可选）

项目导出 PDF 使用 `pdfkit` + `wkhtmltopdf`。如果你在下载报告时看到 “`No wkhtmltopdf executable found`”，请按以下步骤安装：

```bash
# 1) 安装 wkhtmltopdf（推荐 Homebrew）
brew install --cask wkhtmltopdf

# 2) 验证
which wkhtmltopdf
wkhtmltopdf --version
```

如果你安装后仍提示找不到，可在 `.env` 中显式指定路径（择一）：

```env
WKHTMLTOPDF_PATH=/opt/homebrew/bin/wkhtmltopdf
# 或（Intel）
WKHTMLTOPDF_PATH=/usr/local/bin/wkhtmltopdf
```

#### 7.2 启动前端服务

打开新的终端窗口：

```bash
# 进入前端目录
cd frontend

# 启动开发服务器
yarn dev
# 或
npm run dev
```

前端服务将在 `http://localhost:3000` 启动

### 步骤 8: 验证安装

#### 后端验证

```bash
# 检查健康状态
curl http://localhost:8000/api/health

# 访问 API 文档
# 浏览器打开: http://localhost:8000/docs
```

#### 前端验证

```bash
# 浏览器打开: http://localhost:3000
# 使用默认账号登录：
# 用户名: admin
# 密码: admin123
```

#### 数据库验证

```bash
# 连接 MongoDB
mongosh tradingagents

# 查看集合
show collections

# 检查用户
db.users.find().limit(5)
```

## 🔧 常见问题解决

### 1. MongoDB 连接失败

**问题：** 后端启动时报错无法连接 MongoDB

**解决方案：**

```bash
# 检查 MongoDB 是否正在运行
brew services list | grep mongodb

# 如果未运行，启动 MongoDB
brew services start mongodb-community

# 检查端口是否被占用
lsof -i :27017
```

### 2. Redis 连接失败

**问题：** 后端启动时报错无法连接 Redis

**解决方案：**

```bash
# 检查 Redis 是否正在运行
brew services list | grep redis

# 如果未运行，启动 Redis
brew services start redis

# 测试 Redis 连接
redis-cli -a tradingagents123 ping
```

### 3. 登录时报错 "系统配置缺失"

**问题：** 使用 admin/admin123 无法登录，提示配置缺失

**解决方案：**

```bash
# 确保已执行数据库初始化脚本
source venv/bin/activate
python scripts/import_config_and_create_user.py --host

# 验证初始化是否成功
curl http://localhost:8000/api/system/config
```

### 4. 端口被占用

**问题：** 8000 或 3000 端口被占用

**解决方案：**

```bash
# 查找占用 8000 端口的进程
lsof -i :8000

# 终止进程
kill -9 <PID>

# 或者修改 .env 文件中的端口配置
```

### 5. 前端依赖安装失败

**问题：** yarn install 或 npm install 失败

**解决方案：**

```bash
# 清理缓存
rm -rf node_modules package-lock.json yarn.lock

# 重新安装
yarn install
# 或
npm install

# 如果内存不足，增加 Node.js 内存限制
export NODE_OPTIONS="--max-old-space-size=4096"
yarn install
```

## 📝 后续步骤

1. **配置 LLM API 密钥**：在 `.env` 文件中配置您的大模型 API 密钥
2. **同步股票数据**：使用前端界面的数据同步功能同步股票数据
3. **开始分析**：使用默认账号登录后，可以开始进行股票分析

## 🎉 完成！

恭喜您成功完成本地部署！现在可以开始使用 TradingAgents-CN 进行股票分析了。

如果遇到问题，请查看：
- [故障排除指南](./faq/troubleshooting.md)
- [常见问题](./faq/faq.md)
- [GitHub Issues](https://github.com/hsliuping/TradingAgents-CN/issues)
