#!/bin/bash
# Script para realizar rollback de deployments
# Uso: ./rollback.sh <namespace> [service-name]

set -e

NAMESPACE="${1:-dev}"
SERVICE_NAME="$2"

if [ -z "$NAMESPACE" ]; then
    echo "Uso: $0 <namespace> [service-name]"
    echo "Ejemplo: $0 prod user-service"
    exit 1
fi

echo "🔄 Iniciando rollback en namespace ${NAMESPACE}..."

if [ -n "$SERVICE_NAME" ]; then
    # Rollback de un servicio específico
    SERVICES=("$SERVICE_NAME")
else
    # Rollback de todos los servicios
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
fi

for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "🔄 Procesando rollback de ${SERVICE}..."
    
    # Verificar si el deployment existe
    if ! kubectl get deployment "${SERVICE}" -n "${NAMESPACE}" > /dev/null 2>&1; then
        echo "⚠️  Deployment ${SERVICE} no existe en namespace ${NAMESPACE}, saltando..."
        continue
    fi
    
    # Obtener el historial de revisions
    echo "📋 Historial de revisions de ${SERVICE}:"
    kubectl rollout history deployment/"${SERVICE}" -n "${NAMESPACE}"
    
    # Obtener la última revisión que funcionaba (antes de la actual)
    LAST_REVISION=$(kubectl rollout history deployment/"${SERVICE}" -n "${NAMESPACE}" | \
        grep -v "REVISION" | tail -2 | head -1 | awk '{print $1}' || echo "")
    
    if [ -z "$LAST_REVISION" ]; then
        echo "⚠️  No se encontró una revisión anterior para ${SERVICE}"
        continue
    fi
    
    echo "🔄 Haciendo rollback a la revisión ${LAST_REVISION}..."
    
    # Realizar rollback
    kubectl rollout undo deployment/"${SERVICE}" \
        --to-revision="${LAST_REVISION}" \
        -n "${NAMESPACE}"
    
    # Esperar a que el rollback se complete
    echo "⏳ Esperando a que el rollback se complete..."
    kubectl rollout status deployment/"${SERVICE}" -n "${NAMESPACE}" --timeout=600s || {
        echo "❌ Rollback de ${SERVICE} falló"
        continue
    }
    
    echo "✅ Rollback completado para ${SERVICE}"
done

echo ""
echo "🎉 Rollback completado en namespace ${NAMESPACE}"

