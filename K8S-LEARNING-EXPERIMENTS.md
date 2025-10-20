# 🧪 Kubernetes 学习实验设计

基于你的 **Kind + Flux + Tekton** 环境，设计以下循序渐进的实验来学习 Kubernetes 核心原理。

## 📚 实验体系概览

```
实验体系
├── 基础篇: Pod 和容器生命周期
├── 控制器篇: Deployment/StatefulSet/DaemonSet
├── 网络篇: Service/Ingress/NetworkPolicy
├── 存储篇: Volume/PV/PVC/StorageClass
├── 配置篇: ConfigMap/Secret
├── 安全篇: RBAC/ServiceAccount/SecurityContext
├── 调度篇: Scheduler/Affinity/Taints/Tolerations
├── 监控篇: Metrics/Logging/Tracing
└── GitOps篇: Flux/Tekton 深入实践
```

---

# 📖 实验一：Pod 生命周期深度探索

## 🎯 学习目标
- 理解 Pod 的创建、运行、销毁全生命周期
- 掌握容器重启策略和健康检查机制
- 观察 Init Container 和 Sidecar 模式

## 🔬 实验步骤

### 1.1 创建基础 Pod 并观察生命周期

```yaml
# experiments/01-pod-lifecycle/basic-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-demo
  namespace: experiments
  labels:
    app: lifecycle-demo
spec:
  containers:
  - name: main
    image: nginx:alpine
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh", "-c", "echo 'PostStart: Pod started at $(date)' > /usr/share/nginx/html/lifecycle.log"]
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 10 && echo 'PreStop: Pod stopping at $(date)' >> /usr/share/nginx/html/lifecycle.log"]
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 2
      periodSeconds: 3
```

**观察命令**:
```bash
# 创建命名空间
kubectl create namespace experiments

# 应用配置
kubectl apply -f experiments/01-pod-lifecycle/basic-pod.yaml

# 实时查看Pod事件
kubectl get events -n experiments --watch

# 查看Pod详细信息
kubectl describe pod lifecycle-demo -n experiments

# 查看容器日志
kubectl logs lifecycle-demo -n experiments

# 删除Pod观察preStop钩子
kubectl delete pod lifecycle-demo -n experiments
```

**预期学习**:
- Pod 的 Pending → Running → Terminating 状态转换
- postStart 和 preStop 钩子的执行时机
- 健康检查如何影响 Pod 状态

---

### 1.2 探索重启策略

```yaml
# experiments/01-pod-lifecycle/restart-policy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: restart-demo
  namespace: experiments
spec:
  restartPolicy: OnFailure  # 修改为 Always, Never 对比
  containers:
  - name: crash-loop
    image: busybox
    command: ["sh", "-c", "echo 'Starting...'; sleep 10; exit 1"]
```

**实验任务**:
```bash
# 应用Pod
kubectl apply -f experiments/01-pod-lifecycle/restart-policy.yaml

# 观察重启次数
kubectl get pod restart-demo -n experiments -w

# 查看重启历史
kubectl describe pod restart-demo -n experiments | grep -A 10 "State:"

# 修改 restartPolicy 为 Never，观察差异
# 修改 exit 1 为 exit 0，观察成功退出的行为
```

**关键问题**:
- 为什么 CrashLoopBackOff 的重启间隔会越来越长？
- restartPolicy 如何影响 Pod 的行为？

---

### 1.3 Init Container 实验

```yaml
# experiments/01-pod-lifecycle/init-container.yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
  namespace: experiments
spec:
  initContainers:
  - name: init-1
    image: busybox
    command: ['sh', '-c', 'echo "Init 1: Checking database..." && sleep 5']
  - name: init-2
    image: busybox
    command: ['sh', '-c', 'echo "Init 2: Loading config..." && sleep 3']
  containers:
  - name: app
    image: nginx:alpine
    ports:
    - containerPort: 80
```

**观察命令**:
```bash
kubectl apply -f experiments/01-pod-lifecycle/init-container.yaml

# 观察Init容器按顺序执行
kubectl get pod init-demo -n experiments -w

# 查看Init容器日志
kubectl logs init-demo -n experiments -c init-1
kubectl logs init-demo -n experiments -c init-2
```

**学习重点**:
- Init Container 的串行执行机制
- Init Container 失败对 Pod 启动的影响

---

# 📖 实验二：控制器机制深入

## 🎯 学习目标
- 理解 Deployment 的滚动更新和回滚机制
- 掌握 StatefulSet 的有序部署和持久化
- 了解 DaemonSet 的节点级部署

## 🔬 实验步骤

### 2.1 Deployment 滚动更新实验

```yaml
# experiments/02-controllers/rolling-update.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-demo
  namespace: experiments
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
  selector:
    matchLabels:
      app: rolling-demo
  template:
    metadata:
      labels:
        app: rolling-demo
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 2
```

