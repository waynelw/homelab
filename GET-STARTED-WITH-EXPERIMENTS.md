# 🎓 开始 Kubernetes 学习实验之旅

欢迎使用基于你的 homelab 环境设计的 Kubernetes 学习实验体系！

---

## 📚 实验体系概览

我为你设计了 **10 个实验模块**，涵盖 Kubernetes 从基础到高级的所有核心概念：

```
📖 实验一：Pod 生命周期      → 理解 K8s 最小调度单元
📖 实验二：控制器机制        → 掌握应用编排和管理
📖 实验三：网络原理          → 深入 Service 和网络
📖 实验四：存储与持久化      → 理解数据持久化方案
📖 实验五：配置管理          → 掌握 ConfigMap 和 Secret
📖 实验六：RBAC 和安全       → 实践权限控制
📖 实验七：调度机制          → 理解 Pod 调度原理
📖 实验八：监控和可观测性    → 实践监控和日志
📖 实验九：GitOps 实践       → 深入 Flux CD
📖 实验十：Tekton CI/CD      → 构建完整流水线
```

---

## 🚀 快速开始（3 步）

### 第 1 步：了解你的环境

你已经有了一个完整的 CI/CD 环境：

- ✅ **Kind**: 本地 Kubernetes 集群
- ✅ **Flux CD**: GitOps 持续部署
- ✅ **Tekton**: CI/CD 流水线
- ✅ **Prometheus + Grafana**: 监控系统
- ✅ **Docker Registry**: 私有镜像仓库

查看环境状态：
```bash
kubectl get pods -A
kubectl get nodes
```

### 第 2 步：创建实验命名空间

```bash
kubectl create namespace experiments
```

或者使用提供的脚本：
```bash
cd experiments
bash quick-start.sh
```

### 第 3 步：选择并运行第一个实验

**推荐从实验一开始**：

```bash
# 进入实验目录
cd experiments

# 运行第一个实验
kubectl apply -f 01-pod-lifecycle/basic-pod.yaml

# 观察 Pod 创建过程
kubectl get pods -n experiments -w

# 查看 Pod 详细信息
kubectl describe pod lifecycle-demo -n experiments

# 查看日志
kubectl logs lifecycle-demo -n experiments

# 进入 Pod 交互
kubectl exec -it lifecycle-demo -n experiments -- sh
```

---

## 📖 学习路径建议

### 🟢 入门路径（第 1-2 周）

如果你是 Kubernetes 初学者，建议按以下顺序：

1. **实验一：Pod 生命周期** (2-3 天)
   - 1.1 基础 Pod 和生命周期钩子
   - 1.2 重启策略实验
   - 1.3 Init Container

2. **实验二：控制器机制** (3-4 天)
   - 2.1 Deployment 滚动更新
   - 2.2 StatefulSet 有序部署
   - 2.3 DaemonSet 节点级部署

3. **实验三：网络原理** (2-3 天)
   - 3.1 Service 类型对比
   - 3.2 Headless Service 和 DNS
   - 3.3 NetworkPolicy 网络隔离

4. **实验五：配置管理** (1-2 天)
   - 5.1 ConfigMap 多种挂载方式
   - 5.2 Secret 敏感信息管理

### 🟡 进阶路径（第 3-4 周）

掌握基础后，深入高级特性：

5. **实验四：存储与持久化** (2-3 天)
   - 4.1 Volume 类型对比
   - 4.2 PV 和 PVC 实验
   - 4.3 StorageClass 动态供应

6. **实验六：RBAC 和安全** (2-3 天)
   - 6.1 ServiceAccount 和 RBAC
   - 6.2 SecurityContext 实验

7. **实验七：调度机制** (2-3 天)
   - 7.1 资源请求和限制
   - 7.2 节点亲和性
   - 7.3 Pod 亲和性和反亲和性

8. **实验八：监控和可观测性** (2-3 天)
   - 8.1 应用指标暴露
   - 8.2 自定义指标实验
   - 8.3 日志聚合实验

### 🔴 高级路径（第 5-6 周）

结合你的 CI/CD 环境：

9. **实验九：GitOps 实践** (3-4 天)
   - 9.1 Flux GitRepository
   - 9.2 Kustomization 声明式部署
   - 9.3 HelmRelease 管理

10. **实验十：Tekton CI/CD** (4-5 天)
    - 10.1 创建复杂的 Task
    - 10.2 构建完整的 CI Pipeline
    - 10.3 条件执行和错误处理

---

## 🛠️ 实验工具和资源

### 核心文件

| 文件 | 用途 |
|------|------|
| `K8S-LEARNING-EXPERIMENTS.md` | 📘 完整的实验设计文档（理论+实践） |
| `experiments/README.md` | 📄 实验目录说明 |
| `experiments/quick-start.sh` | 🚀 交互式实验启动脚本 |
| `experiments/useful-commands.md` | 📋 常用命令速查表 |
| `experiments/experiment-log-template.md` | 📝 实验记录模板 |

