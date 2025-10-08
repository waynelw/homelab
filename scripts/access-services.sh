#!/bin/bash

# 访问CI/CD和监控服务的脚本
set -e

echo "🚀 启动CI/CD和监控服务访问..."

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

# 获取WSL IP
WSL_IP=$(hostname -I | awk '{print $1}')

echo "🏠 CI/CD和监控服务访问"
echo "====================="
echo ""

log_info "WSL IP地址: $WSL_IP"
echo ""

# 启动端口转发
start_port_forwards() {
    log_info "启动端口转发..."

    # 停止现有的端口转发
    pkill -f "kubectl port-forward" || true
    sleep 2

    # Grafana
    kubectl port-forward -n monitoring svc/grafana 3000:80 --address=0.0.0.0 > /dev/null 2>&1 &
    GRAFANA_PID=$!

    # Prometheus
    kubectl port-forward -n monitoring svc/prometheus-server 9090:80 --address=0.0.0.0 > /dev/null 2>&1 &
    PROMETHEUS_PID=$!

    # Tekton Dashboard
    kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097 --address=0.0.0.0 > /dev/null 2>&1 &
    TEKTON_PID=$!

    # Demo App
    kubectl port-forward -n demo-app svc/demo-app 8080:80 --address=0.0.0.0 > /dev/null 2>&1 &
    DEMO_PID=$!

    # Docker Registry
    kubectl port-forward -n registry svc/docker-registry 5000:5000 --address=0.0.0.0 > /dev/null 2>&1 &
    REGISTRY_PID=$!

    sleep 3
    log_success "端口转发已启动"
}

# 测试服务
test_services() {
    log_info "测试服务连接..."

    echo ""
    echo "📊 Grafana:"
    if curl -s http://localhost:3000 > /dev/null; then
        echo "   ✅ 状态: 正常"
        echo "   🌐 访问: http://localhost:3000"
        echo "   🌐 WSL访问: http://$WSL_IP:3000"
        echo "   � 用户名: admin"
        echo "   🔑 密码: admin123"
    else
        echo "   ❌ 状态: 无法访问"
    fi

    echo ""
    echo "📈 Prometheus:"
    if curl -s http://localhost:9090 > /dev/null; then
        echo "   ✅ 状态: 正常"
        echo "   🌐 访问: http://localhost:9090"
        echo "   🌐 WSL访问: http://$WSL_IP:9090"
    else
        echo "   ❌ 状态: 无法访问"
    fi

    echo ""
    echo "�📊 Tekton Dashboard:"
    if curl -s http://localhost:9097 > /dev/null; then
        echo "   ✅ 状态: 正常"
        echo "   🌐 访问: http://localhost:9097"
        echo "   🌐 WSL访问: http://$WSL_IP:9097"
    else
        echo "   ❌ 状态: 无法访问"
    fi

    echo ""
    echo "🚀 Demo应用:"
    if curl -s http://localhost:8080 > /dev/null; then
        echo "   ✅ 状态: 正常"
        echo "   🌐 访问: http://localhost:8080"
        echo "   🌐 WSL访问: http://$WSL_IP:8080"
    else
        echo "   ❌ 状态: 无法访问"
    fi

    echo ""
    echo "🐳 Docker Registry:"
    if curl -s http://localhost:5000/v2/ > /dev/null; then
        echo "   ✅ 状态: 正常"
        echo "   🌐 访问: http://localhost:5000"
        echo "   🌐 WSL访问: http://$WSL_IP:5000"
    else
        echo "   ❌ 状态: 无法访问"
    fi
}

# 获取访问信息
get_access_info() {
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

# 显示使用说明
show_usage() {
    echo ""
    echo "💡 使用说明:"
    echo "============"
    echo "1. 在Windows浏览器中访问上述URL"
    echo "2. 如果localhost不工作，请使用WSL IP地址"
    echo "3. 按Ctrl+C停止端口转发"
    echo ""

    echo "🔧 故障排除:"
    echo "============"
    echo "• 如果服务无法访问，检查Pod状态: kubectl get pods -A"
    echo "• 重启端口转发: pkill -f 'kubectl port-forward' && $0"
    echo "• 检查防火墙设置"
    echo "• 查看端口转发命令: $0 info"
    echo ""
}

# 主函数
main() {
    case "${1:-}" in
        "info")
            get_access_info
            ;;
        *)
            start_port_forwards
            test_services
            show_usage

            log_info "端口转发正在运行，按Ctrl+C停止..."

            # 等待用户中断
            trap 'log_info "停止端口转发..."; pkill -f "kubectl port-forward"; exit 0' INT

            while true; do
                sleep 10
            done
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