**实验任务**:
```bash
# 部署应用
kubectl apply -f experiments/02-controllers/rolling-update.yaml

# 观察初始状态
kubectl get deployment rolling-demo -n experiments
kubectl get rs -n experiments -l app=rolling-demo

# 触发滚动更新
kubectl set image deployment/rolling-demo app=nginx:1.22-alpine -n experiments

# 实时观察更新过程
kubectl rollout status deployment/rolling-demo -n experiments
kubectl get pods -n experiments -l app=rolling-demo -w

# 查看ReplicaSet变化
kubectl get rs -n experiments -l app=rolling-demo

# 查看滚动历史
kubectl rollout history deployment/rolling-demo -n experiments

# 回滚到上一版本
kubectl rollout undo deployment/rolling-demo -n experiments

# 回滚到特定版本
kubectl rollout undo deployment/rolling-demo --to-revision=1 -n experiments
```

**深入探索**:
```bash
# 修改 maxUnavailable 和 maxSurge 观察差异
kubectl patch deployment rolling-demo -n experiments -p '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":0,"maxSurge":1}}}}'

# 暂停和恢复滚动更新
kubectl rollout pause deployment/rolling-demo -n experiments
kubectl rollout resume deployment/rolling-demo -n experiments
```

**关键问题**:
- maxUnavailable 和 maxSurge 如何影响更新速度？
- ReplicaSet 在滚动更新中的作用是什么？
- 为什么需要 readinessProbe？

---

### 2.2 StatefulSet 有序部署实验

```yaml
# experiments/02-controllers/statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: stateful-svc
  namespace: experiments
spec:
  clusterIP: None  # Headless Service
  selector:
    app: stateful-demo
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-demo
  namespace: experiments
spec:
  serviceName: stateful-svc
  replicas: 3
  selector:
    matchLabels:
      app: stateful-demo
  template:
    metadata:
      labels:
        app: stateful-demo
    spec:
      containers:
      - name: app
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /data
        command: ["/bin/sh"]
        args:
        - -c
        - |
          echo "Pod: $HOSTNAME" > /data/hostname.txt
          echo "Started at: $(date)" >> /data/hostname.txt
          nginx -g 'daemon off;'
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

**观察命令**:
```bash
# 部署StatefulSet
kubectl apply -f experiments/02-controllers/statefulset.yaml

# 观察有序创建
kubectl get pods -n experiments -l app=stateful-demo -w

# 查看Pod名称和持久化存储
kubectl get pods -n experiments -l app=stateful-demo
kubectl get pvc -n experiments

# 进入Pod验证持久化
kubectl exec stateful-demo-0 -n experiments -- cat /data/hostname.txt

# 删除Pod观察重建
kubectl delete pod stateful-demo-1 -n experiments
kubectl get pods -n experiments -l app=stateful-demo -w

# 测试Headless Service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n experiments -- nslookup stateful-svc.experiments.svc.cluster.local
kubectl run -it --rm debug --image=busybox --restart=Never -n experiments -- nslookup stateful-demo-0.stateful-svc.experiments.svc.cluster.local
```

**关键问题**:
- StatefulSet 的 Pod 名称有什么规律？
- 删除的 Pod 重建后 PVC 是否还在？
- Headless Service 的 DNS 解析有何特点？

---

### 2.3 DaemonSet 节点级部署

```yaml
# experiments/02-controllers/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: daemon-demo
  namespace: experiments
spec:
  selector:
    matchLabels:
      app: daemon-demo
  template:
    metadata:
      labels:
        app: daemon-demo
    spec:
      containers:
      - name: logger
        image: busybox
        command: ["sh", "-c", "while true; do echo \"Node: $NODE_NAME - $(date)\"; sleep 30; done"]
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

**观察命令**:
```bash
kubectl apply -f experiments/02-controllers/daemonset.yaml

# 查看每个节点上的Pod
kubectl get pods -n experiments -l app=daemon-demo -o wide

# 查看节点标签
kubectl get nodes --show-labels

# 添加节点选择器测试（如果有多节点）
kubectl patch daemonset daemon-demo -n experiments -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"}}}}}'
```

---

# 📖 实验三：网络原理探索

## 🎯 学习目标
- 理解 Service 的四种类型和负载均衡机制
- 掌握 Ingress 的路由规则
- 实践 NetworkPolicy 网络隔离

## 🔬 实验步骤

### 3.1 Service 类型对比实验

```yaml
# experiments/03-networking/service-types.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: experiments
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo
        args:
        - "-text=Pod: $(POD_NAME) on Node: $(NODE_NAME)"
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        ports:
        - containerPort: 5678
---
# ClusterIP Service
apiVersion: v1
kind: Service
metadata:
  name: web-clusterip
  namespace: experiments
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 5678
---
# NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
  namespace: experiments
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 5678
    nodePort: 30080
```