### 实验文件结构

```
experiments/
├── 01-pod-lifecycle/
│   ├── basic-pod.yaml
│   ├── restart-policy.yaml
│   └── init-container.yaml
├── 02-controllers/
│   ├── rolling-update.yaml
│   └── statefulset.yaml
├── 03-networking/
│   └── service-types.yaml
├── 05-config/
│   └── configmap.yaml
├── 06-security/
│   └── rbac-demo.yaml
├── ... (更多实验目录)
└── quick-start.sh
```

### 使用快速启动脚本

```bash
cd experiments

# 交互式菜单
bash quick-start.sh

# 查看当前状态
bash quick-start.sh status

# 清理资源
bash quick-start.sh cleanup
```

---

## 📝 学习最佳实践

### 1. 边做边记录

使用提供的实验记录模板：

```bash
cp experiments/experiment-log-template.md my-experiments/experiment-1.1.md
```

记录内容：
- ✅ 执行的命令和输出
- ✅ 观察到的现象
- ✅ 遇到的问题和解决方案
- ✅ 关键学习点
- ✅ 疑问和待研究的点

### 2. 主动实验

不要只是运行提供的 YAML：
- 🔧 修改参数观察结果变化
- 🔧 故意制造错误学习排错
- 🔧 尝试不同的配置组合
- 🔧 设计自己的实验变体

### 3. 深入源码和文档

遇到不理解的概念：
- 📚 阅读 Kubernetes 官方文档
- 📚 查看相关组件的源码
- 📚 搜索 GitHub Issues 和 Discussions
- 📚 参与社区讨论

### 4. 建立知识体系

定期回顾和总结：
- 📊 绘制概念图和架构图
- 📊 建立知识点之间的联系
- 📊 写博客或技术文章分享
- 📊 解答其他人的问题来巩固

---

## 🎯 每个实验的学习目标

### 实验一：Pod 生命周期
**掌握**: Pod 状态转换、生命周期钩子、健康检查、重启策略

**关键问题**:
- Pod 从创建到运行经历哪些阶段？
- postStart 和 preStop 何时执行？
- livenessProbe 和 readinessProbe 的区别？

### 实验二：控制器机制
**掌握**: Deployment/StatefulSet/DaemonSet 的使用场景和内部机制

**关键问题**:
- ReplicaSet 和 Deployment 的关系？
- 滚动更新如何保证零停机？
- StatefulSet 如何保证有序性？

### 实验三：网络原理
**掌握**: Service 类型、负载均衡、DNS 解析、网络策略

**关键问题**:
- ClusterIP 的实现原理（kube-proxy）？
- Service 如何发现和更新后端 Pod？
- NetworkPolicy 如何实现网络隔离？

### 实验四：存储与持久化
**掌握**: Volume、PV/PVC、StorageClass、动态供应

**关键问题**:
- emptyDir 和 PV 的生命周期差异？
- PV 和 PVC 的绑定机制？
- StorageClass 如何实现动态供应？

### 实验五：配置管理
**掌握**: ConfigMap 和 Secret 的使用方式、热更新

**关键问题**:
- ConfigMap 的三种挂载方式？
- 配置更新后应用如何感知？
- Secret 的 base64 编码是否安全？

### 实验六：RBAC 和安全
**掌握**: ServiceAccount、Role/RoleBinding、SecurityContext

**关键问题**:
- K8s 的认证和授权流程？
- Role 和 ClusterRole 的区别？
- 如何实现最小权限原则？

### 实验七：调度机制
**掌握**: 资源配额、节点选择、亲和性和反亲和性

**关键问题**:
- Scheduler 如何选择节点？
- requests 和 limits 的区别？
- Pod 亲和性的应用场景？

### 实验八：监控和可观测性
**掌握**: Prometheus 指标收集、Grafana 可视化、日志聚合

**关键问题**:
- 如何暴露应用指标？
- Prometheus 如何发现监控目标？
- 如何设计有效的告警规则？

### 实验九：GitOps 实践
**掌握**: Flux CD 工作流、Kustomization、HelmRelease

**关键问题**:
- GitOps 的核心原则？
- Flux 如何实现自动同步？
- 如何管理多环境配置？

### 实验十：Tekton CI/CD
**掌握**: Task/Pipeline 设计、Workspace 共享、条件执行

**关键问题**:
- Tekton 的架构组件？
- 如何在 Task 之间传递数据？
- 如何实现复杂的流水线逻辑？

---

## 🐛 常见问题和排错

### 问题 1: Pod 一直处于 Pending 状态

**排查步骤**:
```bash
kubectl describe pod <pod-name> -n experiments
kubectl get events -n experiments --sort-by='.lastTimestamp'
kubectl top nodes
```

