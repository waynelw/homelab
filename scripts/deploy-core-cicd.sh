#!/bin/bash

# 核心CI/CD组件部署脚本 - 解决网络问题的简化版本
set -e

echo "🚀 部署核心CI/CD组件..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. 直接安装Tekton (不依赖Helm)
install_tekton() {
    log_info "安装Tekton Pipelines..."
    
    # 安装Tekton Pipelines
    kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
    
    # 等待Tekton Pipelines就绪
    log_info "等待Tekton Pipelines就绪..."
    kubectl wait --for=condition=ready pod -l app=tekton-pipelines-controller -n tekton-pipelines --timeout=300s
    kubectl wait --for=condition=ready pod -l app=tekton-pipelines-webhook -n tekton-pipelines --timeout=300s
    
    # 安装Tekton Dashboard
    log_info "安装Tekton Dashboard..."
    kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
    
    # 等待Dashboard就绪
    kubectl wait --for=condition=ready pod -l app=tekton-dashboard -n tekton-pipelines --timeout=300s
    
    log_success "Tekton安装完成"
}

# 2. 部署轻量级Registry
install_registry() {
    log_info "部署Docker Registry..."
    
    # 创建namespace
    kubectl create namespace registry --dry-run=client -o yaml | kubectl apply -f -
    
    # 直接部署Registry (不使用Helm)
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        env:
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        volumeMounts:
        - name: registry-storage
          mountPath: /var/lib/registry
        resources:
          limits:
            cpu: 100m
            memory: 256Mi
          requests:
            cpu: 50m
            memory: 128Mi
      volumes:
      - name: registry-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
  namespace: registry
spec:
  selector:
    app: docker-registry
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
EOF
    
    # 等待Registry就绪
    kubectl wait --for=condition=available deployment/docker-registry -n registry --timeout=300s
    
    log_success "Docker Registry部署完成"
}

# 3. 部署示例应用
deploy_demo_app() {
    log_info "部署示例应用..."
    
    kubectl apply -k clusters/kind-homelab/apps/demo-app/
    
    # 等待应用就绪
    kubectl wait --for=condition=available deployment/demo-app -n demo-app --timeout=300s
    
    log_success "示例应用部署完成"
}

# 4. 创建基础的CI Pipeline
create_basic_pipeline() {
    log_info "创建基础CI Pipeline..."
    
    # 安装基础的ClusterTasks
    kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml
    kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.6/buildah.yaml
    
    log_success "基础Pipeline创建完成"
}

# 5. 显示访问信息
show_access_info() {
    log_info "获取访问信息..."
    
    echo ""
    echo "🎯 核心CI/CD组件访问信息:"
    echo "================================"
    
    # Tekton Dashboard
    echo "📊 Tekton Dashboard:"
    echo "   kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097"
    echo "   访问: http://localhost:9097"
    echo ""
    
    # Registry
    echo "🐳 Docker Registry:"
    echo "   kubectl port-forward -n registry svc/docker-registry 5000:5000"
    echo "   访问: http://localhost:5000"
    echo ""
    
    # 示例应用
    echo "🚀 示例应用:"
    echo "   kubectl port-forward -n demo-app svc/demo-app 8080:80"
    echo "   访问: http://localhost:8080"
    echo ""
    
    echo "💡 下一步:"
    echo "   1. 访问Tekton Dashboard查看Pipeline"
    echo "   2. 创建PipelineRun测试CI流程"
    echo "   3. 稍后可以手动安装监控组件"
    echo ""
}

# 主函数
main() {
    echo "🏠 核心CI/CD组件部署"
    echo "===================="
    echo ""
    
    install_tekton
    install_registry
    deploy_demo_app
    create_basic_pipeline
    show_access_info
    
    log_success "🎉 核心CI/CD组件部署完成！"
    log_warning "监控组件因网络问题暂时跳过，可稍后手动安装"
}

# 执行主函数
main "$@"
