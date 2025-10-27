# Week 7: 云原生安全最佳实践

## 🎯 本周学习目标

1. **Pod Security Standards**：Restricted、Baseline
2. **Network Policy**：网络隔离
3. **Secrets 管理**：Sealed Secrets / External Secrets
4. **OPA/Gatekeeper**：策略即代码
5. **RBAC 最佳实践**：权限控制与审计
6. **镜像签名**：Sigstore

## 📚 核心学习内容

### 1. Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-microservices
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 2. Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-service-network-policy
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: order-service
    ports:
    - protocol: TCP
      port: 8081
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: product-service
    ports:
    - protocol: TCP
      port: 8082
```

### 3. External Secrets

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: user-service-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: user-service-secrets
    creationPolicy: Owner
  data:
  - secretKey: database-password
    remoteRef:
      key: database/users
      property: password
```

### 4. OPA Gatekeeper 策略

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredresources
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredResources
      validation:
        type: object
        properties:
          cpu:
            type: string
          memory:
            type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredresources
        violations[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.requests.cpu
          msg := "Container is missing CPU request"
        }
```

### 5. RBAC 审计

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets"]
  omitStages:
  - RequestReceived
```

---

**预计完成时间**: 3-4 天  
**每周投入**: 20-25 小时
