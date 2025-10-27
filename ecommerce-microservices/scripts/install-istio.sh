# Istio 快速部署脚本

set -e

echo "🚀 开始部署 Istio 服务网格..."

# 检查 istioctl 是否安装
if ! command -v istioctl &> /dev/null; then
    echo "📥 下载 Istio..."
    curl -L https://istio.io/downloadIstio | sh -
    cd istio-*
    export PATH=$PWD/bin:$PATH
    cd ..
fi

# 检查 Istio 是否已安装
if kubectl get namespace istio-system 2>/dev/null; then
    echo "⚠️  Istio 已经安装在 istio-system 命名空间"
    read -p "是否要重新安装？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ 跳过安装"
        exit 0
    fi
    echo "🗑️  卸载 Istio..."
    istioctl uninstall --purge -y
    kubectl delete namespace istio-system
fi

# 安装 Istio
echo "📦 安装 Istio (demo profile)..."
istioctl install --set profile=demo -y

# 验证安装
echo "🔍 验证 Istio 安装..."
istioctl verify-install

# 检查 Pod 状态
echo "⏳ 等待 Istio 控制平面启动..."
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s

# 显示 Pod 状态
echo "📊 Istio 组件状态："
kubectl get pods -n istio-system

# 为 ecommerce-microservices 命名空间启用自动注入
echo "🏷️  为 ecommerce-microservices 命名空间启用自动注入..."
if ! kubectl get namespace ecommerce-microservices 2>/dev/null; then
    kubectl create namespace ecommerce-microservices
fi

kubectl label namespace ecommerce-microservices istio-injection=enabled --overwrite

# 显示命名空间标签
echo "📝 命名空间标签："
kubectl get namespace ecommerce-microservices --show-labels

echo ""
echo "✅ Istio 安装完成！"
echo ""
echo "📚 下一步："
echo "  1. 部署应用到集群（将自动注入 Sidecar）"
echo "  2. 创建 VirtualService 和 DestinationRule"
echo "  3. 配置流量管理规则"
echo ""
echo "🔗 有用的命令："
echo "  istioctl proxy-status           # 查看代理状态"
echo "  istioctl proxy-config           # 查看代理配置"
echo "  kubectl get vs,dr,gateway -n ecommerce-microservices  # 查看 Istio 资源"
