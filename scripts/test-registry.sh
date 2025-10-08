#!/bin/bash

# 测试Docker Registry功能
set -e

echo "🐳 测试Docker Registry..."

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. 检查Registry状态
check_registry_status() {
    log_info "检查Registry Pod状态..."
    kubectl get pods -n registry
    echo ""
    
    log_info "检查Registry服务..."
    kubectl get svc -n registry
    echo ""
}

# 2. 测试Registry API
test_registry_api() {
    log_info "测试Registry API..."
    
    echo "📊 测试 /v2/ 端点:"
    if curl -s http://localhost:5000/v2/ | grep -q "{}"; then
        log_success "Registry API响应正常"
    else
        log_error "Registry API无响应"
        return 1
    fi
    
    echo ""
    echo "📊 测试 /_catalog 端点:"
    CATALOG=$(curl -s http://localhost:5000/v2/_catalog)
    echo "   响应: $CATALOG"
    
    echo ""
}

# 3. 推送测试镜像
test_push_image() {
    log_info "测试推送镜像到Registry..."
    
    # 拉取一个小镜像
    docker pull hello-world:latest
    
    # 标记镜像
    docker tag hello-world:latest localhost:5000/hello-world:test
    
    # 推送镜像
    if docker push localhost:5000/hello-world:test; then
        log_success "镜像推送成功"
    else
        log_error "镜像推送失败"
        return 1
    fi
    
    echo ""
}

# 4. 验证镜像存储
verify_image_storage() {
    log_info "验证镜像存储..."
    
    echo "📊 检查Registry中的镜像:"
    CATALOG=$(curl -s http://localhost:5000/v2/_catalog)
    echo "   目录: $CATALOG"
    
    if echo "$CATALOG" | grep -q "hello-world"; then
        log_success "镜像已成功存储在Registry中"
        
        echo ""
        echo "📊 检查镜像标签:"
        TAGS=$(curl -s http://localhost:5000/v2/hello-world/tags/list)
        echo "   标签: $TAGS"
    else
        log_error "未找到推送的镜像"
    fi
    
    echo ""
}

# 5. 测试拉取镜像
test_pull_image() {
    log_info "测试从Registry拉取镜像..."
    
    # 删除本地镜像
    docker rmi localhost:5000/hello-world:test || true
    
    # 从Registry拉取
    if docker pull localhost:5000/hello-world:test; then
        log_success "镜像拉取成功"
    else
        log_error "镜像拉取失败"
        return 1
    fi
    
    echo ""
}

# 6. 显示Registry使用说明
show_usage() {
    log_info "Registry使用说明..."
    
    echo ""
    echo "🐳 Docker Registry使用方法:"
    echo "============================"
    echo ""
    echo "1. 推送镜像到Registry:"
    echo "   docker tag <image> localhost:5000/<name>:<tag>"
    echo "   docker push localhost:5000/<name>:<tag>"
    echo ""
    echo "2. 从Registry拉取镜像:"
    echo "   docker pull localhost:5000/<name>:<tag>"
    echo ""
    echo "3. 查看Registry中的镜像:"
    echo "   curl http://localhost:5000/v2/_catalog"
    echo ""
    echo "4. 查看特定镜像的标签:"
    echo "   curl http://localhost:5000/v2/<name>/tags/list"
    echo ""
    echo "💡 注意事项:"
    echo "============"
    echo "• Registry没有Web UI，这是正常的"
    echo "• 浏览器访问根路径会显示空白页面"
    echo "• 使用API端点或Docker命令进行操作"
    echo "• 在Tekton Pipeline中使用: localhost:5000/<image>"
    echo ""
}

# 主函数
main() {
    echo "🏠 Docker Registry功能测试"
    echo "=========================="
    echo ""
    
    check_registry_status
    test_registry_api
    test_push_image
    verify_image_storage
    test_pull_image
    show_usage
    
    log_success "🎉 Registry功能测试完成！"
}

# 执行主函数
main "$@"
