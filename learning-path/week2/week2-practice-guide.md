# Week 2 - Istio 服务网格实践指南

## 📋 实践目标

通过本周的学习和实践，您将能够：

1. **安装和配置 Istio** - 掌握 Istio 的安装和基础配置
2. **理解服务网格架构** - 理解 Sidecar 模式和控制平面
3. **实现流量管理** - 使用 VirtualService 和 DestinationRule
4. **灰度发布实践** - 配置金丝雀部署流程
5. **故障注入测试** - 使用 Istio 注入延迟和错误
6. **熔断器配置** - 配置断路器和超时策略

## 🛠️ 环境准备

### 前置条件
- Kubernetes 集群（Kind、Minikube 或其他）
- kubectl 已配置
- 至少 4GB RAM 可用
- Week 1 的电商服务已部署

### 安装 Istio

```bash
# 使用我们的安装脚本
cd /home/lw/homelab/ecommerce-microservices
./scripts/install-istio.sh

# 或者手动安装
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
```

## 📝 实践步骤

### 实验 1: 部署服务并注入 Sidecar

```bash
# 1. 创建命名空间并启用自动注入
kubectl create namespace ecommerce-microservices
kubectl label namespace ecommerce-microservices istio-injection=enabled

# 2. 部署 Week 1 的服务
kubectl apply -f infrastructure/kubernetes/user-service.yaml

# 3. 检查 Pod 状态（应该看到 2 个容器：应用 + envoy）
kubectl get pods -n ecommerce-microservices

# 4. 查看 Pod 详情
kubectl describe pod -n ecommerce-microservices -l app=user-service
```

**验证点**：
- [ ] Pod 中有 2 个容器（应用容器 + istio-proxy）
- [ ] istio-proxy 容器正常运行
- [ ] 应用容器正常运行

### 实验 2: 配置基础流量管理

```bash
# 1. 应用 Istio 配置
kubectl apply -f infrastructure/kubernetes/istio-config.yaml

# 2. 查看 VirtualService 和 DestinationRule
kubectl get vs,dr -n ecommerce-microservices

# 3. 测试流量路由
kubectl exec -n ecommerce-microservices -it user-service-xxx -c istio-proxy -- 
  curl http://user-service:8081/health
```

**验证点**：
- [ ] VirtualService 已创建
- [ ] DestinationRule 已创建
- [ ] 流量路由正常工作

### 实验 3: 实现灰度发布

**目标**：逐步将用户服务从 v1 迁移到 v2

```bash
# 当前配置：90% v1, 10% v2

# 步骤 1: 10% v2（已完成）
kubectl apply -f infrastructure/kubernetes/istio-config.yaml

# 步骤 2: 增加到 25% v2
# 编辑 istio-config.yaml，修改权重：
#   v1: 75, v2: 25
kubectl apply -f infrastructure/kubernetes/istio-config.yaml

# 步骤 3: 增加到 50% v2
# 编辑 istio-config.yaml，修改权重：
#   v1: 50, v2: 50
kubectl apply -f infrastructure/kubernetes/istio-config.yaml

# 步骤 4: 增加到 75% v2
# 编辑 istio-config.yaml，修改权重：
#   v1: 25, v2: 75
kubectl apply -f infrastructure/kubernetes/istio-config.yaml

# 步骤 5: 100% v2
# 编辑 istio-config.yaml，修改权重：
#   v1: 0, v2: 100
kubectl apply -f infrastructure/kubernetes/istio-config.yaml
```

**验证方法**：
```bash
# 生成流量并查看指标
for i in {1..100}; do
  curl http://user-service.local/api/v1/users
done

# 使用 Kiali 可视化（如果安装了）
# 或者查看 Prometheus 指标
```

### 实验 4: 故障注入测试

