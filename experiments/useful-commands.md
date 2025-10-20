# 🛠️ Kubernetes 实验常用命令速查

实验过程中最常用的 kubectl 命令和调试技巧。

---

## 📦 Pod 管理

### 查看 Pod
```bash
# 查看所有 Pod
kubectl get pods -n experiments

# 实时监控 Pod 状态变化
kubectl get pods -n experiments -w

# 查看 Pod 详细信息
kubectl get pods -n experiments -o wide

# 按标签筛选
kubectl get pods -n experiments -l app=demo

# 查看所有命名空间的 Pod
kubectl get pods -A
```

### Pod 详细信息
```bash
# 查看 Pod 详细描述（包括事件）
kubectl describe pod <pod-name> -n experiments

# 以 YAML 格式查看 Pod
kubectl get pod <pod-name> -n experiments -o yaml

# 以 JSON 格式查看并使用 jq 过滤
kubectl get pod <pod-name> -n experiments -o json | jq '.status.phase'
```

### Pod 日志
```bash
# 查看 Pod 日志
kubectl logs <pod-name> -n experiments

# 实时跟踪日志
kubectl logs -f <pod-name> -n experiments

# 查看前 100 行日志
kubectl logs --tail=100 <pod-name> -n experiments

# 查看最近 1 小时的日志
kubectl logs --since=1h <pod-name> -n experiments

# 多容器 Pod 指定容器
kubectl logs <pod-name> -c <container-name> -n experiments

# 查看之前崩溃容器的日志
kubectl logs <pod-name> -n experiments --previous
```

### Pod 交互
```bash
# 进入 Pod 执行命令
kubectl exec -it <pod-name> -n experiments -- /bin/sh
kubectl exec -it <pod-name> -n experiments -- /bin/bash

# 在 Pod 中执行单条命令
kubectl exec <pod-name> -n experiments -- ls -la

# 从 Pod 拷贝文件
kubectl cp <pod-name>:/path/to/file ./local-file -n experiments
kubectl cp ./local-file <pod-name>:/path/to/file -n experiments

# 端口转发
kubectl port-forward <pod-name> 8080:80 -n experiments
```

---

## 🎮 Deployment 管理

### 查看 Deployment
```bash
# 查看 Deployment
kubectl get deployments -n experiments

# 查看 Deployment 详情
kubectl describe deployment <deployment-name> -n experiments

# 查看 ReplicaSet
kubectl get rs -n experiments
```

### 更新 Deployment
```bash
# 更新镜像
kubectl set image deployment/<deployment-name> <container-name>=<new-image> -n experiments

# 编辑 Deployment
kubectl edit deployment <deployment-name> -n experiments

# 扩缩容
kubectl scale deployment <deployment-name> --replicas=5 -n experiments

# 自动扩缩容
kubectl autoscale deployment <deployment-name> --min=2 --max=10 --cpu-percent=80 -n experiments
```

### 滚动更新管理
```bash
# 查看滚动更新状态
kubectl rollout status deployment/<deployment-name> -n experiments

# 查看滚动历史
kubectl rollout history deployment/<deployment-name> -n experiments

# 查看特定版本详情
kubectl rollout history deployment/<deployment-name> --revision=2 -n experiments

# 回滚到上一版本
kubectl rollout undo deployment/<deployment-name> -n experiments

# 回滚到特定版本
kubectl rollout undo deployment/<deployment-name> --to-revision=2 -n experiments

# 暂停滚动更新
kubectl rollout pause deployment/<deployment-name> -n experiments

# 恢复滚动更新
kubectl rollout resume deployment/<deployment-name> -n experiments

# 重启 Deployment（K8s 1.15+）
kubectl rollout restart deployment/<deployment-name> -n experiments
```

---

## 🌐 Service 和网络

### 查看 Service
```bash
# 查看所有 Service
kubectl get svc -n experiments

# 查看 Service 详情
kubectl describe svc <service-name> -n experiments

# 查看 Endpoints
kubectl get endpoints <service-name> -n experiments
```

### 测试网络连接
```bash
# 创建临时 Pod 测试网络
kubectl run test-pod --rm -it --image=busybox --restart=Never -n experiments -- sh

# 在测试 Pod 中执行
nslookup <service-name>.experiments.svc.cluster.local
wget -O- http://<service-name>
ping <service-name>

# 使用 curl 测试
kubectl run curl --rm -it --image=curlimages/curl --restart=Never -n experiments -- curl http://<service-name>

# 测试外部访问（NodePort）
curl http://localhost:<node-port>
```