**实验任务**:
```bash
kubectl apply -f experiments/03-networking/service-types.yaml

# 查看Service和Endpoints
kubectl get svc -n experiments
kubectl get endpoints -n experiments

# 测试ClusterIP访问
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -n experiments -- curl http://web-clusterip

# 多次请求观察负载均衡
for i in {1..10}; do
  kubectl run curl-$i --image=curlimages/curl --restart=Never -n experiments --rm -- curl -s http://web-clusterip
done

# 测试NodePort（从主机访问）
curl http://localhost:30080

# 查看iptables规则（Service实现原理）
docker exec kind-homelab-control-plane iptables-save | grep web-clusterip
```

**关键问题**:
- Service 如何发现后端 Pod？
- 负载均衡是如何实现的（kube-proxy 模式）？
- ClusterIP 和 NodePort 的网络路径有何不同？

---

### 3.2 Headless Service 和 DNS 实验

```yaml
# experiments/03-networking/headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-headless
  namespace: experiments
spec:
  clusterIP: None  # Headless
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 5678
```

**DNS 探索**:
```bash
kubectl apply -f experiments/03-networking/headless-service.yaml

# 查看Service（没有ClusterIP）
kubectl get svc web-headless -n experiments

# DNS解析对比
kubectl run -it --rm debug --image=busybox --restart=Never -n experiments -- sh

# 在debug Pod中执行
nslookup web-clusterip.experiments.svc.cluster.local
nslookup web-headless.experiments.svc.cluster.local

# 观察Headless Service返回所有Pod IP
```

---

### 3.3 NetworkPolicy 网络隔离

```yaml
# experiments/03-networking/network-policy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: experiments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
      tier: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: app
        image: nginx:alpine
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: experiments
spec:
  selector:
    app: backend
  ports:
  - port: 80
---
# 只允许来自frontend的流量
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: experiments
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
```

**测试网络隔离**:
```bash
kubectl apply -f experiments/03-networking/network-policy.yaml

# 从非frontend Pod访问（应该被拒绝）
kubectl run test-access --image=busybox --restart=Never -n experiments -- wget -T 5 -O- http://backend-svc

# 创建frontend Pod测试
kubectl run frontend --image=busybox --restart=Never -n experiments --labels="tier=frontend" -- wget -T 5 -O- http://backend-svc

# 观察结果差异
kubectl logs test-access -n experiments
kubectl logs frontend -n experiments
```

---

# 📖 实验四：存储与持久化

## 🎯 学习目标
- 理解 Volume、PV、PVC 的关系
- 掌握 StorageClass 动态供应
- 实践数据持久化和迁移

## 🔬 实验步骤

### 4.1 Volume 类型对比

```yaml
# experiments/04-storage/volume-types.yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-demo
  namespace: experiments
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c", "while true; do date >> /data/emptyDir/log.txt; date >> /data/hostPath/log.txt; sleep 5; done"]
    volumeMounts:
    - name: empty-vol
      mountPath: /data/emptyDir
    - name: host-vol
      mountPath: /data/hostPath
  - name: reader
    image: busybox
    command: ["sh", "-c", "tail -f /data/emptyDir/log.txt"]
    volumeMounts:
    - name: empty-vol
      mountPath: /data/emptyDir
  volumes:
  - name: empty-vol
    emptyDir: {}
  - name: host-vol
    hostPath:
      path: /tmp/k8s-data
      type: DirectoryOrCreate
```

**实验任务**:
```bash
kubectl apply -f experiments/04-storage/volume-types.yaml

# 查看日志
kubectl logs volume-demo -n experiments -c reader

# 删除Pod后查看数据
kubectl delete pod volume-demo -n experiments

# 重新创建，观察emptyDir数据丢失，hostPath数据保留
kubectl apply -f experiments/04-storage/volume-types.yaml
docker exec kind-homelab-control-plane cat /tmp/k8s-data/log.txt
```

**关键问题**:
- emptyDir 和 hostPath 的生命周期有何不同？
- 多容器如何共享 Volume？

---

### 4.2 PV 和 PVC 实验

```yaml
# experiments/04-storage/pv-pvc.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-demo
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /tmp/pv-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-demo
  namespace: experiments
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: manual
---
apiVersion: v1
kind: Pod
metadata:
  name: pvc-user
  namespace: experiments
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-demo
```

**观察绑定过程**:
```bash
kubectl apply -f experiments/04-storage/pv-pvc.yaml

# 查看PV和PVC状态
kubectl get pv
kubectl get pvc -n experiments

# 写入数据
kubectl exec pvc-user -n experiments -- sh -c "echo 'Persistent Data' > /usr/share/nginx/html/index.html"

# 删除Pod，重新创建，验证数据持久性
kubectl delete pod pvc-user -n experiments
kubectl apply -f experiments/04-storage/pv-pvc.yaml
kubectl exec pvc-user -n experiments -- cat /usr/share/nginx/html/index.html

# 查看PV回收策略
kubectl describe pv pv-demo
```

