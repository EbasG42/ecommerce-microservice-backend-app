#!/usr/bin/env python3
"""
Script para generar configuraciones de Monitoreo y Scripts de Automatización
"""
import os
import yaml
from pathlib import Path

BASE_DIR = Path('/home/user/plataformas-ii/ecommerce-microservice-backend-app')
K8S_DIR = BASE_DIR / 'k8s'
SCRIPTS_DIR = BASE_DIR / 'scripts'

def create_service_monitor():
    """Crear ServiceMonitor para Prometheus"""
    
    service_monitor = {
        'apiVersion': 'monitoring.coreos.com/v1',
        'kind': 'ServiceMonitor',
        'metadata': {
            'name': 'microservices-metrics',
            'namespace': 'monitoring',
            'labels': {'release': 'prometheus'}
        },
        'spec': {
            'selector': {'matchLabels': {'metrics': 'enabled'}},
            'namespaceSelector': {'matchNames': ['dev', 'qa', 'prod']},
            'endpoints': [{
                'port': 'http',
                'path': '/actuator/prometheus',
                'interval': '30s',
                'scrapeTimeout': '10s'
            }]
        }
    }
    
    return service_monitor

def create_prometheus_rules():
    """Crear PrometheusRules para alertas"""
    
    rules = {
        'apiVersion': 'monitoring.coreos.com/v1',
        'kind': 'PrometheusRule',
        'metadata': {
            'name': 'microservices-alerts',
            'namespace': 'monitoring',
            'labels': {'release': 'prometheus'}
        },
        'spec': {
            'groups': [{
                'name': 'microservices',
                'interval': '30s',
                'rules': [
                    {
                        'alert': 'HighErrorRate',
                        'expr': 'sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (application) / sum(rate(http_server_requests_seconds_count[5m])) by (application) > 0.05',
                        'for': '5m',
                        'labels': {'severity': 'warning'},
                        'annotations': {
                            'summary': 'High error rate detected in {{ $labels.application }}',
                            'description': 'Error rate is {{ $value | humanizePercentage }} for {{ $labels.application }}'
                        }
                    },
                    {
                        'alert': 'ServiceDown',
                        'expr': 'up{job=~".*service.*"} == 0',
                        'for': '2m',
                        'labels': {'severity': 'critical'},
                        'annotations': {
                            'summary': 'Service {{ $labels.job }} is down',
                            'description': '{{ $labels.job }} has been down for more than 2 minutes'
                        }
                    },
                    {
                        'alert': 'HighResponseTime',
                        'expr': 'histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (application, le)) > 1',
                        'for': '5m',
                        'labels': {'severity': 'warning'},
                        'annotations': {
                            'summary': 'High response time in {{ $labels.application }}',
                            'description': '95th percentile response time is {{ $value }}s'
                        }
                    },
                    {
                        'alert': 'HighMemoryUsage',
                        'expr': '(sum(jvm_memory_used_bytes{area="heap"}) by (application) / sum(jvm_memory_max_bytes{area="heap"}) by (application)) > 0.9',
                        'for': '5m',
                        'labels': {'severity': 'warning'},
                        'annotations': {
                            'summary': 'High memory usage in {{ $labels.application }}',
                            'description': 'Memory usage is {{ $value | humanizePercentage }}'
                        }
                    }
                ]
            }]
        }
    }
    
    return rules

