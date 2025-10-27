# Week 3 - 可观测性实践指南

## 🎯 实践目标

通过本周的学习和实践，您将：

1. **部署 Loki 日志系统**
2. **部署 Tempo 分布式追踪**
3. **部署 OpenTelemetry Collector**
4. **在应用中集成 OpenTelemetry SDK**
5. **配置 Grafana 统一面板**
6. **定义 SLO 和配置告警**

## 📋 前置条件

- Kubernetes 集群已就绪
- Istio 已安装（Week 2）
- Helm 3.x 已安装
- 应用服务已部署

## 🚀 快速开始

### Step 1: 安装 Helm Charts

```bash
# 添加 Grafana Helm Chart 仓库
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# 创建命名空间
kubectl create namespace observability
```

### Step 2: 部署 Loki

```bash
# 安装 Loki（包含 Promtail）
helm install loki grafana/loki \
  -n observability \
  --set promtail.enabled=true \
  --set promtail.tolerations[0].key="node-role.kubernetes.io/master" \
  --set promtail.tolerations[0].effect="NoSchedule" \
  --set promtail.resources.limits.memory=256Mi \
  --set promtail.resources.requests.memory=128Mi

# 验证部署
kubectl get pods -n observability -l app=loki
```

### Step 3: 部署 Tempo

```bash
# 安装 Tempo
helm install tempo grafana/tempo \
  -n observability \
  --set storage.retention=30d \
  --set persistence.size=10Gi

# 验证部署
kubectl get pods -n observability -l app.kubernetes.io/name=tempo
```

### Step 4: 部署 OpenTelemetry Collector

```bash
# 安装 OpenTelemetry Operator
helm install opentelemetry-operator \
  opentelemetry/opentelemetry-operator \
  -n observability

# 等待 Operator 启动
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=opentelemetry-operator \
  -n observability \
  --timeout=300s

# 部署 Collector
kubectl apply -f infrastructure/observability/otel-collector.yaml

# 验证部署
kubectl get pods -n observability -l app=otel-collector
```

### Step 5: 配置 Grafana

```bash
# 应用 Grafana 配置
kubectl apply -f infrastructure/observability/grafana-config.yaml

# 访问 Grafana
kubectl port-forward -n observability svc/grafana 3000:80

# 浏览器访问 http://localhost:3000
# 默认用户名/密码: admin/admin
```

### Step 6: 集成 OpenTelemetry SDK

在应用代码中添加 OpenTelemetry 支持：

```go
// go.mod
require (
    go.opentelemetry.io/otel v1.20.0
    go.opentelemetry.io/otel/trace v1.20.0
    go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin v0.45.0
    go.opentelemetry.io/otel/exporters/jaeger v1.17.0
    go.opentelemetry.io/otel/sdk v1.20.0
)
```

### Step 7: 测试可观测性

```bash
# 生成一些流量
for i in {1..100}; do
  curl http://user-service.local/api/v1/users
done

# 查看 Loki 日志
# 在 Grafana 中切换到 Loki 数据源，查询: {app="user-service"}

# 查看 Tempo 追踪
# 在 Grafana 中切换到 Tempo 数据源，查看 Service Map

# 查看 Prometheus 指标
# 在 Grafana 中切换到 Prometheus 数据源，查询: up
```

## 📊 验证清单

### Loki 日志
- [ ] Loki 服务运行正常
- [ ] Promtail 收集日志正常
- [ ] 能在 Grafana 查询日志
- [ ] 日志链路追踪工作正常

### Tempo 追踪
- [ ] Tempo 服务运行正常
- [ ] 追踪数据正常收集
- [ ] Service Map 正常显示
- [ ] Trace 详情正常查看

### Prometheus 指标
- [ ] Prometheus 服务运行正常
- [ ] 指标正常抓取
- [ ] PromQL 查询正常
- [ ] 告警规则生效

### Grafana 面板
- [ ] 仪表板正常显示
- [ ] 数据源配置正确
- [ ] 日志链路追踪正常
- [ ] 告警正常触发

## 🐛 故障排查

### Loki 问题

```bash
# 检查 Loki 状态
kubectl logs -n observability -l app=loki

# 检查 Promtail 配置
kubectl logs -n observability -l app=promtail

# 测试 Loki API
kubectl port-forward -n observability svc/loki 3100:3100
curl http://localhost:3100/ready
```

### Tempo 问题

```bash
# 检查 Tempo 状态
kubectl logs -n observability -l app.kubernetes.io/name=tempo

# 测试 Tempo API
kubectl port-forward -n observability svc/tempo 3200:3200
curl http://localhost:3200/ready
```

### OpenTelemetry Collector 问题

```bash
# 检查 Collector 状态
kubectl logs -n observability -l app=otel-collector

# 检查配置
kubectl get cm otel-collector-config -n observability -o yaml
```

## 📈 SLO 定义和监控

### 核心 SLO

```yaml
SLO:
  user-service:
    availability: 99.5%  # 可用性
    latency_p95: 200ms    # P95 延迟
    latency_p99: 500ms    # P99 延迟
    error_rate: 0.5%      # 错误率
  
  product-service:
    availability: 99.5%
    latency_p95: 200ms
    latency_p99: 500ms
    error_rate: 0.5%
  
  order-service:
    availability: 99.9%   # 订单服务更高要求
    latency_p95: 300ms
    latency_p99: 1000ms
    error_rate: 0.1%
```

### 告警配置

```yaml
告警分级:
  P0: 关键服务完全不可用
  P1: 核心功能受影响
  P2: 非核心功能受影响
  P3: 性能指标异常
```

## 🎓 学习成果

完成本周学习后，您应该能够：

- ✅ 部署完整的可观测性系统
- ✅ 使用 Loki 查询和聚合日志
- ✅ 使用 Tempo 查看分布式追踪
- ✅ 使用 Prometheus 高级查询
- ✅ 定义和监控 SLO
- ✅ 配置分级告警策略
- ✅ 在 Grafana 创建统一面板

## 📚 参考资源

- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [Loki 查询语法](https://grafana.com/docs/loki/latest/logql/)
- [Prometheus 查询](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana 文档](https://grafana.com/docs/grafana/latest/)

---

**预计完成时间**: 3-4 天  
**每周投入**: 20-25 小时