---

### 4.3 StorageClass 动态供应

```yaml
# experiments/04-storage/storageclass.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
  namespace: experiments
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard  # Kind默认的StorageClass
---
apiVersion: v1
kind: Pod
metadata:
  name: dynamic-user
  namespace: experiments
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'Dynamic Storage' > /data/test.txt && sleep 3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: dynamic-pvc
```

**观察动态供应**:
```bash
kubectl apply -f experiments/04-storage/storageclass.yaml

# 查看自动创建的PV
kubectl get pv
kubectl get pvc dynamic-pvc -n experiments

# 查看StorageClass
kubectl get storageclass
kubectl describe storageclass standard
```

---

# 📖 实验五：配置管理

## 🎯 学习目标
- 掌握 ConfigMap 和 Secret 的使用
- 理解配置热更新机制
- 实践敏感信息保护

## 🔬 实验步骤

### 5.1 ConfigMap 多种挂载方式

```yaml
# experiments/05-config/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: experiments
data:
  app.properties: |
    server.port=8080
    server.name=demo
    debug.enabled=true
  log.level: "INFO"
  feature.flags: "feature1,feature2,feature3"
---
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
  namespace: experiments
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do echo 'LOG_LEVEL: '$LOG_LEVEL; cat /config/app.properties; sleep 30; done"]
    env:
    # 方式1: 环境变量
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
    # 方式2: 全部导入为环境变量
    envFrom:
    - configMapRef:
        name: app-config
        prefix: CONFIG_
    volumeMounts:
    # 方式3: 文件挂载
    - name: config-volume
      mountPath: /config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

**实验任务**:
```bash
kubectl apply -f experiments/05-config/configmap.yaml

# 查看配置使用
kubectl logs config-demo -n experiments

# 进入容器验证
kubectl exec config-demo -n experiments -- env | grep CONFIG
kubectl exec config-demo -n experiments -- ls /config
kubectl exec config-demo -n experiments -- cat /config/app.properties

# 修改ConfigMap观察变化
kubectl edit configmap app-config -n experiments
# 修改 log.level 为 DEBUG

# 环境变量不会更新，文件会更新（需要等待约1分钟）
kubectl exec config-demo -n experiments -- cat /config/app.properties
```

**关键问题**:
- ConfigMap 更新后，哪些方式会自动更新？
- 如何实现应用的配置热更新？

---

### 5.2 Secret 敏感信息管理

```yaml
# experiments/05-config/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: experiments
type: Opaque
stringData:
  username: admin
  password: super-secret-password
  database-url: "postgresql://db.example.com:5432/mydb"
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-demo
  namespace: experiments
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'DB_USER: '$DB_USER; echo 'DB_PASS: [HIDDEN]'; cat /secrets/database-url; sleep 3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    volumeMounts:
    - name: secret-volume
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
      items:
      - key: database-url
        path: database-url
```

**实验任务**:
```bash
kubectl apply -f experiments/05-config/secret.yaml

# 查看Secret（已编码）
kubectl get secret db-secret -n experiments -o yaml

# 解码Secret
kubectl get secret db-secret -n experiments -o jsonpath='{.data.password}' | base64 -d

# 验证Pod使用
kubectl logs secret-demo -n experiments
kubectl exec secret-demo -n experiments -- cat /secrets/database-url
```

---

# 📖 实验六：RBAC 和安全

## 🎯 学习目标
- 理解 K8s 的认证和授权机制
- 掌握 RBAC 的配置
- 实践最小权限原则

## 🔬 实验步骤

### 6.1 ServiceAccount 和 RBAC 实验

```yaml
# experiments/06-security/rbac-demo.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: experiments
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: experiments
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: experiments
subjects:
- kind: ServiceAccount
  name: pod-reader
  namespace: experiments
roleRef:
  kind: Role
  name: pod-reader-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test
  namespace: experiments
spec:
  serviceAccountName: pod-reader
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "3600"]
```

**权限测试**:
```bash
kubectl apply -f experiments/06-security/rbac-demo.yaml

# 进入Pod测试权限
kubectl exec -it rbac-test -n experiments -- bash

# 在Pod内执行：
# 可以执行（有权限）
kubectl get pods -n experiments

# 无法执行（无权限）
kubectl get deployments -n experiments
kubectl delete pod lifecycle-demo -n experiments
kubectl get pods -n default

# 退出Pod
exit

# 查看ServiceAccount token
kubectl exec rbac-test -n experiments -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

**权限扩展实验**:
```bash
# 添加删除权限
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-manager-role
  namespace: experiments
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-manager-binding
  namespace: experiments
subjects:
- kind: ServiceAccount
  name: pod-reader
  namespace: experiments
roleRef:
  kind: Role
  name: pod-manager-role
  apiGroup: rbac.authorization.k8s.io
EOF

# 重新测试删除权限
kubectl exec -it rbac-test -n experiments -- kubectl delete pod config-demo -n experiments
```

