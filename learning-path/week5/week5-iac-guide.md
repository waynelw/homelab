# Week 5: 基础设施即代码（IaC）

## 🎯 本周学习目标

1. **掌握 Terraform**：Provider、Resource、Module
2. **学习 Helm Chart**：依赖管理、Hook
3. **使用 Kustomize**：多环境配置
4. **ArgoCD ApplicationSet**：多集群部署
5. **GitOps 最佳实践**：分支策略、审批流程

## 📚 核心学习内容

### 1. Terraform 基础

```hcl
# main.tf
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "ecommerce" {
  metadata {
    name = "ecommerce-microservices"
  }
}

resource "kubernetes_deployment" "user_service" {
  metadata {
    name      = "user-service"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }
  
  spec {
    replicas = 3
    
    selector {
      match_labels = {
        app = "user-service"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "user-service"
        }
      }
      
      spec {
        container {
          name  = "user-service"
          image = "user-service:latest"
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
```

### 2. Helm Chart 开发

```yaml
# Chart.yaml
apiVersion: v2
name: user-service
description: User Service Helm Chart
version: 1.0.0

dependencies:
  - name: postgresql
    version: "12.1.0"
    repository: https://charts.bitnami.com/bitnami

# values.yaml
replicaCount: 3

image:
  repository: user-service
  tag: latest

service:
  type: ClusterIP
  port: 8081

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

# hooks.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-migration
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: migration
        image: user-service:migration
        command: ["/migrate", "up"]
      restartPolicy: Never
```

### 3. Kustomize 多环境

```
base/
  kustomization.yaml
  deployment.yaml
  service.yaml

overlays/
  dev/
    kustomization.yaml
    replica-patch.yaml
  staging/
    kustomization.yaml
  prod/
    kustomization.yaml
```

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

# overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: dev

bases:
  - ../../base

replicas:
  - name: user-service
    count: 1

images:
  - name: user-service
    newTag: dev-latest
```

### 4. ArgoCD ApplicationSet

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: ecommerce-microservices
spec:
  generators:
  - list:
      elements:
      - cluster: dev
        path: overlays/dev
      - cluster: staging
        path: overlays/staging
      - cluster: prod
        path: overlays/prod
  
  template:
    metadata:
      name: '{{cluster}}-ecommerce'
    spec:
      project: default
      source:
        repoURL: https://github.com/example/repo
        targetRevision: main
        path: '{{path}}'
      destination:
        server: '{{cluster}}'
        namespace: ecommerce-microservices
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

**预计完成时间**: 3-4 天  
**每周投入**: 20-25 小时