---

## 💾 存储管理

### PV 和 PVC
```bash
# 查看 PersistentVolume
kubectl get pv

# 查看 PersistentVolumeClaim
kubectl get pvc -n experiments

# 查看 StorageClass
kubectl get storageclass

# 查看 PVC 详情
kubectl describe pvc <pvc-name> -n experiments

# 查看哪些 Pod 使用了某个 PVC
kubectl get pods -n experiments -o json | jq -r '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="<pvc-name>") | .metadata.name'
```

---

## ⚙️ ConfigMap 和 Secret

### ConfigMap
```bash
# 查看 ConfigMap
kubectl get configmap -n experiments

# 查看 ConfigMap 内容
kubectl describe configmap <configmap-name> -n experiments
kubectl get configmap <configmap-name> -n experiments -o yaml

# 从文件创建 ConfigMap
kubectl create configmap <name> --from-file=<file-path> -n experiments

# 从字面量创建
kubectl create configmap <name> --from-literal=key1=value1 --from-literal=key2=value2 -n experiments

# 编辑 ConfigMap
kubectl edit configmap <configmap-name> -n experiments
```

### Secret
```bash
# 查看 Secret
kubectl get secret -n experiments

# 查看 Secret（隐藏敏感信息）
kubectl describe secret <secret-name> -n experiments

# 查看 Secret 值（base64 编码）
kubectl get secret <secret-name> -n experiments -o yaml

# 解码 Secret
kubectl get secret <secret-name> -n experiments -o jsonpath='{.data.password}' | base64 -d

# 创建 Secret
kubectl create secret generic <name> --from-literal=username=admin --from-literal=password=secret -n experiments

# 从文件创建
kubectl create secret generic <name> --from-file=<file-path> -n experiments
```

---

## 🔐 RBAC 和权限

### 查看权限
```bash
# 查看 ServiceAccount
kubectl get sa -n experiments

# 查看 Role
kubectl get role -n experiments

# 查看 RoleBinding
kubectl get rolebinding -n experiments

# 查看 ClusterRole
kubectl get clusterrole

# 查看 ClusterRoleBinding
kubectl get clusterrolebinding
```

### 检查权限
```bash
# 检查当前用户是否有权限
kubectl auth can-i get pods -n experiments

# 检查特定 ServiceAccount 的权限
kubectl auth can-i get pods --as=system:serviceaccount:experiments:pod-reader -n experiments

# 列出用户可以执行的操作
kubectl auth can-i --list -n experiments
```

---

## 🐛 调试和故障排查

### Pod 故障排查
```bash
# 查看 Pod 事件
kubectl get events -n experiments --sort-by='.lastTimestamp'
kubectl get events -n experiments --field-selector involvedObject.name=<pod-name>

# 查看 Pod 的容器状态
kubectl get pod <pod-name> -n experiments -o jsonpath='{.status.containerStatuses[*].state}'

# 查看重启次数
kubectl get pods -n experiments -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].restartCount}{"\n"}{end}'

# 查看 Pod 调度失败原因
kubectl describe pod <pod-name> -n experiments | grep -A 10 Events

# 查看节点资源
kubectl top nodes
kubectl describe node <node-name>
```

### 网络调试
```bash
# 查看 iptables 规则（在节点上）
docker exec kind-homelab-control-plane iptables-save | grep <service-name>

# 查看 CoreDNS 日志
kubectl logs -n kube-system -l k8s-app=kube-dns

# 测试 DNS 解析
kubectl run -it --rm debug --image=busybox --restart=Never -n experiments -- nslookup kubernetes.default
```

### 资源使用
```bash
# 查看节点资源使用
kubectl top nodes

# 查看 Pod 资源使用
kubectl top pods -n experiments

# 查看特定 Pod 的资源使用
kubectl top pod <pod-name> -n experiments --containers
```

---

## 📊 监控和日志

### Prometheus
```bash
# 端口转发访问 Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# 访问 http://localhost:9090
```

### Grafana
```bash
# 端口转发访问 Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# 访问 http://localhost:3000
# 默认用户名/密码: admin/admin123
```

