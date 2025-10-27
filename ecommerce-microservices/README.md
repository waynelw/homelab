# Ecommerce Microservices System

## 🏗️ 系统架构

这是一个基于 Go 语言开发的电商微服务系统，包含三个核心服务：

- **User Service**: 用户管理服务
- **Product Service**: 商品管理服务  
- **Order Service**: 订单管理服务

## 🚀 快速开始

### 环境要求

- Go 1.21+
- PostgreSQL 13+
- Redis 6+
- Docker & Docker Compose

### 启动服务

```bash
# 启动基础设施
docker-compose up -d postgres redis rabbitmq

# 启动用户服务
cd services/user-service
go run cmd/main.go

# 启动商品服务
cd services/product-service
go run cmd/main.go

# 启动订单服务
cd services/order-service
go run cmd/main.go
```

### API 文档

- User Service: http://localhost:8081/swagger/index.html
- Product Service: http://localhost:8082/swagger/index.html
- Order Service: http://localhost:8083/swagger/index.html

## 📁 项目结构

```
ecommerce-microservices/
├── services/           # 微服务实现
├── shared/            # 共享库
├── infrastructure/    # 基础设施配置
├── docs/             # 文档
└── scripts/          # 脚本工具
```

## 🎯 学习目标

通过这个项目学习：

1. 微服务架构设计原则
2. RESTful API 和 gRPC 服务开发
3. 服务间通信模式
4. 数据库设计和数据一致性
5. 容器化部署

## 📚 相关文档

- [Week 1 学习指南](./week1-microservices-guide.md)
- [API 文档](./docs/api/)
- [架构设计](./docs/architecture/)
- [部署指南](./docs/deployment/)
