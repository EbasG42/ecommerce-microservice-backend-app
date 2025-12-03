#!/bin/bash
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
kubectl apply -f k8s/services/service_discovery/deployment.yaml

echo "⏳ Esperando a que Service Discovery esté listo..."
sleep 10

# 8. Cloud Config Server
echo "📝 Desplegando Cloud Config Server..."
kubectl apply -f k8s/services/cloud_config_server/deployment.yaml

sleep 5

# 9. Servicios de Negocio
echo "🏢 Desplegando servicios de negocio..."
for service in user product favourite order shipping payment; do
    echo "  📦 Desplegando ${service}-service..."
    kubectl apply -f k8s/services/${service}_service/deployment.yaml
done

# 10. API Gateway
echo "🚪 Desplegando API Gateway..."
kubectl apply -f k8s/services/api_gateway/deployment.yaml

# 11. Proxy Client
echo "🖥️  Desplegando Proxy Client..."
kubectl apply -f k8s/services/proxy_client/deployment.yaml

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
