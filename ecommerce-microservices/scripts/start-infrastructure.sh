#!/bin/bash

# 电商微服务系统启动脚本

set -e

echo "🚀 启动电商微服务系统..."

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装"
    exit 1
fi

# 创建网络
echo "📡 创建 Docker 网络..."
docker network create ecommerce-network 2>/dev/null || true

# 启动基础设施服务
echo "🏗️ 启动基础设施服务..."
cd infrastructure/docker-compose
docker-compose up -d postgres redis rabbitmq

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

echo "✅ 基础设施服务启动完成！"
echo ""
echo "📊 服务访问地址："
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - RabbitMQ Management: http://localhost:15672 (admin/admin)"
echo ""
echo "🔧 下一步："
echo "  1. 启动用户服务: cd services/user-service && go run cmd/main.go"
echo "  2. 访问 Swagger 文档: http://localhost:8081/swagger/index.html"
echo "  3. 健康检查: curl http://localhost:8081/health"
