# Week 4: 混沌工程与弹性设计

## 🎯 本周学习目标

1. **理解弹性模式**：重试、超时、熔断、限流
2. **掌握 Chaos Mesh**：混沌工程平台的使用
3. **实现自动伸缩**：HPA、VPA、KEDA
4. **配置 PDB**：Pod Disruption Budget
5. **备份与恢复**：Velero 灾难恢复

## 📚 核心学习内容

### 1. 弹性模式（Resilience Patterns）

#### 重试（Retry）
```go
import "time"

func retry(maxAttempts int, fn func() error) error {
    var err error
    for i := 0; i < maxAttempts; i++ {
        err = fn()
        if err == nil {
            return nil
        }
        time.Sleep(time.Second * time.Duration(i+1))
    }
    return err
}
```

#### 熔断器（Circuit Breaker）
- 三种状态：关闭、打开、半开
- 连续错误数超过阈值则打开
- 等待时间后进入半开状态

#### 限流（Rate Limiting）
- 令牌桶算法
- 漏桶算法
- 固定窗口、滑动窗口

### 2. Chaos Mesh 混沌工程

#### 支持的故障类型
- Pod 故障：删除 Pod、CPU 负载、内存压力
- 网络故障：延迟、丢包、分区
- 文件系统故障：I/O 错误、磁盘故障
- 时间故障：时钟偏移

#### Chaos 实验
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-experiment
  namespace: ecommerce-microservices
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - ecommerce-microservices
    labelSelectors:
      app: user-service
  scheduler:
    cron: "@every 1h"
```

### 3. 自动伸缩（Auto Scaling）

#### HPA（Horizontal Pod Autoscaler）
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### VPA（Vertical Pod Autoscaler）
- 自动调整 Pod 资源请求和限制
- 基于历史使用数据推荐

#### KEDA（Kubernetes Event-Driven Autoscaling）
- 基于消息队列等外部指标
- 支持多种缩放器

### 4. Pod Disruption Budget (PDB)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: user-service-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: user-service
```

### 5. 备份与恢复（Velero）

```bash
# 安装 Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.7.0 \
  --bucket my-backup-bucket \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1

# 创建备份
velero backup create my-backup --include-namespaces ecommerce-microservices

# 恢复备份
velero restore create --from-backup my-backup
```

## 🎯 实践项目

### 系统弹性改造

1. **配置 HPA 自动扩缩容**
2. **使用 Chaos Mesh 注入故障**
3. **设置 Pod Disruption Budget**
4. **测试服务降级策略**
5. **配置 Velero 备份**

---

**预计完成时间**: 3-4 天  
**每周投入**: 20-25 小时
