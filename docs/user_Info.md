TradingAgents v1.0.0-preview 源码版安装手册（修订版）
本手册指导您从源码安装 TradingAgents v1.0.0-preview 版本，该版本采用前后端分离架构：

后端
：FastAPI 应用，源码位于 app/ 目录
前端
：Vue 3 应用，源码位于 frontend/ 目录
数据库
：MongoDB（数据存储）
缓存
：Redis（会话缓存和临时数据）
系统要求
环境要求
Python 3.10+
Node.js 18+
MongoDB 4.4+
Redis 6.0+
Git
推荐配置
CPU：4 核心以上
内存：8GB 以上
存储：50GB 可用空间
网络：稳定的互联网连接
项目结构
TradingAgentsCN/
├── app/                    # 后端源码目录
│   ├── main.py            # FastAPI 主应用
│   ├── api/               # API 路由
│   ├── core/              # 核心配置
│   ├── models/            # 数据模型
│   ├── services/          # 业务逻辑
│─── requirements.txt   # Python 依赖
├── frontend/              # 前端源码目录
│   ├── package.json       # Node.js 依赖
│   ├── src/               # Vue 3 源码
│   └── vite.config.js     # Vite 配置
├── docker-compose.yml     # Docker 配置
├── Dockerfile.backend     # 后端 Docker 镜像
└── Dockerfile.frontend    # 前端 Docker 镜像
安装步骤
1. 克隆项目
git clone https://github.com/hsliuping/TradingAgents-CN.git
cd TradingAgents-CN
2. 安装数据库
安装 MongoDB
Windows:

# 使用 Chocolatey
choco install mongodb

# 或使用 MSI 安装包从官网下载
# 安装后需要创建管理员用户（参考docker-compose.hub.nginx.yml配置）
# 用户名: admin
# 密码: tradingagents123
macOS:

# 使用 Homebrew
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb/brew/mongodb-community

# 创建管理员用户（参考docker-compose.hub.nginx.yml配置）
mongosh
> use admin
> db.createUser({
    user: "admin",
    pwd: "tradingagents123",
    roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
})
Linux (Ubuntu/Debian):

# 导入公钥
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc |sudo apt-key add -

# 创建列表文件
echo"deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse"|sudotee /etc/apt/sources.list.d/mongodb-org-5.0.list

# 更新并安装
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# 创建管理员用户（参考docker-compose.hub.nginx.yml配置）
mongosh
> use admin
> db.createUser({
    user: "admin",
    pwd: "tradingagents123",
    roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
})
安装 Redis
Windows:

# 使用 Chocolatey
choco install redis-64

# 或使用 MSOpenTech Redis
# 安装后需要设置密码（参考docker-compose.hub.nginx.yml配置）
# 密码: tradingagents123
macOS:

# 使用 Homebrew
brew install redis
brew services start redis

# 设置密码（参考docker-compose.hub.nginx.yml配置）
# 编辑配置文件: /usr/local/etc/redis.conf
# 添加: requirepass tradingagents123
brew services restart redis
Linux (Ubuntu/Debian):

sudo apt-get  update
sudo apt-get install redis-server
sudo systemctl start redis
sudo systemctl enable redis

# 设置密码（参考docker-compose.hub.nginx.yml配置）
# 编辑配置文件: /etc/redis/redis.conf
# 添加: requirepass tradingagents123
sudo systemctl restart redis
3. 配置后端环境
3.1 创建 Python 虚拟环境

# 创建虚拟环境（确保Python版本在3.10-3.12之间）
python -m venv venv

# 激活虚拟环境
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate
注意：确保使用Python 3.10-3.12版本，可以通过 python --version 检查版本。建议使用Python 3.10或3.11以获得最佳兼容性。

3.2 安装 Python 依赖

# 配置清华镜像
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 验证配置
pip config list

# 确保在 app 目录下且虚拟环境已激活
pip install -r requirements.txt 
3.3 配置环境变量
创建 .env 文件：

cp .env.example .env
编辑 .env 文件，配置以下关键参数：

# 数据库配置（参考docker-compose.hub.nginx.yml中的配置）
MONGODB_URL=mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin
REDIS_URL=redis://:tradingagents123@localhost:6379/0

# API 配置
API_BASE_URL=http://localhost:8000
CORS_ORIGINS=["http://localhost:3000"]

# LLM 配置（根据需要配置）
OPENAI_API_KEY=your_openai_key
DEEPSEEK_API_KEY=your_deepseek_key
SILICONFLOW_API_KEY=your_siliconflow_key

# 其他配置
DEBUG=true
LOG_LEVEL=INFO
数据库账号密码说明：

MongoDB
：用户名 admin，密码 tradingagents123，数据库 tradingagents
Redis
：密码 tradingagents123，无用户名（使用空用户名）
这些账号密码配置与 docker-compose.hub.nginx.yml 中的配置保持一致
⚠️ 重要提示：

生产环境请务必修改默认密码
MongoDB连接字符串中的 authSource=admin 参数表示在admin数据库中进行身份验证
Redis连接字符串中的 :tradingagents123 表示空用户名加密码的格式
4. 配置前端环境
4.1 安装 Node.js 依赖
cd frontend