def create_deployment_script():
    """Crear script de despliegue"""
    
    script = '''#!/bin/bash
# Script para desplegar todos los componentes
# E-Commerce Microservices Platform

set -e

BASE_DIR="/home/user/plataformas-ii/ecommerce-microservice-backend-app"
cd "$BASE_DIR"

NAMESPACE=${1:-dev}

echo "🚀 Desplegando E-Commerce Microservices en namespace: $NAMESPACE"
echo "================================================================"

# 1. Crear namespaces
echo "📦 Creando namespaces..."
kubectl apply -f k8s/namespaces/namespaces.yaml

# 2. Storage Classes
echo "💾 Aplicando Storage Classes..."
kubectl apply -f k8s/storage/storage-class.yaml

# 3. PostgreSQL
echo "🗄️  Desplegando PostgreSQL..."
kubectl apply -f k8s/databases/postgres-secret.yaml
kubectl apply -f k8s/databases/postgres-init-scripts.yaml
kubectl apply -f k8s/databases/postgres-statefulset.yaml

echo "⏳ Esperando a que PostgreSQL esté listo..."
kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s || true

# 4. ConfigMaps y Secrets
echo "⚙️  Aplicando ConfigMaps..."
kubectl apply -f k8s/config/

echo "🔐 Aplicando Secrets..."
kubectl apply -f k8s/secrets/

# 5. RBAC
echo "🔒 Aplicando RBAC..."
kubectl apply -f k8s/rbac/

# 6. Network Policies
echo "🌐 Aplicando Network Policies..."
kubectl apply -f k8s/network-policies/

# 7. Service Discovery
echo "🔍 Desplegando Service Discovery..."
kubectl apply -f k8s/services/discovery/deployment.yaml

echo "⏳ Esperando a que Service Discovery esté listo..."
sleep 10

# 8. Cloud Config Server
echo "📝 Desplegando Cloud Config Server..."
kubectl apply -f k8s/services/config/deployment.yaml

sleep 5

# 9. Servicios de Negocio
echo "🏢 Desplegando servicios de negocio..."
for service in user product favourite order shipping payment; do
    echo "  📦 Desplegando ${service}-service..."
    kubectl apply -f k8s/services/${service}_service/deployment.yaml
done

# 10. API Gateway
echo "🚪 Desplegando API Gateway..."
kubectl apply -f k8s/services/gateway/deployment.yaml

# 11. Proxy Client
echo "🖥️  Desplegando Proxy Client..."
kubectl apply -f k8s/services/proxy/deployment.yaml

# 12. Ingress
echo "🌍 Aplicando Ingress..."
kubectl apply -f k8s/ingress/ingress.yaml

# 13. HPA
echo "📊 Aplicando HPA..."
kubectl apply -f k8s/autoscaling/

echo ""
echo "✅ Despliegue completado!"
echo ""
echo "📊 Verificar estado:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl get svc -n $NAMESPACE"
echo ""
echo "🔍 Ver logs:"
echo "  kubectl logs -n $NAMESPACE -l app=service-discovery"
'''
    
    return script

def create_health_check_script():
    """Crear script de health check"""
    
    script = '''#!/bin/bash
# Script de Health Check
# E-Commerce Microservices Platform

NAMESPACE=${1:-dev}

echo "🏥 Health Check - Namespace: $NAMESPACE"
echo "========================================"
echo ""

# Verificar pods
echo "📦 Estado de Pods:"
kubectl get pods -n $NAMESPACE --no-headers | awk '{
    status=$3; 
    if(status!="Running" && status!="Completed") 
        print "  ❌ "$1" - "$3; 
    else 
        print "  ✅ "$1" - "$3
}'

echo ""

# Verificar servicios
echo "🌐 Servicios Expuestos:"
kubectl get svc -n $NAMESPACE --no-headers | awk '{print "  - "$1" ("$2") - "$5}'

echo ""

# Verificar HPA
echo "📊 Autoscaling Status:"
kubectl get hpa -n $NAMESPACE --no-headers 2>/dev/null | awk '{
    print "  - "$1": "$3"/"$4" réplicas (CPU: "$5")"
}' || echo "  No HPAs configurados"

echo ""

# Verificar eventos recientes
echo "📋 Eventos Recientes (últimos 10):"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

echo ""
echo "✅ Health check completado"
'''
    
    return script

if __name__ == '__main__':
    print('📊 Generando configuraciones de Monitoreo y Scripts...')
    
    # Monitoring
    (K8S_DIR / 'monitoring').mkdir(parents=True, exist_ok=True)
    
    service_monitor = create_service_monitor()
    with open(K8S_DIR / 'monitoring' / 'service-monitors.yaml', 'w') as f:
        yaml.dump(service_monitor, f, default_flow_style=False, sort_keys=False)
    print('  ✅ ServiceMonitor')
    
    prometheus_rules = create_prometheus_rules()
    with open(K8S_DIR / 'monitoring' / 'prometheus-rules.yaml', 'w') as f:
        yaml.dump(prometheus_rules, f, default_flow_style=False, sort_keys=False)
    print('  ✅ PrometheusRules')
    
    # Scripts
    SCRIPTS_DIR.mkdir(parents=True, exist_ok=True)
    
    deploy_script = create_deployment_script()
    with open(SCRIPTS_DIR / 'deploy-all.sh', 'w') as f:
        f.write(deploy_script)
    os.chmod(SCRIPTS_DIR / 'deploy-all.sh', 0o755)
    print('  ✅ deploy-all.sh')
    
    health_script = create_health_check_script()
    with open(SCRIPTS_DIR / 'health-check.sh', 'w') as f:
        f.write(health_script)
    os.chmod(SCRIPTS_DIR / 'health-check.sh', 0o755)
    print('  ✅ health-check.sh')
    
    print('✅ Configuraciones de Monitoreo y Scripts generadas!')