```bash
# 1. 应用故障注入配置
kubectl apply -f infrastructure/kubernetes/istio-advanced.yaml

# 2. 测试延迟注入
# 配置会为 50% 的请求注入 5 秒延迟
for i in {1..10}; do
  time curl http://user-service.local/api/v1/users
done

# 3. 测试错误注入
# 配置会为 10% 的请求返回 500 错误
for i in {1..50}; do
  curl -w "%{http_code}\n" http://user-service.local/api/v1/users
done
```

**验证点**：
- [ ] 延迟注入：部分请求明显变慢
- [ ] 错误注入：部分请求返回 500

### 实验 5: 配置熔断器

```bash
# 1. 应用熔断器配置
kubectl apply -f infrastructure/kubernetes/istio-advanced.yaml

# 2. 触发熔断条件
# 连续发送失败的请求
for i in {1..10}; do
  curl -H "Host: invalid.host" http://user-service.local/api/v1/users
done

# 3. 查看熔断器状态
istioctl proxy-config cluster user-service-xxx | grep circuit_breakers
```

**验证点**：
- [ ] 熔断器配置已应用
- [ ] 超过阈值后触发熔断
- [ ] 熔断恢复后流量正常

## 📊 Istio 管理命令

### 查看代理状态

```bash
# 查看所有代理的状态
istioctl proxy-status

# 查看特定服务的代理
istioctl proxy-status user-service-xxx -n ecommerce-microservices

# 查看代理配置
istioctl proxy-config cluster user-service-xxx
istioctl proxy-config listener user-service-xxx
istioctl proxy-config route user-service-xxx
```

### 调试和排查

```bash
# 查看代理日志
kubectl logs user-service-xxx -c istio-proxy -n ecommerce-microservices

# 查看 Istio 资源
kubectl get vs,dr,gateway,peerauthentication,authorizationpolicy -n ecommerce-microservices

# 查看代理统计
istioctl proxy-config bootstrap user-service-xxx
```

### 流量访问

```bash
# 通过 Ingress Gateway 访问
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

curl -H "Host: user-service.local" http://$INGRESS_HOST:$INGRESS_PORT/api/v1/users
```

## 🎯 验证清单

### 基础操作
- [ ] Istio 安装成功
- [ ] Sidecar 自动注入工作正常
- [ ] VirtualService 配置生效
- [ ] DestinationRule 配置生效

### 流量管理
- [ ] 流量路由规则生效
- [ ] 负载均衡正常工作
- [ ] 超时和重试配置生效

### 灰度发布
- [ ] 能够逐步增加 v2 流量
- [ ] 能够回滚到 v1
- [ ] 流量分割正确

### 故障测试
- [ ] 延迟注入测试通过
- [ ] 错误注入测试通过
- [ ] 熔断器工作正常

## 🐛 常见问题

### 1. Sidecar 未注入

```bash
# 检查命名空间标签
kubectl get namespace ecommerce-microservices --show-labels

# 重新标记
kubectl label namespace ecommerce-microservices istio-injection=enabled --overwrite

# 删除 Pod 让其重新创建
kubectl delete pod -n ecommerce-microservices -l app=user-service
```

### 2. 流量不按规则路由

```bash
# 检查 VirtualService
kubectl get vs user-service-vs -o yaml

# 检查代理配置
istioctl proxy-config route user-service-xxx
```

### 3. Envoy 配置错误

```bash
# 查看配置
istioctl proxy-config bootstrap user-service-xxx

# 重置配置
kubectl delete vs,dr -n ecommerce-microservices --all
kubectl apply -f infrastructure/kubernetes/istio-config.yaml
```

## 📚 扩展学习

### 高级主题

1. **mTLS 安全**
   - 配置双向 TLS
   - 证书管理

2. **链路追踪**
   - 集成 Jaeger
   - 查看分布式追踪

3. **可观测性**
   - 配置 Prometheus
   - 使用 Kiali 可视化

4. **服务间认证**
   - 配置授权策略
   - 实现基于 RBAC 的访问控制

---

**完成时间**: 2-3 天  
**预计投入**: 20-25 小时  
**难度**: ⭐⭐⭐⭐
