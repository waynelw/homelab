# 🏠 Homelab CI/CD 轻量级方案

基于 **Kind + Flux + Tekton** 的轻量级 CI/CD 解决方案，专为学习和实验环境设计。

## 🎯 架构概览

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Git Repository │    │   Tekton CI      │    │  Kind Cluster   │
│   (Source Code)  │───▶│  (Build/Test)    │───▶│   (Flux CD)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌──────────────────┐             │
         │              │ Docker Registry  │             │
         │              │  (Image Store)   │             │
         │              └──────────────────┘             │
         │                                                │
         └────────────────────────────────────────────────┘
                           GitOps Flow
```

## 🛠️ 组件清单

### 核心组件 (轻量级)
- **Kind**: 本地Kubernetes集群
- **Flux**: GitOps持续部署
- **Tekton**: 云原生CI流水线
- **Docker Registry**: 轻量级镜像仓库

### 监控和日志 (精简版)
- **Prometheus**: 指标收集 (7天保留)
- **Grafana**: 可视化仪表板
- **Loki**: 轻量级日志聚合
- **Promtail**: 日志收集器

### 资源占用估算
```
组件                CPU请求    内存请求    存储需求
─────────────────────────────────────────────────
Tekton              200m       256Mi       -
Docker Registry     50m        128Mi       10Gi
Prometheus          200m       256Mi       8Gi
Grafana             100m       128Mi       1Gi
Loki                100m       128Mi       5Gi
Promtail            50m        64Mi        -
─────────────────────────────────────────────────
总计                700m       960Mi       24Gi
```

## 🚀 快速开始

### 1. 前置条件
```bash
# 确保已安装
- Docker
- Kind
- kubectl
- Flux CLI (可选)
```

### 2. 一键部署
```bash
# 克隆仓库
git clone https://github.com/waynelw/homelab.git
cd homelab

# 执行部署脚本
./scripts/deploy-cicd.sh
```

### 3. 验证部署
```bash
# 检查所有Pod状态
kubectl get pods -A

# 检查Flux同步状态
kubectl get gitrepository,kustomization -A
```

## 🎛️ 访问服务

### Tekton Dashboard
```bash
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
# 访问: http://localhost:9097
```

### Grafana 监控
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# 访问: http://localhost:3000
# 用户名: admin / 密码: admin123
```

### Docker Registry
```bash
kubectl port-forward -n registry svc/docker-registry 5000:5000
# 访问: http://localhost:5000
```

## 📁 目录结构

```
homelab/
├── clusters/kind-homelab/           # Flux配置
│   ├── flux-system/                 # Flux系统配置
│   ├── infrastructure/              # 基础设施组件
│   │   ├── sources/                 # Git和Helm源
│   │   ├── registry/                # Docker Registry
│   │   ├── tekton/                  # Tekton CI
│   │   ├── monitoring/              # Prometheus + Grafana
│   │   └── logging/                 # Loki + Promtail
│   └── apps/                        # 应用部署
│       └── demo-app/                # 示例应用
├── scripts/                         # 部署脚本
└── README-CICD.md                   # 本文档
```

## 🔄 CI/CD 工作流

### 1. 代码提交触发
```bash
# 开发者提交代码
git add .
git commit -m "feat: add new feature"
git push origin main
```

### 2. Tekton 构建流水线
```yaml
# 自动触发的Pipeline步骤:
1. 拉取源码 (git-clone)
2. 构建镜像 (buildah)
3. 推送到Registry
4. 部署到集群 (kubectl)
```

### 3. Flux 自动同步
```bash
# Flux监控Git仓库变化
# 自动应用Kubernetes配置
# 实现GitOps持续部署
```

## 🛡️ 安全配置

### RBAC 权限控制
- Tekton Pipeline 专用ServiceAccount
- 最小权限原则
- 命名空间隔离

### 镜像安全
- 私有Registry
- 镜像扫描 (可选集成Trivy)
- 签名验证 (可选)

## 📊 监控告警

### Prometheus 指标
- 集群资源使用率
- Pod健康状态
- 应用性能指标

### Grafana 仪表板
- Kubernetes集群概览
- Node资源监控
- Pod性能分析

### 日志聚合
- 容器日志收集
- 应用错误追踪
- 审计日志记录

## 🔧 故障排查

### 常见问题

1. **Pod启动失败**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

2. **Flux同步失败**
```bash
flux get sources git
flux logs --level=error
```

3. **Tekton Pipeline失败**
```bash
kubectl get pipelinerun -A
kubectl logs <pipelinerun-pod> -n tekton-pipelines
```

### 资源不足
```bash
# 检查节点资源
kubectl top nodes
kubectl top pods -A

# 调整资源限制
# 编辑对应的HelmRelease配置
```

## 🚀 扩展功能

### 添加新的CI工具
- Jenkins (重量级选择)
- GitLab CI (如果使用GitLab)
- GitHub Actions (云端CI)

### 增强安全性
- Sealed Secrets (密钥管理)
- OPA Gatekeeper (策略控制)
- Falco (运行时安全)

### 高级监控
- Jaeger (分布式追踪)
- AlertManager (告警管理)
- Slack/钉钉集成

## 📚 学习资源

- [Tekton 官方文档](https://tekton.dev/docs/)
- [Flux 官方文档](https://fluxcd.io/docs/)
- [Kind 官方文档](https://kind.sigs.k8s.io/)
- [Prometheus 官方文档](https://prometheus.io/docs/)

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

MIT License
