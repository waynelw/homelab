# 🏠 Homelab 云原生环境架构总结

## 🎯 整体架构概览

您的homelab环境是一个基于**Kind + Flux + Tekton**的完整云原生CI/CD平台，包含监控、日志、镜像仓库等完整的DevOps工具链。

## 🏗️ 系统架构图

### 主架构图
```mermaid
graph TB
    subgraph "外部环境"
        DEV[开发者] 
        GIT[Git Repository<br/>github.com/waynelw/homelab]
    end

    subgraph "Kind Kubernetes 集群"
        subgraph "flux-system namespace"
            FLUX[Flux CD<br/>GitOps 控制器]
            FLUXSRC[Source Controller]
            FLUXKUST[Kustomize Controller]
            FLUXHELM[Helm Controller]
        end

        subgraph "tekton-pipelines namespace"
            TEKTON[Tekton Pipelines<br/>CI 流水线]
            TEKDASH[Tekton Dashboard<br/>9097端口]
            TEKCTRL[Tekton Controller]
            TEKWEB[Tekton Webhook]
        end

        subgraph "registry namespace"
            REG[Docker Registry<br/>私有镜像仓库<br/>5000端口]
        end

        subgraph "monitoring namespace"
            PROM[Prometheus Server<br/>指标收集]
            ALERT[AlertManager<br/>告警管理]
            GRAF[Grafana<br/>可视化面板<br/>3000端口]
            NODE[Node Exporter<br/>节点监控]
            KUBE[Kube State Metrics<br/>集群状态]
        end

        subgraph "demo-app namespace"
            APP1[Demo App Pod 1]
            APP2[Demo App Pod 2]
            APPSVC[Demo App Service]
        end

        subgraph "ingress-nginx namespace"
            NGINX[Nginx Ingress Controller<br/>80/443端口]
        end

        subgraph "kube-system namespace"
            API[Kube API Server]
            ETCD[etcd]
            SCHED[Kube Scheduler]
            CTRL[Kube Controller]
            DNS[CoreDNS]
            PROXY[Kube Proxy]
        end
    end

    %% 工作流程
    DEV -->|git push| GIT
    GIT -->|webhook/polling| FLUX
    FLUX -->|GitOps 同步| FLUXSRC
    FLUXSRC --> FLUXKUST
    FLUXSRC --> FLUXHELM
    FLUXKUST -->|部署应用| APP1
    FLUXKUST -->|部署应用| APP2
    FLUXHELM -->|部署基础设施| TEKTON
    FLUXHELM -->|部署监控| PROM
    FLUXHELM -->|部署监控| GRAF

    %% CI/CD 流程
    GIT -->|触发构建| TEKTON
    TEKTON -->|构建镜像| REG
    REG -->|拉取镜像| APP1
    REG -->|拉取镜像| APP2

    %% 监控数据流
    APP1 -->|指标| PROM
    APP2 -->|指标| PROM
    NODE -->|节点指标| PROM
    KUBE -->|集群指标| PROM
    PROM -->|数据源| GRAF
    PROM -->|告警规则| ALERT

    %% 网络访问
    NGINX -->|路由| APPSVC
    APPSVC --> APP1
    APPSVC --> APP2

    %% 样式
    classDef fluxStyle fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    classDef tektonStyle fill:#fd495a,stroke:#fff,stroke-width:2px,color:#fff
    classDef monitorStyle fill:#e6522c,stroke:#fff,stroke-width:2px,color:#fff
    classDef appStyle fill:#00d4aa,stroke:#fff,stroke-width:2px,color:#fff
    classDef infraStyle fill:#ff6b35,stroke:#fff,stroke-width:2px,color:#fff

    class FLUX,FLUXSRC,FLUXKUST,FLUXHELM fluxStyle
    class TEKTON,TEKDASH,TEKCTRL,TEKWEB tektonStyle
    class PROM,ALERT,GRAF,NODE,KUBE monitorStyle
    class APP1,APP2,APPSVC appStyle
    class REG,NGINX infraStyle
```

## 📊 当前运行状态分析

根据 `kubectl get pods -A` 输出，环境运行状态如下：

### ✅ 正常运行的组件
- **Flux System**: 6个组件全部正常运行
- **Tekton Pipelines**: 4个组件全部正常运行  
- **Demo Application**: 2个副本正常运行
- **Monitoring**: Prometheus、AlertManager等大部分组件正常
- **Infrastructure**: Ingress、Registry、DNS等核心组件正常

### ⚠️ 需要关注的问题
- **Grafana**: 状态为 `Unknown`，可能需要重启或检查配置

## 🏗️ 架构特点

### 1. **GitOps 驱动**
- 使用 Flux CD 实现声明式部署
- Git 仓库作为唯一真实来源
- 自动同步和部署

### 2. **云原生 CI/CD**
- Tekton 提供容器化构建流水线
- 私有 Docker Registry 存储镜像
- 完整的构建-测试-部署流程

### 3. **完整监控体系**
- Prometheus 收集指标
- Grafana 可视化展示
- AlertManager 告警管理
- Node Exporter 节点监控

### 4. **命名空间隔离**
- 按功能划分命名空间
- 清晰的权限边界
- 便于管理和维护

## 🔄 CI/CD 工作流程

