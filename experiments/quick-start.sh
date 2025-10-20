#!/bin/bash
# Kubernetes 学习实验快速启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查 kubectl 是否安装
check_prerequisites() {
    print_info "检查前置条件..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "无法连接到 Kubernetes 集群"
        exit 1
    fi
    
    print_success "前置条件检查通过"
}

# 创建命名空间
create_namespace() {
    print_info "创建实验命名空间..."
    
    if kubectl get namespace experiments &> /dev/null; then
        print_warning "命名空间 experiments 已存在"
    else
        kubectl create namespace experiments
        print_success "命名空间 experiments 创建成功"
    fi
}

# 显示可用实验
show_experiments() {
    echo ""
    echo "=========================================="
    echo "   Kubernetes 学习实验菜单"
    echo "=========================================="
    echo ""
    echo "1️⃣  实验一：Pod 生命周期探索"
    echo "   1.1 - 基础 Pod 和生命周期钩子"
    echo "   1.2 - 重启策略实验"
    echo "   1.3 - Init Container"
    echo ""
    echo "2️⃣  实验二：控制器机制"
    echo "   2.1 - Deployment 滚动更新"
    echo "   2.2 - StatefulSet 有序部署"
    echo ""
    echo "3️⃣  实验三：网络原理"
    echo "   3.1 - Service 类型对比"
    echo ""
    echo "5️⃣  实验五：配置管理"
    echo "   5.1 - ConfigMap 使用"
    echo ""
    echo "6️⃣  实验六：RBAC 和安全"
    echo "   6.1 - RBAC 权限实验"
    echo ""
    echo "0️⃣  清理所有实验资源"
    echo ""
    echo "=========================================="
    echo ""
}

# 运行指定实验
run_experiment() {
    local exp_file=$1
    local exp_name=$2
    
    if [ ! -f "$exp_file" ]; then
        print_error "实验文件不存在: $exp_file"
        return 1
    fi
    
    print_info "运行实验: $exp_name"
    print_info "应用配置文件: $exp_file"
    
    kubectl apply -f "$exp_file"
    
    print_success "实验部署完成"
    echo ""
    print_info "使用以下命令观察实验结果："
    echo "  kubectl get pods -n experiments -w"
    echo "  kubectl get all -n experiments"
    echo "  kubectl describe pod <pod-name> -n experiments"
    echo "  kubectl logs <pod-name> -n experiments"
}

# 清理资源
cleanup() {
    print_warning "准备清理所有实验资源..."
    read -p "确认删除 experiments 命名空间及所有资源? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "删除命名空间..."
        kubectl delete namespace experiments --wait=false
        print_success "清理命令已执行"
    else
        print_info "取消清理操作"
    fi
}

# 查看实验状态
show_status() {
    print_info "当前实验环境状态："
    echo ""
    echo "--- Namespace ---"
    kubectl get namespace experiments 2>/dev/null || echo "命名空间不存在"
    echo ""
    echo "--- Pods ---"
    kubectl get pods -n experiments 2>/dev/null || echo "无 Pod"
    echo ""
    echo "--- Services ---"
    kubectl get svc -n experiments 2>/dev/null || echo "无 Service"
    echo ""
    echo "--- Deployments ---"
    kubectl get deployments -n experiments 2>/dev/null || echo "无 Deployment"
}

# 主菜单
main_menu() {
    while true; do
        show_experiments
        read -p "请选择实验 (输入数字或 q 退出): " choice
        
        case $choice in
            1.1)
                run_experiment "01-pod-lifecycle/basic-pod.yaml" "Pod 生命周期钩子"
                ;;
            1.2)
                run_experiment "01-pod-lifecycle/restart-policy.yaml" "重启策略"
                ;;
            1.3)
                run_experiment "01-pod-lifecycle/init-container.yaml" "Init Container"
                ;;
            2.1)
                run_experiment "02-controllers/rolling-update.yaml" "Deployment 滚动更新"
                ;;
            2.2)
                run_experiment "02-controllers/statefulset.yaml" "StatefulSet"
                ;;
            3.1)
                run_experiment "03-networking/service-types.yaml" "Service 类型"
                ;;
            5.1)
                run_experiment "05-config/configmap.yaml" "ConfigMap"
                ;;
            6.1)
                run_experiment "06-security/rbac-demo.yaml" "RBAC"
                ;;
            0)
                cleanup
                ;;
            s|status)
                show_status
                ;;
            q|quit)
                print_info "退出实验环境"
                exit 0
                ;;
            *)
                print_error "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按 Enter 继续..." dummy
    done
}

# 主程序
main() {
    clear
    echo ""
    echo "🧪 Kubernetes 学习实验平台"
    echo ""
    
    check_prerequisites
    create_namespace
    
    # 如果提供了参数，直接运行
    if [ $# -gt 0 ]; then
        case $1 in
            status)
                show_status
                ;;
            cleanup)
                cleanup
                ;;
            *)
                print_error "未知命令: $1"
                echo "用法: $0 [status|cleanup]"
                exit 1
                ;;
        esac
    else
        # 否则显示交互式菜单
        main_menu
    fi
}

# 运行主程序
main "$@"