**关键问题**:
- ServiceAccount、Role、RoleBinding 的关系？
- Role 和 ClusterRole 的区别？
- 如何调试权限问题？

---

### 6.2 SecurityContext 实验

```yaml
# experiments/06-security/security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-demo
  namespace: experiments
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "id; ls -l /data; echo 'test' > /data/test.txt; ls -l /data; sleep 3600"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: false
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
```

**安全实验**:
```bash
kubectl apply -f experiments/06-security/security-context.yaml

# 查看运行用户和权限
kubectl logs security-demo -n experiments

# 尝试提权操作（应该失败）
kubectl exec security-demo -n experiments -- sh -c "id && whoami"
```

---

# 📖 实验七：调度机制探索

## 🎯 学习目标
- 理解 Kubernetes 调度器工作原理
- 掌握节点亲和性和 Pod 亲和性
- 实践 Taints 和 Tolerations

## 🔬 实验步骤

### 7.1 资源请求和限制

```yaml
# experiments/07-scheduling/resources.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
  namespace: experiments
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**观察调度**:
```bash
kubectl apply -f experiments/07-scheduling/resources.yaml

# 查看Pod资源使用
kubectl top pod resource-demo -n experiments

# 查看节点可用资源
kubectl top nodes

# 创建资源过大的Pod观察调度失败
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: huge-resource
  namespace: experiments
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "1000Gi"
        cpu: "1000"
EOF

# 查看调度失败事件
kubectl describe pod huge-resource -n experiments
```

---

### 7.2 节点亲和性实验

```yaml
# experiments/07-scheduling/node-affinity.yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-demo
  namespace: experiments
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: node-role.kubernetes.io/control-plane
            operator: Exists
  containers:
  - name: app
    image: nginx:alpine
```

**调度测试**:
```bash
# 查看节点标签
kubectl get nodes --show-labels

# 应用Pod
kubectl apply -f experiments/07-scheduling/node-affinity.yaml

# 查看Pod调度到哪个节点
kubectl get pod affinity-demo -n experiments -o wide

# 为节点添加自定义标签
kubectl label nodes kind-homelab-control-plane env=production

# 修改nodeAffinity使用自定义标签
```

---

### 7.3 Pod 亲和性和反亲和性

```yaml
# experiments/07-scheduling/pod-affinity.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-tier
  namespace: experiments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
      - name: web
        image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache-tier
  namespace: experiments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
        tier: backend
    spec:
      affinity:
        # 倾向于和web-tier在同一节点
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: tier
                  operator: In
                  values:
                  - frontend
              topologyKey: kubernetes.io/hostname
        # 避免多个cache Pod在同一节点
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - cache
              topologyKey: kubernetes.io/hostname
      containers:
      - name: cache
        image: redis:alpine
```

**观察调度策略**:
```bash
kubectl apply -f experiments/07-scheduling/pod-affinity.yaml

# 查看Pod分布
kubectl get pods -n experiments -o wide -l app=web
kubectl get pods -n experiments -o wide -l app=cache

# 分析调度结果
```

---

# 📖 实验八：监控和可观测性

## 🎯 学习目标
- 利用 Prometheus 收集指标
- 使用 Grafana 可视化
- 实践日志聚合和追踪

## 🔬 实验步骤

### 8.1 应用指标暴露

```yaml
# experiments/08-monitoring/metrics-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-demo
  namespace: experiments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: metrics-demo
  template:
    metadata:
      labels:
        app: metrics-demo
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 8080
          name: metrics
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-demo
  namespace: experiments
  labels:
    app: metrics-demo
spec:
  selector:
    app: metrics-demo
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: metrics
    port: 8080
    targetPort: 8080
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: metrics-demo
  namespace: experiments
spec:
  selector:
    matchLabels:
      app: metrics-demo
  endpoints:
  - port: metrics
    interval: 30s
```

**监控实验**:
```bash
kubectl apply -f experiments/08-monitoring/metrics-app.yaml

# 端口转发访问Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &

# 在浏览器访问 http://localhost:9090
# 查询: up{job="experiments/metrics-demo"}

# 端口转发访问Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80 &

# 访问 http://localhost:3000 (admin/admin123)
# 创建Dashboard展示应用指标
```

---

### 8.2 自定义指标实验

创建一个带有自定义指标的应用：

```yaml
# experiments/08-monitoring/custom-metrics-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-app-script
  namespace: experiments
data:
  app.sh: |
    #!/bin/sh
    # 简单的Prometheus格式指标服务器
    while true; do
      echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n# HELP custom_requests_total Total requests\n# TYPE custom_requests_total counter\ncustom_requests_total $RANDOM\n# HELP custom_active_users Active users\n# TYPE custom_active_users gauge\ncustom_active_users $((RANDOM % 100))\n" | nc -l -p 8080
    done