# 使用 yarn进行安装
yarn install
5. 初始化数据库
5.1 启动 MongoDB 和 Redis
确保数据库服务正在运行：

# 检查 MongoDB
sudo systemctl status mongod  # Linux
brew services list |grep mongodb  # macOS

# 检查 Redis
sudo systemctl status redis  # Linux
brew services list |grep redis  # macOS
5.2 创建数据库用户和索引
创建MongoDB数据库用户：

# 连接MongoDB（使用管理员账户）
mongosh mongodb://admin:tradingagents123@localhost:27017/admin

# 切换到tradingagents数据库
use tradingagents

# 创建应用用户（可选，用于更细粒度的权限控制）
db.createUser({
  user: "tradingagents_user",
  pwd: "tradingagents123",
  roles: [
{ role: "readWrite", db: "tradingagents"}
]
})
创建数据库索引：


# 导入初始配置并创建默认管理员用户（必须执行）
python scripts/import_config_and_create_user.py --host

# 如果提示找不到配置文件，可以使用以下命令只创建用户
# python scripts/import_config_and_create_user.py --create-user-only --host
⚠️ 重要提示：import_config_and_create_user.py 脚本必须执行，注意要带上参数 --host ，它会：

导入系统配置数据到 MongoDB
创建默认管理员用户（用户名：admin，密码：admin123）
初始化 LLM 提供商、市场分类等基础数据
如果不执行此步骤，系统将无法正常运行，登录时会提示配置缺失。

或使用 MongoDB shell 手动创建集合和索引：

mongosh mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin

# 创建集合和索引
use tradingagents
db.createCollection('users')
db.createCollection('analyses')
db.createCollection('stock_basic_info')
6. 启动应用
6.1 启动后端服务

# 激活虚拟环境（如果未激活）
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# 确保已执行数据库初始化脚本（重要！）
python scripts/import_config_and_create_user.py --host

# 启动后端服务
python -m app
后端服务将在 http://localhost:8000 启动

⚠️ 注意：如果启动时报错提示配置缺失，请先执行数据库初始化脚本：python scripts/import_config_and_create_user.py --host

6.2 启动前端服务
cd frontend

# 启动开发服务器
npm run dev

# 或使用 yarn
yarn dev
前端服务将在 http://localhost:3000 启动

7. 验证安装
后端验证：

访问 http://localhost:8000/docs 查看 API 文档
访问 http://localhost:8000/health 检查健康状态
前端验证：

访问 http://localhost:3000 查看前端界面
检查浏览器控制台是否有错误
数据库验证：

# 连接 MongoDB
mongosh trading_agents

# 查看集合
show collections

# 检查数据
db.users.find().limit(5)
后端服务验证（新增）：

# 检查后端服务状态
curl http://localhost:8000/api/health

# 应该返回：{"status":"healthy","timestamp":"..."}

# 检查API文档
# 访问：http://localhost:8000/docs

# 验证数据库初始化是否成功
curl http://localhost:8000/api/system/config

# 应该返回系统配置信息，如果返回404或错误，说明数据库初始化未完成
高级配置
使用 Docker 安装
Docker安装方式请参考专门的Docker部署文档。

环境变量详解
后端环境变量
# 数据库（与docker-compose.hub.nginx.yml配置一致）
MONGODB_URL=mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin
REDIS_URL=redis://:tradingagents123@localhost:6379/0

# API 配置
API_BASE_URL=http://localhost:8000
CORS_ORIGINS=["http://localhost:3000"]

# LLM 配置
OPENAI_API_KEY=your_key
DEEPSEEK_API_KEY=your_key
SILICONFLOW_API_KEY=your_key

# 缓存配置
CACHE_TTL=3600
CACHE_MAX_SIZE=1000

# 日志配置
LOG_LEVEL=INFO
LOG_FILE=logs/app.log

# 安全配置（与docker-compose.hub.nginx.yml配置一致）
SECRET_KEY=docker-jwt-secret-key-change-in-production-2024
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
REFRESH_TOKEN_EXPIRE_DAYS=30
CSRF_SECRET=docker-csrf-secret-key-change-in-production-2024
BCRYPT_ROUNDS=12
故障排除
常见问题
1. 后端启动失败
问题：端口被占用

# 查找占用 8000 端口的进程
netstat -ano | findstr :8000  # Windows
lsof -i :8000  # macOS/Linux

# 终止进程
taskkill /PID <pid> /F  # Windows
kill -9 <pid># macOS/Linux
问题：依赖安装失败

# 升级 pip
python -m pip install --upgrade pip

# 清理缓存
pip cache purge

# 重新安装
pip install -r requirements.txt --force-reinstall
2. 前端构建失败
问题：Node.js 版本不兼容

# 检查 Node.js 版本
node --version

# 使用 nvm 切换版本
nvm use 18

# 清理 node_modules
rm -rf node_modules package-lock.json
yarn install
问题：内存不足

# 增加 Node.js 内存限制
export NODE_OPTIONS="--max-old-space-size=4096"

