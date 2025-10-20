# 实验记录：HostPath 节点存储

**实验日期**: 2024-01-15  
**实验耗时**: 1 小时  
**实验编号**: 4.3  

---

## 📋 实验信息

**实验目标**:
- [x] 目标 1: 理解 HostPath 的节点存储特性
- [x] 目标 2: 掌握节点存储的使用场景
- [x] 目标 3: 学习节点存储的安全考虑

**使用的资源文件**:
- `experiments/04-storage/hostpath-demo.yaml`

---

## 📊 HostPath 架构图

```mermaid
graph TB
    subgraph "Pod"
        C[Container]
        HP[HostPath Volume]
    end
    
    C --> |挂载| HP
    
    subgraph "节点文件系统"
        NFS[/tmp/hostpath-demo]
    end
    
    HP --> |映射到| NFS
```

## 🔬 实验步骤

### 步骤 1: 部署 HostPath Pod

**执行命令**:
```bash
kubectl apply -f hostpath-demo.yaml
kubectl get pods -n experiments
```

**预期结果**:
- Pod 创建成功
- 存储卷挂载到节点目录

### 步骤 2: 验证节点存储

**执行命令**:
```bash
# 在容器中写入数据
kubectl exec -it hostpath-demo -n experiments -- sh -c "echo 'HostPath data at $(date)' > /host-data/test.txt"

# 查看写入的数据
kubectl exec -it hostpath-demo -n experiments -- cat /host-data/test.txt
```

**预期结果**:
- 数据成功写入节点目录
- 可以正常读取数据

---

## 📊 实验结果

### 成功完成的目标
- ✅ 目标 1: 理解了 HostPath 的节点存储特性
- ✅ 目标 2: 验证了节点存储的使用方法
- ✅ 目标 3: 掌握了节点存储的安全考虑

### 关键观察

#### 观察 1: 节点存储特性
- **现象**: 数据直接存储在节点文件系统中
- **原因**: HostPath 直接映射节点目录
- **学习点**: 适合需要访问节点资源的场景

#### 观察 2: 安全考虑
- **现象**: 容器可以访问节点文件系统
- **原因**: HostPath 绕过了容器隔离
- **学习点**: 需要谨慎使用，存在安全风险

---

## 🧹 实验清理

```bash
kubectl delete -f hostpath-demo.yaml
```

**清理状态**: ✅ 已清理

---

## 📝 总结

HostPath 提供了直接访问节点文件系统的能力，适合日志收集、监控等场景，但需要注意安全性和可移植性。

---

**实验记录完成时间**: 2024-01-15 16:00  
**记录人**: K8s 学习者