### Tekton Dashboard
```bash
# 端口转发访问 Tekton Dashboard
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097

# 访问 http://localhost:9097
```

---

## 🔄 Flux GitOps

### Flux 管理
```bash
# 查看 GitRepository
kubectl get gitrepository -A

# 查看 Kustomization
kubectl get kustomization -A

# 查看 HelmRelease
kubectl get helmrelease -A

# 手动触发同步
flux reconcile source git <git-repo-name> -n experiments
flux reconcile kustomization <kustomization-name> -n experiments

# 查看 Flux 日志
flux logs -n flux-system
```

---

## 🚀 Tekton CI/CD

### Pipeline 管理
```bash
# 查看 Pipeline
kubectl get pipeline -n experiments

# 查看 PipelineRun
kubectl get pipelinerun -n experiments

# 查看 PipelineRun 详情
kubectl describe pipelinerun <pipelinerun-name> -n experiments

# 查看 Task
kubectl get task -n experiments

# 查看 TaskRun
kubectl get taskrun -n experiments

# 查看 PipelineRun 日志
kubectl logs -n experiments -l tekton.dev/pipelineRun=<pipelinerun-name> --all-containers=true

# 删除 PipelineRun
kubectl delete pipelinerun <pipelinerun-name> -n experiments
```

---

## 🧹 资源清理

### 删除资源
```bash
# 删除单个资源
kubectl delete pod <pod-name> -n experiments
kubectl delete deployment <deployment-name> -n experiments
kubectl delete svc <service-name> -n experiments

# 根据标签删除
kubectl delete pods -l app=demo -n experiments

# 删除所有 Pod
kubectl delete pods --all -n experiments

# 删除命名空间（包含所有资源）
kubectl delete namespace experiments

# 强制删除（如果卡住）
kubectl delete pod <pod-name> -n experiments --force --grace-period=0
```

### 批量清理
```bash
# 删除所有 Completed 状态的 Pod
kubectl delete pods -n experiments --field-selector=status.phase==Succeeded

# 删除所有 Failed 状态的 Pod
kubectl delete pods -n experiments --field-selector=status.phase==Failed

# 清理所有 PipelineRun
kubectl delete pipelinerun --all -n experiments
```

---

## 📋 资源模板

### 快速创建资源
```bash
# 生成 YAML 模板（不实际创建）
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml

# 生成并保存到文件
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml

# 创建 Service
kubectl expose deployment nginx --port=80 --type=ClusterIP --dry-run=client -o yaml

# 创建 ConfigMap
kubectl create configmap my-config --from-literal=key=value --dry-run=client -o yaml
```

---

## 🔍 高级查询

### JSONPath 查询
```bash
# 查询所有 Pod 的镜像
kubectl get pods -n experiments -o jsonpath='{.items[*].spec.containers[*].image}'

# 查询 Pod 的 IP
kubectl get pods -n experiments -o jsonpath='{.items[*].status.podIP}'

# 查询 Pod 的节点
kubectl get pods -n experiments -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'

# 格式化输出
kubectl get pods -n experiments -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

### 使用 grep 和 awk
```bash
# 查找特定状态的 Pod
kubectl get pods -n experiments | grep Running
kubectl get pods -n experiments | grep -v Running

# 统计 Pod 数量
kubectl get pods -n experiments | wc -l

# 提取特定字段
kubectl get pods -n experiments -o wide | awk '{print $1, $7}'
```

---

## 💡 实用技巧

### 别名设置
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kdel='kubectl delete'
alias kex='kubectl exec -it'
alias klog='kubectl logs -f'
alias kns='kubectl config set-context --current --namespace'

# 使用
k get pods -n experiments
klog <pod-name> -n experiments
```

### Shell 自动补全
```bash
# Bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# Zsh
source <(kubectl completion zsh)
echo "source <(kubectl completion zsh)" >> ~/.zshrc
```

### 上下文切换
```bash
# 查看当前上下文
kubectl config current-context

# 切换上下文
kubectl config use-context kind-homelab

# 设置默认命名空间
kubectl config set-context --current --namespace=experiments

# 查看配置
kubectl config view
```

---

## 📚 参考资源

- [kubectl 速查表](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl 命令文档](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)
- [JSONPath 支持](https://kubernetes.io/docs/reference/kubectl/jsonpath/)

---

**提示**: 将此文件加入书签，在实验过程中随时查阅！ 📖
