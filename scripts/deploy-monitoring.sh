#!/bin/bash

# 部署监控和日志系统
set -e

echo "🚀 部署监控和日志系统..."

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

# 1. 添加Helm仓库
add_helm_repos() {
    log_info "添加Helm仓库..."
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    log_success "Helm仓库添加完成"
}

# 2. 创建监控命名空间
create_namespaces() {
    log_info "创建命名空间..."
    
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "命名空间创建完成"
}

# 3. 部署Prometheus
deploy_prometheus() {
    log_info "部署Prometheus..."
    
    helm install prometheus prometheus-community/prometheus \
        --namespace monitoring \
        --set alertmanager.enabled=true \
        --set server.persistentVolume.enabled=true \
        --set server.persistentVolume.size=8Gi \
        --set server.retention=7d \
        --set server.resources.limits.cpu=500m \
        --set server.resources.limits.memory=512Mi \
        --set server.resources.requests.cpu=200m \
        --set server.resources.requests.memory=256Mi \
        --set alertmanager.resources.limits.cpu=100m \
        --set alertmanager.resources.limits.memory=128Mi \
        --set alertmanager.resources.requests.cpu=50m \
        --set alertmanager.resources.requests.memory=64Mi \
        --set nodeExporter.resources.limits.cpu=100m \
        --set nodeExporter.resources.limits.memory=128Mi \
        --set nodeExporter.resources.requests.cpu=50m \
        --set nodeExporter.resources.requests.memory=64Mi \
        --set pushgateway.enabled=false
    
    log_success "Prometheus部署完成"
}

# 4. 部署Grafana
deploy_grafana() {
    log_info "部署Grafana..."
    
    helm install grafana grafana/grafana \
        --namespace monitoring \
        --set persistence.enabled=true \
        --set persistence.size=1Gi \
        --set resources.limits.cpu=200m \
        --set resources.limits.memory=256Mi \
        --set resources.requests.cpu=100m \
        --set resources.requests.memory=128Mi \
        --set adminPassword=admin123 \
        --set service.type=ClusterIP \
        --set datasources."datasources\.yaml".apiVersion=1 \
        --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
        --set datasources."datasources\.yaml".datasources[0].type=prometheus \
        --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.monitoring.svc.cluster.local \
        --set datasources."datasources\.yaml".datasources[0].access=proxy \
        --set datasources."datasources\.yaml".datasources[0].isDefault=true
    
    log_success "Grafana部署完成"
}

# 5. 部署Loki
deploy_loki() {
    log_info "部署Loki..."
    
    helm install loki grafana/loki \
        --namespace logging \
        --set deploymentMode=SingleBinary \
        --set singleBinary.replicas=1 \
        --set singleBinary.persistence.enabled=true \
        --set singleBinary.persistence.size=5Gi \
        --set singleBinary.resources.limits.cpu=200m \
        --set singleBinary.resources.limits.memory=256Mi \
        --set singleBinary.resources.requests.cpu=100m \
        --set singleBinary.resources.requests.memory=128Mi \
        --set loki.auth_enabled=false \
        --set loki.commonConfig.replication_factor=1 \
        --set loki.storage.type=filesystem \
        --set loki.limits_config.retention_period=168h
    
    log_success "Loki部署完成"
}

# 6. 部署Promtail
deploy_promtail() {
    log_info "部署Promtail..."
    
    helm install promtail grafana/promtail \
        --namespace logging \
        --set resources.limits.cpu=100m \
        --set resources.limits.memory=128Mi \
        --set resources.requests.cpu=50m \
        --set resources.requests.memory=64Mi \
        --set config.clients[0].url=http://loki-gateway.logging.svc.cluster.local/loki/api/v1/push
    
    log_success "Promtail部署完成"
}

# 7. 等待部署完成
wait_for_deployments() {
    log_info "等待部署完成..."
    
    kubectl wait --for=condition=available deployment/prometheus-server -n monitoring --timeout=300s
    kubectl wait --for=condition=available deployment/grafana -n monitoring --timeout=300s
    kubectl wait --for=condition=available deployment/loki -n logging --timeout=300s
    kubectl wait --for=condition=ready pod -l app=promtail -n logging --timeout=300s
    
    log_success "所有部署已完成"
}

# 8. 显示访问信息
show_access_info() {
    log_info "获取访问信息..."
    
    echo ""
    echo "🎯 监控和日志系统访问信息:"
    echo "============================"
    
    echo "📊 Grafana:"
    echo "   kubectl port-forward -n monitoring svc/grafana 3000:80"
    echo "   访问: http://localhost:3000"
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    
    echo "📈 Prometheus:"
    echo "   kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
    echo "   访问: http://localhost:9090"
    echo ""
    
    echo "📊 Tekton Dashboard:"
    echo "   kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097"
    echo "   访问: http://localhost:9097"
    echo ""
    
    echo "🐳 Docker Registry:"
    echo "   kubectl port-forward -n registry svc/docker-registry 5000:5000"
    echo "   访问: http://localhost:5000"
    echo ""
    
    echo "🚀 Demo应用:"
    echo "   kubectl port-forward -n demo-app svc/demo-app 8080:80"
    echo "   访问: http://localhost:8080"
    echo ""
}

# 主函数
main() {
    echo "🏠 监控和日志系统部署"
    echo "====================="
    echo ""
    
    add_helm_repos
    create_namespaces
    deploy_prometheus
    deploy_grafana
    deploy_loki
    deploy_promtail
    wait_for_deployments
    show_access_info
    
    log_success "🎉 监控和日志系统部署完成！"
}

# 执行主函数
main "$@"
