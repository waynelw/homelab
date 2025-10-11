#!/usr/bin/env python3
"""
Demo Flask Application for CI/CD Pipeline Demo
"""

from flask import Flask, jsonify, render_template_string
import os
import datetime
import socket

app = Flask(__name__)

# 应用版本 - 这个会在CI/CD演示中被修改
APP_VERSION = "v1.0.0"
BUILD_TIME = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Demo App - {{ version }}</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        .version { 
            font-size: 2em; 
            color: #ffeb3b; 
            margin-bottom: 20px;
        }
        .info { 
            background: rgba(0,0,0,0.2); 
            padding: 15px; 
            border-radius: 5px; 
            margin: 10px 0;
        }
        .status { 
            color: #4caf50; 
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Demo Application</h1>
        <div class="version">Version: {{ version }}</div>
        
        <div class="info">
            <h3>📊 Application Info</h3>
            <p><strong>Build Time:</strong> {{ build_time }}</p>
            <p><strong>Hostname:</strong> {{ hostname }}</p>
            <p><strong>Status:</strong> <span class="status">✅ Running</span></p>
        </div>
        
        <div class="info">
            <h3>🔄 CI/CD Pipeline Status</h3>
            <p>This application was deployed through:</p>
            <ul>
                <li>✅ Git Repository (Source)</li>
                <li>✅ Tekton Pipeline (Build)</li>
                <li>✅ Docker Registry (Image)</li>
                <li>✅ Flux CD (Deploy)</li>
                <li>✅ Kubernetes (Runtime)</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>🛠️ Tech Stack</h3>
            <p>Python Flask + Docker + Kubernetes + Tekton + Flux</p>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    """主页面"""
    return render_template_string(
        HTML_TEMPLATE,
        version=APP_VERSION,
        build_time=BUILD_TIME,
        hostname=socket.gethostname()
    )

@app.route('/health')
def health():
    """健康检查端点"""
    return jsonify({
        'status': 'healthy',
        'version': APP_VERSION,
        'build_time': BUILD_TIME,
        'hostname': socket.gethostname()
    })

@app.route('/metrics')
def metrics():
    """Prometheus指标端点"""
    return f"""# HELP demo_app_info Application information
# TYPE demo_app_info gauge
demo_app_info{{version="{APP_VERSION}",hostname="{socket.gethostname()}"}} 1

# HELP demo_app_requests_total Total requests
# TYPE demo_app_requests_total counter
demo_app_requests_total 100

# HELP demo_app_uptime_seconds Application uptime
# TYPE demo_app_uptime_seconds gauge
demo_app_uptime_seconds 3600
"""

@app.route('/api/version')
def api_version():
    """API版本信息"""
    return jsonify({
        'version': APP_VERSION,
        'build_time': BUILD_TIME,
        'api': 'v1'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
