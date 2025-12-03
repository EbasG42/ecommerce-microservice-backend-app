#!/bin/bash
# Script para ejecutar smoke tests después del despliegue
# Uso: ./smoke-tests.sh <namespace>

set -e

# Configurar PATH para incluir ubicaciones comunes de kubectl
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# Verificar que kubectl esté disponible
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl no está instalado o no está en el PATH"
    echo "Por favor, instala kubectl o agrega su ubicación al PATH"
    exit 1
fi

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
    local HEALTH_PATH=${3:-/actuator/health}
    
    echo "🔍 Verificando health de ${SERVICE}..."
    
    # Verificar que al menos un pod esté en estado Running
    READY_PODS=$(kubectl get pods -l app="${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$READY_PODS" ]; then
        # Intentar esperar a que al menos un pod esté listo
        kubectl wait --for=condition=ready pod \
            -l app="${SERVICE}" \
            -n "${NAMESPACE}" \
            --timeout=30s 2>/dev/null || {
            echo "❌ Pod de ${SERVICE} no está listo"
            return 1
        }
    fi
    
    # Verificar health endpoint usando port-forward al servicio
    # Usar un puerto local único basado en el puerto del servicio + offset
    # Esto evita conflictos cuando múltiples servicios usan el mismo puerto
    LOCAL_PORT=$((10000 + PORT))
    
    # Limpiar cualquier port-forward anterior en el mismo puerto
    pkill -f "port-forward.*${LOCAL_PORT}" 2>/dev/null || true
    sleep 1
    
    # Iniciar port-forward al servicio (más confiable que al pod)
    kubectl port-forward -n "${NAMESPACE}" "svc/${SERVICE}" "${LOCAL_PORT}:${PORT}" > /dev/null 2>&1 &
    PF_PID=$!
    
    # Esperar a que el port-forward esté listo
    # Algunos servicios necesitan más tiempo para iniciar
    sleep 8
    
    # Verificar health endpoint con múltiples intentos
    HEALTH_CHECK_RESULT=1
    for i in {1..5}; do
        if curl -sf --max-time 5 "http://localhost:${LOCAL_PORT}${HEALTH_PATH}" > /dev/null 2>&1; then
            HEALTH_CHECK_RESULT=0
            break
        fi
        sleep 2
    done
    
    # Limpiar port-forward
    kill $PF_PID 2>/dev/null || true
    wait $PF_PID 2>/dev/null || true
    sleep 1
    
    if [ $HEALTH_CHECK_RESULT -eq 0 ]; then
        echo "✅ Health check de ${SERVICE} exitoso"
        return 0
    else
        echo "❌ Health check de ${SERVICE} falló"
        return 1
    fi
}

# Lista de servicios a verificar con sus context paths
# Formato: "service-name:port:context-path"
# Si no se especifica context-path, se usa /actuator/health
SERVICES=(
    "service-discovery:8761:/actuator/health"
    "cloud-config-server:8888:/actuator/health"
    "api-gateway:8080:/actuator/health"
    "user-service:8081:/user-service/actuator/health"
    "product-service:8082:/product-service/actuator/health"
    "favourite-service:8083:/favourite-service/actuator/health"
    "order-service:8084:/order-service/actuator/health"
    "shipping-service:8085:/shipping-service/actuator/health"
    "payment-service:8086:/payment-service/actuator/health"
)

FAILED_TESTS=0

for SERVICE_PORT_PATH in "${SERVICES[@]}"; do
    SERVICE=$(echo "$SERVICE_PORT_PATH" | cut -d: -f1)
    PORT=$(echo "$SERVICE_PORT_PATH" | cut -d: -f2)
    HEALTH_PATH=$(echo "$SERVICE_PORT_PATH" | cut -d: -f3)
    # Si no se especificó HEALTH_PATH, usar el default
    HEALTH_PATH=${HEALTH_PATH:-/actuator/health}
    
    if ! check_health "$SERVICE" "$PORT" "$HEALTH_PATH"; then
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

