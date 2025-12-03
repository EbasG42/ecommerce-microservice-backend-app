#!/bin/bash
# Script para ejecutar smoke tests después del despliegue
# Uso: ./smoke-tests.sh <namespace>

set -e

NAMESPACE="${1:-dev}"

if [ -z "$NAMESPACE" ]; then
    echo "Uso: $0 <namespace>"
    echo "Ejemplo: $0 dev"
    exit 1
fi

echo "🧪 Ejecutando smoke tests en namespace ${NAMESPACE}..."

# Función para verificar health endpoint
check_health() {
    local SERVICE=$1
    local PORT=${2:-8080}
    local PATH=${3:-/actuator/health}
    
    echo "🔍 Verificando health de ${SERVICE}..."
    
    # Esperar a que el pod esté listo
    kubectl wait --for=condition=ready pod \
        -l app="${SERVICE}" \
        -n "${NAMESPACE}" \
        --timeout=120s || {
        echo "❌ Pod de ${SERVICE} no está listo"
        return 1
    }
    
    # Obtener un pod
    POD=$(kubectl get pod -l app="${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$POD" ]; then
        echo "❌ No se encontró pod para ${SERVICE}"
        return 1
    fi
    
    # Verificar health endpoint
    if kubectl exec -n "${NAMESPACE}" "${POD}" -- \
        curl -f "http://localhost:${PORT}${PATH}" > /dev/null 2>&1; then
        echo "✅ Health check de ${SERVICE} exitoso"
        return 0
    else
        echo "❌ Health check de ${SERVICE} falló"
        return 1
    fi
}

# Lista de servicios a verificar
SERVICES=(
    "service-discovery:8761"
    "cloud-config-server:8888"
    "api-gateway:8080"
    "user-service:8081"
    "product-service:8082"
    "favourite-service:8083"
    "order-service:8084"
    "shipping-service:8085"
    "payment-service:8086"
)

FAILED_TESTS=0

for SERVICE_PORT in "${SERVICES[@]}"; do
    SERVICE=$(echo "$SERVICE_PORT" | cut -d: -f1)
    PORT=$(echo "$SERVICE_PORT" | cut -d: -f2)
    
    if ! check_health "$SERVICE" "$PORT"; then
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
done

# Verificar registro en Eureka
echo ""
echo "🔍 Verificando registro en Eureka..."
EUREKA_POD=$(kubectl get pod -l app=service-discovery -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$EUREKA_POD" ]; then
    # Port-forward temporal a Eureka
    kubectl port-forward -n "${NAMESPACE}" "pod/${EUREKA_POD}" 8761:8761 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 5
    
    # Verificar servicios registrados
    REGISTERED_SERVICES=$(curl -s http://localhost:8761/eureka/apps 2>/dev/null | grep -o '<name>[^<]*</name>' | wc -l || echo "0")
    
    kill $PF_PID 2>/dev/null || true
    
    if [ "$REGISTERED_SERVICES" -gt "1" ]; then
        echo "✅ Eureka tiene ${REGISTERED_SERVICES} servicios registrados"
    else
        echo "⚠️  Eureka tiene pocos servicios registrados (${REGISTERED_SERVICES})"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo "⚠️  No se pudo verificar Eureka"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Resumen
echo ""
if [ "$FAILED_TESTS" -eq 0 ]; then
    echo "✅ Todos los smoke tests pasaron exitosamente"
    exit 0
else
    echo "❌ ${FAILED_TESTS} smoke test(s) fallaron"
    exit 1
fi

