# 8周云原生学习路径 - 完整指南

## 📁 目录结构

```
learning-path/
├── README.md                          # 本文件
├── cloud-native-learning-plan.md      # 完整学习计划
├── cloud-native-roadmap-summary.md    # 学习路线总结
├── implementation-summary.md          # 实施总结
│
├── week1/                              # Week 1: 微服务架构与 API 设计
│   ├── week1-microservices-guide.md  # 学习指南
│   └── week1-progress.md              # 进度总结
│
├── week2/                              # Week 2: 服务网格入门
│   ├── week2-istio-guide.md          # 学习指南
│   ├── week2-practice-guide.md       # 实践指南
│   ├── week2-progress.md              # 进度总结
│   └── week2-quickstart.md            # 快速开始
│
├── week3/                              # Week 3: 云原生可观测性
│   ├── week3-observability-guide.md  # 学习指南
│   ├── week3-practice-guide.md       # 实践指南
│   └── week3-progress.md              # 进度总结
│
├── week4/                              # Week 4: 混沌工程与弹性设计
│   ├── week4-resilience-guide.md     # 学习指南
│   └── week4-progress.md              # 进度总结
│
├── week5/                              # Week 5: 基础设施即代码
│   ├── week5-iac-guide.md            # 学习指南
│   └── week5-progress.md              # 进度总结
│
├── week6/                              # Week 6: CI/CD 流水线深化
│   ├── week6-cicd-guide.md            # 学习指南
│   └── week6-progress.md              # 进度总结
│
├── week7/                              # Week 7: 云原生安全最佳实践
│   ├── week7-security-guide.md       # 学习指南
│   └── week7-progress.md              # 进度总结
│
└── week8/                              # Week 8: 成本优化与生产就绪
    ├── week8-production-guide.md     # 学习指南
    └── week8-progress.md              # 进度总结
```

## 🎯 学习路径概览

### 阶段一：云原生应用开发基础（Week 1-2）

**Week 1 - 微服务架构与 API 设计**
- 微服务拆分原则（DDD）
- RESTful API 设计
- gRPC 服务开发
- 电商系统（3个微服务）

**Week 2 - 服务网格入门**
- Istio 安装和配置
- 流量管理（VirtualService、DestinationRule）
- 灰度发布和金丝雀部署
- 熔断和超时控制

### 阶段二：可观测性与稳定性工程（Week 3-4）

**Week 3 - 云原生可观测性**
- Loki 日志聚合
- Tempo 分布式追踪
- Prometheus 高级查询
- OpenTelemetry 集成

**Week 4 - 混沌工程与弹性设计**
- Chaos Mesh 混沌工程
- HPA/VPA/KEDA 自动伸缩
- Pod Disruption Budget
- Velero 备份与恢复

### 阶段三：平台工程与 DevOps 进阶（Week 5-6）

**Week 5 - 基础设施即代码**
- Terraform 基础和应用
- Helm Chart 开发
- Kustomize 多环境配置
- ArgoCD ApplicationSet

**Week 6 - CI/CD 流水线深化**
- 镜像安全（Trivy）
- 多阶段构建优化
- 自动化测试
- 部署策略（蓝绿、金丝雀）

### 阶段四：安全、成本与生产就绪（Week 7-8）

**Week 7 - 云原生安全**
- Pod Security Standards
- Network Policy
- OPA/Gatekeeper
- Secrets 管理
- RBAC 最佳实践

**Week 8 - 成本优化与生产就绪**
- 资源优化
- Spot 实例策略
- VPA 自动伸缩
- 成本监控（OpenCost）
- 生产检查清单

## 📚 如何使用

### 1. 按周次顺序学习
从 Week 1 开始，依次完成每周围的学习和实践。

### 2. 阅读学习指南
每个周次都有详细的学习指南，包含：
- 学习目标
- 核心知识点
- 实践项目
- 推荐资源

### 3. 完成实践项目
动手实践是学习的关键，完成每个周次的实践项目。

### 4. 记录学习进度
在每周的 progress 文件中记录学习心得和遇到的问题。

## 🚀 快速开始

```bash
# 查看 Week 1 内容
cd week1
cat week1-microservices-guide.md

# 查看 Week 2 内容
cd ../week2
cat week2-istio-guide.md

# 查看整体进度
cd ..
cat cloud-native-roadmap-summary.md
```

## 📊 当前进度

- ✅ Week 1: 微服务架构（100% 完成）
- ✅ Week 2: 服务网格（100% 完成）
- ✅ Week 3: 可观测性（50% 完成）
- ✅ Week 4-8: 文档准备完成

## 🎓 学习建议

### 每日时间分配
- 上午（2-3小时）：理论学习
- 下午（3-4小时）：动手实践
- 晚上（1小时）：复盘总结

### 每周目标
1. 完成理论学习
2. 完成实践项目
3. 记录学习笔记
4. 准备下周内容

## 📖 推荐资源

### 官方文档
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Istio 官方文档](https://istio.io/latest/docs/)
- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [CNCF 项目](https://www.cncf.io/projects/)

### 在线课程
- [Linux Foundation 培训](https://training.linuxfoundation.org/)
- [Tetrate Academy](https://academy.tetrate.io/)

### 书籍推荐
1. 《微服务架构设计模式》（Chris Richardson）
2. 《云原生模式》（Cornelia Davis）
3. 《Site Reliability Engineering》（Google SRE）
4. 《Production Kubernetes》（Josh Rosso）

## 🎯 完成标准

完成 8 周学习后，您应该能够：
- ✅ 设计并实现微服务架构
- ✅ 使用 Istio 管理服务网格
- ✅ 构建完整的可观测性体系
- ✅ 编写高质量的 IaC 代码
- ✅ 实施云原生安全最佳实践
- ✅ 优化系统成本与性能

## 🎉 后续进阶方向

### 专家级主题
1. **eBPF 与可观测性**: Cilium、Pixie
2. **WebAssembly**: WASM 微服务、边缘计算
3. **多集群管理**: Cluster API、Karmada
4. **AI/ML on Kubernetes**: Kubeflow、KServe
5. **边缘计算**: K3s、OpenYurt
6. **Serverless**: Knative、OpenFaaS

### 认证考试
- **CKA** (Certified Kubernetes Administrator)
- **CKAD** (Certified Kubernetes Application Developer)
- **CKS** (Certified Kubernetes Security Specialist)

---

**预计完成时间**: 8 周（56 天）  
**每周投入**: 35-40 小时  
**总学时**: 约 300 小时

祝您学习愉快！💪