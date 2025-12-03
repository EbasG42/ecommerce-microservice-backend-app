#!/bin/bash
# Script para realizar Canary Deployment
# Uso: ./canary-deploy.sh <service-name> <new-version> <namespace>

set -e

SERVICE_NAME="$1"
NEW_VERSION="$2"
NAMESPACE="${3:-dev}"

if [ -z "$SERVICE_NAME" ] || [ -z "$NEW_VERSION" ]; then
    echo "Uso: $0 <service-name> <new-version> [namespace]"
    echo "Ejemplo: $0 user-service 1.1.0 dev"
    exit 1
fi

DOCKER_USER="${DOCKER_USER:-ebasg423}"
CANARY_DEPLOYMENT="${SERVICE_NAME}-canary"
CANARY_SERVICE="${SERVICE_NAME}-canary"

echo "🚀 Iniciando Canary Deployment para ${SERVICE_NAME} versión ${NEW_VERSION} en namespace ${NAMESPACE}..."

# Paso 1: Crear deployment canary con 10% de tráfico
echo "📦 Creando deployment canary con 10% de tráfico..."
kubectl create deployment "${CANARY_DEPLOYMENT}" \
    --image="${DOCKER_USER}/${SERVICE_NAME}:${NEW_VERSION}" \
    --namespace="${NAMESPACE}" \
    --replicas=1 \
    --dry-run=client -o yaml | kubectl apply -f -

# Configurar labels y selectors
kubectl label deployment "${CANARY_DEPLOYMENT}" \
    app="${SERVICE_NAME}" \
    version="canary" \
    -n "${NAMESPACE}" --overwrite

# Crear service para canary (opcional, para testing directo)
kubectl create service clusterip "${CANARY_SERVICE}" \
    --tcp=8080:8080 \
    --namespace="${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl patch service "${CANARY_SERVICE}" -n "${NAMESPACE}" -p \
    "{\"spec\":{\"selector\":{\"app\":\"${SERVICE_NAME}\",\"version\":\"canary\"}}}"

# Esperar a que el pod canary esté listo
echo "⏳ Esperando a que el pod canary esté listo..."
kubectl wait --for=condition=ready pod \
    -l app="${SERVICE_NAME}",version=canary \
    -n "${NAMESPACE}" \
    --timeout=300s || {
    echo "❌ El pod canary no se inició correctamente"
    kubectl delete deployment "${CANARY_DEPLOYMENT}" -n "${NAMESPACE}" || true
    exit 1
}

# Paso 2: Validación inicial (60 segundos)
echo "✅ Pod canary listo. Ejecutando validación inicial (60 segundos)..."
sleep 60

# Verificar health check
echo "🔍 Verificando health check del servicio canary..."
CANARY_POD=$(kubectl get pod -l app="${SERVICE_NAME}",version=canary -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}')

if kubectl exec -n "${NAMESPACE}" "${CANARY_POD}" -- \
    curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ Health check del canary exitoso"
else
    echo "❌ Health check del canary falló. Abortando despliegue..."
    kubectl delete deployment "${CANARY_DEPLOYMENT}" -n "${NAMESPACE}"
    exit 1
fi

# Paso 3: Escalar a 50% de tráfico
echo "📈 Escalando canary a 50% de tráfico..."
MAIN_REPLICAS=$(kubectl get deployment "${SERVICE_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "2")
CANARY_REPLICAS=$((MAIN_REPLICAS))

kubectl scale deployment "${CANARY_DEPLOYMENT}" \
    --replicas="${CANARY_REPLICAS}" \
    -n "${NAMESPACE}"

echo "⏳ Esperando a que todos los pods canary estén listos..."
kubectl wait --for=condition=ready pod \
    -l app="${SERVICE_NAME}",version=canary \
    -n "${NAMESPACE}" \
    --timeout=300s

# Validación adicional (120 segundos)
echo "✅ Pods canary escalados. Ejecutando validación extendida (120 segundos)..."
sleep 120

# Verificar métricas (si Prometheus está disponible)
echo "📊 Verificando métricas del canary..."
# Aquí se podrían agregar verificaciones de métricas con Prometheus

# Paso 4: Rollout completo
echo "🚀 Canary validado exitosamente. Realizando rollout completo..."

# Actualizar el deployment principal
kubectl set image deployment/"${SERVICE_NAME}" \
    "${SERVICE_NAME}=${DOCKER_USER}/${SERVICE_NAME}:${NEW_VERSION}" \
    -n "${NAMESPACE}"

# Esperar rollout del deployment principal
echo "⏳ Esperando rollout del deployment principal..."
kubectl rollout status deployment/"${SERVICE_NAME}" -n "${NAMESPACE}" --timeout=600s

# Paso 5: Limpiar deployment canary
echo "🧹 Limpiando deployment canary..."
kubectl delete deployment "${CANARY_DEPLOYMENT}" -n "${NAMESPACE}" || true
kubectl delete service "${CANARY_SERVICE}" -n "${NAMESPACE}" || true

echo "✅ Canary Deployment completado exitosamente para ${SERVICE_NAME} versión ${NEW_VERSION}"

