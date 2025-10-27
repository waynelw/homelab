# Week 6: CI/CD 流水线深化

## 🎯 本周学习目标

1. **容器镜像安全**：Trivy 扫描、镜像签名
2. **多阶段构建**：优化镜像体积
3. **缓存策略**：BuildKit、Layer Caching
4. **集成测试**：单元测试 + 集成测试 + E2E
5. **部署策略**：蓝绿、金丝雀、滚动

## 📚 核心学习内容

### 1. 容器镜像安全

#### Trivy 扫描
```bash
# 扫描镜像
trivy image user-service:latest

# 生成报告
trivy image --format template --template "@contrib/gitlab.tpl" \
  -o gl-container-scanning-report.json user-service:latest
```

#### 镜像签名（Sigstore）
```bash
# 使用 Cosign 签名
cosign sign --key cosign.key user-service:latest

# 验证签名
cosign verify --key cosign.pub user-service:latest
```

### 2. 多阶段构建优化

```dockerfile
# Stage 1: 构建
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main

# Stage 2: 最小镜像
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
```

### 3. Tekton Pipeline 示例

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: ci-cd-pipeline
spec:
  params:
    - name: image-name
    - name: image-tag
  
  tasks:
    - name: source-code-checkout
      taskRef:
        name: git-clone
      
    - name: run-tests
      runAfter:
        - source-code-checkout
      taskSpec:
        steps:
          - name: unit-tests
            image: golang:1.21
            script: |
              cd $(workspaces.source.path)
              go test ./... -v -coverprofile=coverage.out
      
    - name: security-scan
      runAfter:
        - run-tests
      taskRef:
        name: trivy-scanner
      
    - name: build-image
      runAfter:
        - security-scan
      taskRef:
        name: kaniko-build
      
    - name: push-image
      runAfter:
        - build-image
      taskRef:
        name: kaniko-push
```

### 4. 部署策略配置

#### 金丝雀发布
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: user-service
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/target: "10"
    spec:
      containers:
      - image: user-service:v2
  traffic:
  - percent: 90
    revisionName: user-service-v1
  - percent: 10
    revisionName: user-service-v2
```

---

**预计完成时间**: 4-5 天  
**每周投入**: 25-30 小时
