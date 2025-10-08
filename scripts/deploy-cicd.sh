#!/bin/bash

# Homelab CI/CD 轻量级部署脚本
# 适用于Kind集群的完整CI/CD环境

set -e

echo "🚀 开始部署Homelab CI/CD环境..."

# 颜色定kubectl get gitrepository,kustomization -A义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
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

# 检查前置条件
check_prerequisites() {
    log_info "检查前置条件..."

    # 检查kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl 未安装"
        exit 1
    fi

    # 检查kind
    if ! command -v kind &> /dev/null; then
        log_error "kind 未安装"
        exit 1
    fi

    # 检查flux
    if ! command -v flux &> /dev/null; then
        log_warning "flux CLI 未安装，将跳过某些检查"
    fi

    # 检查集群连接
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群"
        exit 1
    fi

    log_success "前置条件检查完成"
}

# 等待部署完成
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}

    log_info "等待 $namespace/$deployment 部署完成..."

    if kubectl wait --for=condition=available deployment/$deployment -n $namespace --timeout=${timeout}s; then
        log_success "$namespace/$deployment 部署完成"
    else
        log_error "$namespace/$deployment 部署失败"
        return 1
    fi
}

# 等待Pod就绪
wait_for_pods() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300}

    log_info "等待 $namespace 中标签为 $label 的Pod就绪..."

    if kubectl wait --for=condition=ready pod -l $label -n $namespace --timeout=${timeout}s; then
        log_success "$namespace 中的Pod已就绪"
    else
        log_error "$namespace 中的Pod未能就绪"
        return 1
    fi
}

# 部署基础设施组件
deploy_infrastructure() {
    log_info "开始部署基础设施组件..."

    # 应用所有配置
    kubectl apply -k clusters/kind-homelab/infrastructure/sources/
    sleep 10

    # 等待Helm仓库同步
    log_info "等待Helm仓库同步..."
    kubectl wait --for=condition=ready helmrepository --all -n flux-system --timeout=300s

    # 部署Registry
    log_info "部署Docker Registry..."
    kubectl apply -k clusters/kind-homelab/infrastructure/registry/
    wait_for_deployment registry docker-registry

    # 部署Tekton
    log_info "部署Tekton..."
    kubectl apply -k clusters/kind-homelab/infrastructure/tekton/
    sleep 300
    wait_for_pods tekton-pipelines app=tekton-pipelines-controller
    wait_for_pods tekton-pipelines app=tekton-pipelines-webhook

    # 部署监控
    log_info "部署监控系统..."
    kubectl apply -k clusters/kind-homelab/infrastructure/monitoring/
    wait_for_deployment monitoring prometheus-server
    wait_for_deployment monitoring grafana

    # 部署日志
    log_info "部署日志系统..."
    kubectl apply -k clusters/kind-homelab/infrastructure/logging/
    wait_for_deployment logging loki
    wait_for_pods logging app=promtail

    log_success "基础设施组件部署完成"
}

# 部署应用
deploy_applications() {
    log_info "开始部署示例应用..."

    kubectl apply -k clusters/kind-homelab/apps/
    wait_for_deployment demo-app demo-app

    log_success "示例应用部署完成"
}

# 显示访问信息
show_access_info() {
    log_info "获取访问信息..."

    echo ""
    echo "🎯 CI/CD环境访问信息:"
    echo "================================"

    # Tekton Dashboard
    echo "📊 Tekton Dashboard:"
    echo "   kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097"
    echo "   访问: http://localhost:9097"
    echo ""

    # Grafana
    echo "📈 Grafana:"
    echo "   kubectl port-forward -n monitoring svc/grafana 3000:80"
    echo "   访问: http://localhost:3000"
    echo "   用户名: admin"
    echo "   密码: admin123"
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

    echo "💡 提示:"
    echo "   - 使用 'kubectl get pods -A' 查看所有Pod状态"
    echo "   - 使用 'kubectl logs -f <pod-name> -n <namespace>' 查看日志"
    echo "   - 配置文件位于 clusters/kind-homelab/ 目录"
    echo ""
}

# 主函数
main() {
    echo "🏠 Homelab CI/CD 轻量级部署"
    echo "============================="
    echo ""

    check_prerequisites
    deploy_infrastructure
    deploy_applications
    show_access_info

    log_success "🎉 CI/CD环境部署完成！"
}

# 执行主函数
main "$@"