---
apiVersion: v1
kind: Pod
metadata:
  name: custom-metrics
  namespace: experiments
  labels:
    app: custom-metrics
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "/scripts/app.sh"]
    ports:
    - containerPort: 8080
      name: metrics
    volumeMounts:
    - name: script
      mountPath: /scripts
  volumes:
  - name: config configMap:
      name: custom-app-script
      defaultMode: 0755
```

**查询自定义指标**:
```bash
kubectl apply -f experiments/08-monitoring/custom-metrics-app.yaml

# 本地测试指标端点
kubectl port-forward custom-metrics 8080:8080 -n experiments &
curl http://localhost:8080

# 在Prometheus中查询
# custom_requests_total
# custom_active_users
```

---

### 8.3 日志聚合实验

```yaml
# experiments/08-monitoring/logging-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logging-demo
  namespace: experiments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: logging-demo
  template:
    metadata:
      labels:
        app: logging-demo
    spec:
      containers:
      - name: app
        image: busybox
        command:
        - sh
        - -c
        - |
          while true; do
            echo "{\"timestamp\":\"$(date -Iseconds)\", \"level\":\"INFO\", \"message\":\"Request processed\", \"user\":\"user-$RANDOM\", \"duration_ms\":$((RANDOM % 1000))}"
            sleep 2
            if [ $((RANDOM % 10)) -eq 0 ]; then
              echo "{\"timestamp\":\"$(date -Iseconds)\", \"level\":\"ERROR\", \"message\":\"Failed to process request\", \"error\":\"Connection timeout\"}"
            fi
          done
```

**日志实验**:
```bash
kubectl apply -f experiments/08-monitoring/logging-app.yaml

# 查看日志
kubectl logs -f -n experiments -l app=logging-demo

# 多Pod日志聚合
kubectl logs -n experiments -l app=logging-demo --tail=20 --prefix

# 使用stern工具（如果安装）
# stern -n experiments logging-demo

# 在Grafana中查看Loki日志
# 查询: {namespace="experiments", app="logging-demo"}
# 过滤错误: {namespace="experiments", app="logging-demo"} |= "ERROR"
```

---

# 📖 实验九：GitOps 深入实践

## 🎯 学习目标
- 理解 Flux 的 GitOps 工作流
- 掌握 Kustomization 和 HelmRelease
- 实践声明式配置管理

## 🔬 实验步骤

### 9.1 Flux GitRepository 实验

```yaml
# experiments/09-gitops/git-source.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: experiment-repo
  namespace: experiments