**可能原因**:
- 资源不足（CPU/内存）
- PVC 未绑定
- 镜像拉取失败
- 节点选择器不匹配

### 问题 2: 无法访问 Service

**排查步骤**:
```bash
kubectl get svc -n experiments
kubectl get endpoints <service-name> -n experiments
kubectl run test --rm -it --image=busybox -n experiments -- wget -O- http://<service-name>
```

**可能原因**:
- Service selector 不匹配 Pod labels
- Pod 未就绪（readinessProbe 失败）
- 网络策略阻止访问

### 问题 3: ConfigMap 更新但应用未生效

**原因**: 环境变量方式不会自动更新

**解决方案**:
- 使用 Volume 挂载（会自动更新，约 1 分钟延迟）
- 或者重启 Pod: `kubectl rollout restart deployment/<name> -n experiments`

### 问题 4: RBAC 权限错误

**排查步骤**:
```bash
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name> -n <namespace>
kubectl describe role <role-name> -n experiments
kubectl describe rolebinding <rolebinding-name> -n experiments
```

---

## 📊 学习进度追踪

创建一个进度文件来追踪你的学习：

```bash
cat > my-progress.md << 'EOF'
# My Kubernetes Learning Progress

## 实验完成情况

- [ ] 实验 1.1: 基础 Pod 和生命周期钩子
- [ ] 实验 1.2: 重启策略实验
- [ ] 实验 1.3: Init Container
- [ ] 实验 2.1: Deployment 滚动更新
- [ ] 实验 2.2: StatefulSet 有序部署
- [ ] 实验 3.1: Service 类型对比
...

## 知识点掌握程度

| 知识点 | 理解程度 | 实践经验 | 备注 |
|--------|----------|----------|------|
| Pod 生命周期 | ⭐⭐⭐ | ⭐⭐ | 需要深入理解重启策略 |
| Deployment | ⭐⭐⭐⭐ | ⭐⭐⭐ | 已完成滚动更新实验 |
...

## 待解决的问题

1. StatefulSet 的 PVC 回收策略？
2. NetworkPolicy 的性能影响？
...

## 下一步计划

- [ ] 完成实验四
- [ ] 研究 Operator 开发
- [ ] 尝试多集群管理
EOF
```

---

## 🎓 学习资源推荐

### 官方文档
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Flux CD 文档](https://fluxcd.io/docs/)
- [Tekton 文档](https://tekton.dev/docs/)

### 书籍推荐
- 《Kubernetes in Action》
- 《Programming Kubernetes》
- 《Cloud Native DevOps with Kubernetes》

### 在线课程
- [Kubernetes 官方培训](https://kubernetes.io/training/)
- [CNCF 认证课程](https://www.cncf.io/certification/)

### 社区和论坛
- [Kubernetes Slack](https://slack.k8s.io/)
- [CNCF Slack](https://slack.cncf.io/)
- [GitHub Discussions](https://github.com/kubernetes/kubernetes/discussions)

---

## 🏆 学习里程碑

### 🥉 初级 (1-2 个月)
- ✅ 完成实验 1-3
- ✅ 能独立部署和管理应用
- ✅ 理解 Pod、Service、Deployment 等基础概念
- ✅ 能使用 kubectl 进行基本操作

### 🥈 中级 (3-4 个月)
- ✅ 完成实验 4-7
- ✅ 掌握存储、配置、权限管理
- ✅ 能设计和实施 RBAC 策略
- ✅ 能进行问题排查和性能优化

### 🥇 高级 (5-6 个月)
- ✅ 完成实验 8-10
- ✅ 掌握监控、日志、追踪体系
- ✅ 能设计和实施 GitOps 工作流
- ✅ 能构建完整的 CI/CD 流水线

### 🏅 专家级 (持续学习)
- ✅ 开发自定义 Operator
- ✅ 贡献开源项目
- ✅ 通过 CKA/CKAD/CKS 认证
- ✅ 分享知识，帮助他人

---

## 💬 反馈和改进

在学习过程中：
- 📝 记录你的问题和建议
- 📝 分享你的实验结果和心得
- 📝 提出新的实验想法
- 📝 改进实验设计

---

## 🎉 开始你的学习之旅

现在你已经准备好了！选择一个实验，动手开始吧：

```bash
# 进入实验目录
cd /home/lw/homelab/experiments

# 创建命名空间
kubectl create namespace experiments

# 运行第一个实验
kubectl apply -f 01-pod-lifecycle/basic-pod.yaml

# 观察结果
kubectl get pods -n experiments -w
```

**祝你学习顺利，享受 Kubernetes 的魅力！** 🚀

---

**创建时间**: 2024-10-12  
**适用环境**: Kind + Flux + Tekton  
**维护者**: Wayne