# 或使用 npm
npm run dev -- --max-old-space-size=4096
3. 数据库连接失败
问题：MongoDB 连接失败

# 检查 MongoDB 状态
sudo systemctl status mongod

# 重启 MongoDB
sudo systemctl restart mongod

# 检查连接字符串
mongosh "mongodb://localhost:27017/trading_agents"
问题：Redis 连接失败

# 检查 Redis 状态
sudo systemctl status redis

# 重启 Redis
sudo systemctl restart redis

# 测试连接
redis-cli ping
问题：后端启动时报错无法连接 MongoDB

解决方案：

检查 MongoDB 是否正在运行：

# Windows
net start MongoDB

# macOS/Linux
sudo systemctl status mongod
检查连接字符串是否正确

检查防火墙是否阻止了 27017 端口

问题：登录时报错 “系统配置缺失” 或 API 返回 404 错误

解决方案：

执行数据库初始化脚本（最常见问题）：

# 激活虚拟环境后
python scripts/import_config_and_create_user.py --host 
检查默认配置文件是否存在：

ls install/database_export_config_*.json
如果配置文件不存在，只创建用户：

python scripts/import_config_and_create_user.py --create-user-only --host
验证初始化是否成功：

curl http://localhost:8000/api/system/config
# 应该返回系统配置信息，而不是404错误
8.3 API 调用失败
问题：CORS 错误

# 检查后端 CORS 配置
grep -r "CORS_ORIGINS" app/

# 检查前端 API URL
grep -r "VITE_API_BASE_URL" frontend/
问题：认证失败

# 检查 JWT 配置
grep -r "SECRET_KEY" app/

# 检查用户权限
mongosh trading_agents --eval "db.users.find()"
8.4 默认用户无法登录
问题：使用 admin/admin123 无法登录

解决方案：

确认数据库初始化脚本已执行：

python scripts/import_config_and_create_user.py --host
检查用户是否已创建：

mongosh   mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin
> use tradingagents
> db.users.find({username: "admin"})
如果用户不存在，重新创建：

python scripts/import_config_and_create_user.py --create-user-only --host
检查密码是否正确：默认密码是 admin123

日志查看
后端日志
# 查看应用日志
tail -f logs\tradingagents.log

# 查看系统日志
journalctl -u your-app-service -f
前端日志
# 查看浏览器控制台（F12）
# 查看构建日志
cd frontend &&npm run dev
性能优化
后端优化
数据库索引优化：

# 创建复合索引
mongosh trading_agents --eval "db.analyses.createIndex({symbol: 1, date: -1})"
缓存配置：

CACHE_TTL=7200
CACHE_MAX_SIZE=2000
连接池配置：

MONGODB_MAX_POOL_SIZE=100
REDIS_MAX_CONNECTIONS=50
前端优化
构建优化：

# 生产构建
npm run build

# 分析包大小
npm run build -- --analyze
代码分割：

// 使用动态导入
const LazyComponent=()=>import('./components/LazyComponent.vue')
安全建议
更改默认密码：

# MongoDB
mongosh --eval "db.createUser({user: 'admin', pwd: 'strong_password', roles: ['root']})"

# Redis
redis-cli CONFIG SET requirepass "strong_password"
配置防火墙：

# 仅允许必要端口
sudo ufw allow 8000/tcp
sudo ufw allow 5173/tcp
sudo ufw enable
使用 HTTPS：

# 生成 SSL 证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
更新和维护
更新代码
# 拉取最新代码
git pull origin main

# 更新后端依赖
cd app && pip install -r requirements.txt --upgrade

# 更新前端依赖
cd frontend &&npm update
备份数据
# 备份 MongoDB
mongodump --db trading_agents --out ./backup/$(date +%Y%m%d)

# 备份 Redis
redis-cli SAVE
cp /var/lib/redis/dump.rdb ./backup/redis-$(date +%Y%m%d).rdb
监控和告警
# 设置监控脚本
cat> monitor.sh <<'EOF'
#!/bin/bash
# 检查服务状态
if ! curl -f http://localhost:8000/health; then
    echo "Backend service is down!" | mail -s "Alert" admin@example.com
fi
EOF

chmod +x monitor.sh
# 添加到 crontab
echo"*/5 * * * * /path/to/monitor.sh"|crontab -
获取帮助
GitHub Issues
: https://github.com/hsliuping/TradingAgents-CN/issues
文档
: 项目 docs/ 目录下的详细文档
微信公众号
: 搜索"TradingAgents-CN"关注获取最新资讯
邮件
: hsliup@163.com
重要提醒
🔴 安装完成后必须执行：python scripts/import_config_and_create_user.py  --host 

这是最常见的安装问题，如果不执行此步骤，系统将无法正常运行。

如果执行过程中遇到问题，请检查：

MongoDB 和 Redis 是否正常运行
数据库连接配置是否正确
虚拟环境是否已激活
Python 版本是否在 3.10-3.12 范围内
其他安装方式
如果您觉得源码安装比较复杂，我们还提供了更简单的安装方式：









