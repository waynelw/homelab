# Week 8: 成本优化与生产就绪

## 🎯 本周学习目标

1. **资源优化**：请求与限制最佳实践
2. **Spot 实例**：成本优化策略
3. **VPA**：垂直 Pod 自动伸缩
4. **成本监控**：Kubecost / OpenCost
5. **生产检查清单**：上线前准备
6. **文档与知识库**：运维手册建设

## 📚 核心学习内容

### 1. 资源请求与限制

```yaml
resources:
  requests:
    cpu: 100m      # 最少的 CPU 保证
    memory: 128Mi  # 最少的内存保证
  limits:
    cpu: 200m      # 最大 CPU 限制
    memory: 256Mi  # 最大内存限制
```

### 2. VPA 自动伸缩

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: user-service-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: user-service
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 500m
        memory: 512Mi
```

### 3. OpenCost 成本监控

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: opencost-config
data:
  pricing-config.csv: |
    CPU,0.031611
    RAM,0.004237
    storage,0.0001388888888888889
    gpu,1.5
```

### 4. 生产环境检查清单

```markdown
## 生产环境检查清单

### 高可用
- [ ] 至少 3 个副本
- [ ] Pod Disruption Budget 已配置
- [ ] 节点亲和性和反亲和性
- [ ] 多区域部署

### 监控和日志
- [ ] Prometheus 指标监控
- [ ] Loki 日志聚合
- [ ] Tempo 分布式追踪
- [ ] 告警规则已配置

### 安全
- [ ] Pod Security Standards
- [ ] Network Policy
- [ ] Secrets 管理
- [ ] RBAC 权限控制

### 备份和恢复
- [ ] Velero 备份已配置
- [ ] 数据定期备份
- [ ] 灾难恢复计划
- [ ] 恢复测试通过

### 性能
- [ ] 资源请求和限制已配置
- [ ] HPA 自动伸缩
- [ ] 性能测试通过
- [ ] 容量规划完成

### 文档
- [ ] 架构文档
- [ ] 运维手册
- [ ] 故障排查指南
- [ ] 监控和告警文档
```

---

**预计完成时间**: 3-4 天  
**每周投入**: 20-25 小时

## 🎉 完成学习路径

恭喜完成 8 周云原生学习路径！

### 获得的核心能力

- ✅ 微服务架构设计与开发
- ✅ 服务网格（Istio）
- ✅ 可观测性（日志、追踪、指标）
- ✅ 混沌工程与弹性设计
- ✅ 基础设施即代码（IaC）
- ✅ CI/CD 流水线
- ✅ 云原生安全
- ✅ 成本优化与生产就绪

### 下一步

- 准备 CKA/CKAD 认证
- 参与开源项目贡献
- 在团队中推广云原生实践
- 深入学习专家级主题（eBPF、WebAssembly 等）