```mermaid
sequenceDiagram
    participant Dev as 开发者
    participant Git as Git Repository
    participant Flux as Flux CD
    participant Tekton as Tekton CI
    participant Registry as Docker Registry
    participant K8s as Kubernetes

    Dev->>Git: 1. git push 代码变更
    Git->>Flux: 2. 检测到变更
    Flux->>Tekton: 3. 触发 Pipeline
    
    Note over Tekton: CI 流水线执行
    Tekton->>Tekton: 4a. 拉取源码
    Tekton->>Tekton: 4b. 构建镜像
    Tekton->>Registry: 4c. 推送镜像
    
    Flux->>K8s: 5. 同步 Kubernetes 配置
    K8s->>Registry: 6. 拉取最新镜像
    K8s->>K8s: 7. 滚动更新应用
    
    Note over K8s: 应用成功部署
```

## 📁 项目结构

```mermaid
graph TD
    ROOT[homelab/]
    
    ROOT --> CLUSTERS[clusters/]
    ROOT --> SCRIPTS[scripts/]
    ROOT --> CONFIG[kind-config.yaml]
    ROOT --> README[README-CICD.md]
    
    CLUSTERS --> KIND[kind-homelab/]
    
    KIND --> FLUX[flux-system/]
    KIND --> INFRA[infrastructure/]
    KIND --> APPS[apps/]
    KIND --> KUST[kustomization.yaml]
    
    FLUX --> SYNC[gotk-sync.yaml]
    FLUX --> FLUXKUST[kustomization.yaml]
    
    INFRA --> SOURCES[sources/]
    INFRA --> REGISTRY[registry/]
    INFRA --> TEKTON[tekton/]
    INFRA --> MONITOR[monitoring/]
    INFRA --> LOGGING[logging/]
    
    APPS --> DEMO[demo-app/]
    
    SOURCES --> GITREPO[git-repository.yaml]
    SOURCES --> HELM[helm-repositories.yaml]
    
    REGISTRY --> REGHELM[registry-helmrelease.yaml]
    TEKTON --> TEKPIPE[tekton-pipelines.yaml]
    TEKTON --> TEKDASH[tekton-dashboard.yaml]
    
    MONITOR --> PROM[prometheus-helmrelease.yaml]
    MONITOR --> GRAF[grafana-helmrelease.yaml]
    
    DEMO --> DEPLOY[deployment.yaml]
    DEMO --> PIPE[pipeline.yaml]
    
    SCRIPTS --> DEPLOY_SCRIPT[deploy-cicd.sh]
    SCRIPTS --> ACCESS[access-services.sh]
    
    classDef fluxStyle fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    classDef infraStyle fill:#ff6b35,stroke:#fff,stroke-width:2px,color:#fff
    classDef appStyle fill:#00d4aa,stroke:#fff,stroke-width:2px,color:#fff
    
    class FLUX,SYNC,FLUXKUST fluxStyle
    class INFRA,SOURCES,REGISTRY,TEKTON,MONITOR,LOGGING infraStyle
    class APPS,DEMO appStyle
```

## 🛠️ 核心组件详情

| 组件 | 命名空间 | 状态 | 功能描述 |
|------|----------|------|----------|
| **Flux CD** | flux-system | ✅ 正常 | GitOps 持续部署，自动同步 Git 仓库 |
| **Tekton Pipelines** | tekton-pipelines | ✅ 正常 | 云原生 CI 流水线，构建和测试 |
| **Docker Registry** | registry | ✅ 正常 | 私有镜像仓库，存储构建的镜像 |
| **Prometheus** | monitoring | ✅ 正常 | 指标收集和存储，7天数据保留 |
| **Grafana** | monitoring | ⚠️ Unknown | 监控可视化面板，需要检查 |
| **AlertManager** | monitoring | ✅ 正常 | 告警管理和通知 |
| **Nginx Ingress** | ingress-nginx | ✅ 正常 | 入口控制器，处理外部访问 |
| **Demo App** | demo-app | ✅ 正常 | 示例应用，2个副本运行 |

## 🔧 服务访问方式

### 本地端口转发访问
```bash
# Tekton Dashboard
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
# 访问: http://localhost:9097

# Grafana 监控面板
kubectl port-forward -n monitoring svc/grafana 3000:80
# 访问: http://localhost:3000 (admin/admin123)

# Docker Registry
kubectl port-forward -n registry svc/docker-registry 5000:5000
# 访问: http://localhost:5000
```

## 📈 资源使用情况

根据配置文件分析，当前资源配置：

| 组件 | CPU 请求 | 内存请求 | 存储需求 |
|------|----------|----------|----------|
| Prometheus Server | 200m | 256Mi | 8Gi |
| AlertManager | 50m | 64Mi | 2Gi |
| Grafana | ~100m | ~128Mi | 1Gi |
| Node Exporter | 50m | 64Mi | - |
| Kube State Metrics | 50m | 64Mi | - |
| **总计** | ~450m | ~576Mi | ~11Gi |

## 🎯 架构优势

1. **轻量级设计**: 基于 Kind 的本地 Kubernetes 环境
2. **GitOps 最佳实践**: 声明式配置，版本控制
3. **完整的 DevOps 工具链**: CI/CD + 监控 + 日志
4. **云原生技术栈**: 容器化、微服务、自动化
5. **易于扩展**: 模块化设计，便于添加新组件

## 🔍 建议的后续优化

1. **修复 Grafana**: 检查 Grafana Pod 状态，可能需要重启
2. **添加日志聚合**: 当前 Loki 组件可能未完全部署
3. **配置告警规则**: 完善 Prometheus 告警配置
4. **安全加固**: 添加 RBAC 权限控制和网络策略
5. **备份策略**: 配置 etcd 和持久化数据备份

---

**生成时间**: 2025-10-08  
**环境版本**: Kind v1.28.0 + Flux + Tekton  
**文档状态**: 基于当前运行状态分析