spec:
  interval: 1m
  url: https://github.com/waynelw/homelab
  ref:
    branch: main
  ignore: |
    # exclude all
    /*
    # include experiments directory
    !/experiments/09-gitops/manifests
```

**观察 Flux 同步**:
```bash
# 创建namespace并应用
kubectl create namespace experiments --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f experiments/09-gitops/git-source.yaml

# 查看GitRepository状态
kubectl get gitrepository -n experiments
kubectl describe gitrepository experiment-repo -n experiments

# 查看Flux日志
flux logs --level=debug -n experiments
```

---

### 9.2 Kustomization 声明式部署

创建一个通过 Flux 管理的应用：

```yaml
# experiments/09-gitops/kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: experiment-app
  namespace: experiments
spec:
  interval: 5m
  path: ./experiments/09-gitops/manifests
  prune: true
  sourceRef:
    kind: GitRepository
    name: experiment-repo
  healthChecks:
  - apiVersion: apps/v1
    kind: Deployment
    name: gitops-demo
    namespace: experiments
```

对应的应用配置：
```yaml
# experiments/09-gitops/manifests/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitops-demo
  namespace: experiments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: gitops-demo
  template:
    metadata:
      labels:
        app: gitops-demo
    spec:
      containers:
      - name: app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: gitops-demo
  namespace: experiments
spec:
  selector:
    app: gitops-demo
  ports:
  - port: 80
```

**GitOps 工作流**:
```bash
# 应用Kustomization
kubectl apply -f experiments/09-gitops/kustomization.yaml

# 观察Flux自动部署
kubectl get kustomization -n experiments -w
flux get kustomizations -n experiments

# 修改Git仓库中的配置（例如修改replicas）
# 观察Flux自动同步
flux reconcile kustomization experiment-app -n experiments

# 查看部署状态
kubectl get deployment gitops-demo -n experiments
```

---

### 9.3 HelmRelease 管理

```yaml
# experiments/09-gitops/helm-release.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: bitnami
  namespace: experiments
spec:
  interval: 1h
  url: https://charts.bitnami.com/bitnami
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: redis
  namespace: experiments
spec:
  interval: 5m
  chart:
    spec:
      chart: redis
      version: "17.x"
      sourceRef:
        kind: HelmRepository
        name: bitnami
  values:
    architecture: standalone
    auth:
      enabled: false
    master:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 256Mi
```

**Helm 管理实验**:
```bash
kubectl apply -f experiments/09-gitops/helm-release.yaml

# 观察Helm安装过程
kubectl get helmrelease -n experiments -w
flux get helmreleases -n experiments

# 查看安装的资源
kubectl get pods -n experiments -l app.kubernetes.io/name=redis

# 修改values（例如增加resources）
kubectl edit helmrelease redis -n experiments

# 观察滚动更新
kubectl rollout status statefulset redis-master -n experiments
```

---

# 📖 实验十：Tekton CI/CD 深入

## 🎯 学习目标
- 理解 Tekton Task 和 Pipeline 设计
- 掌握 Workspace 和参数传递
- 实践完整的 CI/CD 流程

## 🔬 实验步骤

### 10.1 创建复杂的 Task

```yaml
# experiments/10-tekton/test-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: run-tests
  namespace: experiments
spec:
  params:
  - name: test-type
    type: string
    default: "unit"
  workspaces:
  - name: source
  results:
  - name: test-result
    description: Test execution result
  steps:
  - name: run-unit-tests
    image: python:3.9-slim
    workingDir: $(workspaces.source.path)
    script: |
      #!/usr/bin/env bash
      set -e
      echo "Running $(params.test-type) tests..."
      
      # 模拟测试
      if [ "$(params.test-type)" == "unit" ]; then
        echo "✓ test_user_login: passed"
        echo "✓ test_data_validation: passed"
        echo "✓ test_api_endpoints: passed"
        echo "PASS" | tee $(results.test-result.path)
      elif [ "$(params.test-type)" == "integration" ]; then
        echo "✓ test_database_connection: passed"
        echo "✓ test_api_integration: passed"
        echo "PASS" | tee $(results.test-result.path)
      else
        echo "Unknown test type"
        echo "FAIL" | tee $(results.test-result.path)
        exit 1
      fi
  - name: generate-report
    image: busybox
    script: |
      #!/bin/sh
      echo "=== Test Report ==="
      echo "Test Type: $(params.test-type)"
      echo "Result: $(cat $(results.test-result.path))"
      echo "Timestamp: $(date)"
```

---

### 10.2 构建完整的 CI Pipeline

```yaml
# experiments/10-tekton/ci-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: full-ci-pipeline
  namespace: experiments
spec:
  params:
  - name: git-url
    type: string
  - name: git-revision
    type: string
    default: main
  - name: image-name
    type: string
  workspaces:
  - name: shared-workspace
  tasks:
  # Task 1: Clone源码
  - name: fetch-repository
    taskRef:
      name: git-clone-simple
    workspaces:
    - name: output
      workspace: shared-workspace
    params:
    - name: url
      value: $(params.git-url)
    - name: revision
      value: $(params.git-revision)
  
  # Task 2: 运行单元测试
  - name: unit-tests
    taskRef:
      name: run-tests
    runAfter:
    - fetch-repository
    workspaces:
    - name: source
      workspace: shared-workspace
    params:
    - name: test-type
      value: "unit"
  
  # Task 3: 代码质量检查
  - name: code-quality
    runAfter:
    - fetch-repository
    taskSpec:
      workspaces:
      - name: source
      steps:
      - name: lint
        image: python:3.9-slim
        workingDir: $(workspaces.source.path)
        script: |
          #!/bin/bash
          echo "Running code quality checks..."
          echo "✓ Code style: passed"
          echo "✓ Security scan: passed"
          echo "✓ Complexity check: passed"
    workspaces:
    - name: source
      workspace: shared-workspace
  
  # Task 4: 构建镜像（并行）
  - name: build-image
    runAfter:
    - unit-tests
    - code-quality
    taskRef:
      name: build-simple
    workspaces:
    - name: source
      workspace: shared-workspace
    params:
    - name: image
      value: $(params.image-name)
  
  # Task 5: 集成测试
  - name: integration-tests
    taskRef:
      name: run-tests
    runAfter:
    - build-image
    workspaces:
    - name: source
      workspace: shared-workspace
    params:
    - name: test-type
      value: "integration"
  
  # Task 6: 部署到环境
  - name: deploy
    taskRef:
      name: deploy-simple
    runAfter:
    - integration-tests
    params:
    - name: image
      value: $(params.image-name)
  
  # Task 7: 健康检查
  - name: health-check
    runAfter:
    - deploy
    taskSpec:
      steps:
      - name: check
        image: curlimages/curl
        script: |
          #!/bin/sh
          echo "Performing health check..."
          sleep 5
          echo "✓ Application is healthy"
```

**运行完整 Pipeline**:
```bash
# 确保之前的Tasks已创建
kubectl apply -f experiments/10-tekton/test-task.yaml
kubectl apply -f experiments/10-tekton/ci-pipeline.yaml

# 创建PipelineRun
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: full-ci-run-$(date +%Y%m%d-%H%M%S)
  namespace: experiments
spec:
  pipelineRef:
    name: full-ci-pipeline
  params:
  - name: git-url
    value: "https://github.com/waynelw/homelab.git"
  - name: git-revision
    value: "main"
  - name: image-name
    value: "localhost:5000/demo-app:latest"
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
  timeout: "1h"
EOF

# 观察Pipeline执行
kubectl get pipelinerun -n experiments -w

# 查看详细日志
tkn pipelinerun logs -f -n experiments

# 查看任务拓扑（如果安装了Tekton Dashboard）
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
# 访问 http://localhost:9097
```

---

### 10.3 条件执行和错误处理

```yaml
# experiments/10-tekton/conditional-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: conditional-pipeline
  namespace: experiments
spec:
  params:
  - name: deploy-env
    type: string
    default: "dev"
  - name: run-security-scan
    type: string
    default: "true"
  workspaces:
  - name: workspace
  tasks:
  - name: build
    taskSpec:
      steps:
      - name: build
        image: busybox
        script: echo "Building..."
    workspaces:
    - name: source
      workspace: workspace
  
  - name: security-scan
    when:
    - input: "$(params.run-security-scan)"
      operator: in
      values: ["true"]
    runAfter:
    - build
    taskSpec:
      steps:
      - name: scan
        image: busybox
        script: |
          echo "Running security scan..."
          echo "✓ No vulnerabilities found"
  
  - name: deploy-dev
    when:
    - input: "$(params.deploy-env)"
      operator: in
      values: ["dev"]
    runAfter:
    - security-scan
    taskSpec:
      steps:
      - name: deploy
        image: busybox
        script: echo "Deploying to DEV environment..."
  
  - name: deploy-prod
    when:
    - input: "$(params.deploy-env)"
      operator: in
      values: ["prod"]
    runAfter:
    - security-scan
    taskSpec:
      steps:
      - name: deploy
        image: busybox
        script: echo "Deploying to PROD environment..."
```

---

# 📊 实验完成检查清单

## ✅ 基础知识掌握

- [ ] 理解 Pod 生命周期和状态转换
- [ ] 掌握各种控制器的使用场景
- [ ] 理解 Service 的类型和网络机制
- [ ] 掌握存储的持久化方式
- [ ] 理解配置管理最佳实践

## ✅ 高级特性理解

- [ ] 掌握 RBAC 权限配置
- [ ] 理解调度器工作原理
- [ ] 掌握监控和日志聚合
- [ ] 理解 GitOps 工作流
- [ ] 掌握 CI/CD Pipeline 设计

## ✅ 实践能力

- [ ] 能够独立设计和部署应用
- [ ] 能够排查常见问题
- [ ] 能够优化资源使用
- [ ] 能够设计安全策略
- [ ] 能够构建完整的 CI/CD 流程

---

# 🎓 进阶学习路径

## 1. 深入源码
- 阅读 Kubernetes 核心组件源码
- 理解 Controller 设计模式
- 研究 Scheduler 算法实现

## 2. 性能优化
- 集群性能调优
- 应用性能优化
- 资源配额管理

## 3. 高可用架构
- 多集群管理
- 灾难恢复
- 跨区域部署

## 4. 扩展开发
- 开发 Operator
- 自定义 CRD
- Webhook 开发

## 5. 云原生生态
- Service Mesh (Istio/Linkerd)
- Serverless (Knative)
- Edge Computing (K3s)

---

# 📝 实验记录模板

为每个实验创建记录：

```markdown
## 实验 X.Y: [实验名称]

**日期**: YYYY-MM-DD
**耗时**: X 小时

### 实验目标
- [ ] 目标 1
- [ ] 目标 2

### 实验步骤
1. 步骤 1
2. 步骤 2

### 观察结果
- 结果 1
- 结果 2

### 遇到的问题
- 问题 1: 描述 + 解决方案
- 问题 2: 描述 + 解决方案

### 关键收获
- 收获 1
- 收获 2

### 下一步计划
- [ ] 任务 1
- [ ] 任务 2
```

---

# 🛠️ 实用工具推荐

## 调试工具
```bash
# kubectl 插件
kubectl krew install neat      # 清理YAML输出
kubectl krew install tree      # 资源树形查看
kubectl krew install tail      # 日志聚合

# 其他工具
k9s                           # TUI管理工具
stern                         # 多Pod日志
kubectx/kubens               # 上下文切换
```

## 学习资源
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [CNCF Landscape](https://landscape.cncf.io/)

---

**祝你学习顺利！通过这些实验，你将深入理解 Kubernetes 的核心原理和最佳实践。** 🚀
