#!/bin/bash
# Script para realizar Blue-Green Deployment
# Uso: ./blue-green-deploy.sh <namespace> <new-version>

set -e

NAMESPACE="${1:-dev}"
NEW_VERSION="$2"

if [ -z "$NEW_VERSION" ]; then
    echo "Uso: $0 <namespace> <new-version>"
    echo "Ejemplo: $0 prod 1.1.0"
    exit 1
fi

DOCKER_USER="${DOCKER_USER:-ebasg423}"

echo "🚀 Iniciando Blue-Green Deployment en namespace ${NAMESPACE} con versión ${NEW_VERSION}..."

# Lista de servicios a desplegar
SERVICES=(
    "api-gateway"
    "user-service"
    "product-service"
    "favourite-service"
    "order-service"
    "shipping-service"
    "payment-service"
    "proxy-client"
    "service-discovery"
    "cloud-config-server"
)

for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "🔄 Procesando servicio: ${SERVICE}"
    
    # Determinar si el servicio actual es "blue" o "green"
    CURRENT_COLOR=$(kubectl get deployment "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.metadata.labels.color}' 2>/dev/null || echo "blue")
    
    if [ "$CURRENT_COLOR" = "blue" ]; then
        NEW_COLOR="green"
    else
        NEW_COLOR="blue"
    fi
    
    GREEN_DEPLOYMENT="${SERVICE}-green"
    BLUE_DEPLOYMENT="${SERVICE}-blue"
    
    # Crear deployment "green" con la nueva versión
    echo "📦 Creando deployment ${NEW_COLOR} (${SERVICE}-${NEW_COLOR})..."
    
    # Obtener el deployment actual como base
    kubectl get deployment "${SERVICE}" -n "${NAMESPACE}" -o yaml > /tmp/${SERVICE}-current.yaml 2>/dev/null || {
        echo "⚠️  Deployment ${SERVICE} no existe, creando nuevo..."
        continue
    }
    
    # Crear deployment green/blue
    kubectl create deployment "${SERVICE}-${NEW_COLOR}" \
        --image="${DOCKER_USER}/${SERVICE}:${NEW_VERSION}" \
        --namespace="${NAMESPACE}" \
        --dry-run=client -o yaml | \
    kubectl label --local -f - -o yaml \
        app="${SERVICE}" \
        color="${NEW_COLOR}" \
        version="${NEW_VERSION}" | \
    kubectl apply -f -
    
    # Copiar configuración del deployment original (replicas, resources, etc.)
    REPLICAS=$(kubectl get deployment "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    kubectl scale deployment "${SERVICE}-${NEW_COLOR}" --replicas="${REPLICAS}" -n "${NAMESPACE}"
    
    # Esperar a que el deployment green/blue esté listo
    echo "⏳ Esperando a que ${SERVICE}-${NEW_COLOR} esté listo..."
    kubectl wait --for=condition=available deployment/"${SERVICE}-${NEW_COLOR}" \
        -n "${NAMESPACE}" \
        --timeout=600s || {
        echo "❌ Deployment ${SERVICE}-${NEW_COLOR} no se inició correctamente"
        kubectl delete deployment "${SERVICE}-${NEW_COLOR}" -n "${NAMESPACE}" || true
        continue
    }
    
    # Verificar health check
    echo "🔍 Verificando health check de ${SERVICE}-${NEW_COLOR}..."
    NEW_POD=$(kubectl get pod -l app="${SERVICE}",color="${NEW_COLOR}" -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$NEW_POD" ]; then
        # Intentar health check (ajustar puerto según el servicio)
        PORT=$(kubectl get deployment "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null || echo "8080")
        
        if kubectl exec -n "${NAMESPACE}" "${NEW_POD}" -- \
            curl -f "http://localhost:${PORT}/actuator/health" > /dev/null 2>&1; then
            echo "✅ Health check de ${SERVICE}-${NEW_COLOR} exitoso"
        else
            echo "⚠️  Health check de ${SERVICE}-${NEW_COLOR} falló, pero continuando..."
        fi
    fi
    
    # Cambiar el Service para apuntar a green/blue
    echo "🔄 Cambiando Service ${SERVICE} para apuntar a ${NEW_COLOR}..."
    kubectl patch service "${SERVICE}" -n "${NAMESPACE}" -p \
        "{\"spec\":{\"selector\":{\"app\":\"${SERVICE}\",\"color\":\"${NEW_COLOR}\"}}}"
    
    # Esperar un momento para que el tráfico se enrute
    sleep 10
    
    # Verificar que el servicio responde
    echo "✅ Verificando que el servicio responde correctamente..."
    sleep 5
    
    # Si todo está bien, eliminar el deployment antiguo
    if [ "$CURRENT_COLOR" = "blue" ]; then
        OLD_DEPLOYMENT="${BLUE_DEPLOYMENT}"
    else
        OLD_DEPLOYMENT="${GREEN_DEPLOYMENT}"
    fi
    
    echo "🧹 Eliminando deployment antiguo ${OLD_DEPLOYMENT}..."
    kubectl delete deployment "${OLD_DEPLOYMENT}" -n "${NAMESPACE}" || true
    
    # Actualizar el deployment principal para que apunte a la nueva versión
    echo "🔄 Actualizando deployment principal ${SERVICE}..."
    kubectl set image deployment/"${SERVICE}" \
        "${SERVICE}=${DOCKER_USER}/${SERVICE}:${NEW_VERSION}" \
        -n "${NAMESPACE}" || true
    
    # Actualizar labels del deployment principal
    kubectl label deployment "${SERVICE}" \
        color="${NEW_COLOR}" \
        version="${NEW_VERSION}" \
        -n "${NAMESPACE}" --overwrite || true
    
    echo "✅ Blue-Green Deployment completado para ${SERVICE}"
done

echo ""
echo "🎉 Blue-Green Deployment completado exitosamente en namespace ${NAMESPACE}"

