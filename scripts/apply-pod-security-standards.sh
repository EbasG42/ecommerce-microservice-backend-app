#!/bin/bash
# Script para aplicar Pod Security Standards a todos los deployments
# Este script actualiza los deployments existentes con security contexts

set -e

NAMESPACE="dev"

echo "🔒 Aplicando Pod Security Standards a deployments en namespace $NAMESPACE..."

# Lista de servicios
SERVICES=(
  "api-gateway"
  "user-service"
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "favourite-service"
  "service-discovery"
  "cloud-config-server"
  "proxy-client"
)

for service in "${SERVICES[@]}"; do
  echo "  📝 Actualizando $service..."
  
  # Aplicar security context a nivel de pod
  kubectl patch deployment "$service" -n "$NAMESPACE" --type='json' -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/securityContext",
      "value": {
        "runAsNonRoot": true,
        "runAsUser": 1000,
        "fsGroup": 1000,
        "seccompProfile": {
          "type": "RuntimeDefault"
        }
      }
    }
  ]' || echo "    ⚠️  No se pudo actualizar securityContext de pod para $service"
  
  # Obtener el nombre del contenedor (generalmente el mismo que el servicio)
  CONTAINER_NAME="$service"
  
  # Aplicar security context a nivel de container
  kubectl patch deployment "$service" -n "$NAMESPACE" --type='json' -p="[
    {
      \"op\": \"add\",
      \"path\": \"/spec/template/spec/containers/0/securityContext\",
      \"value\": {
        \"allowPrivilegeEscalation\": false,
        \"readOnlyRootFilesystem\": true,
        \"capabilities\": {
          \"drop\": [\"ALL\"]
        }
      }
    }
  ]" || echo "    ⚠️  No se pudo actualizar securityContext de container para $service"
  
  # Agregar ServiceAccount si existe
  SERVICE_ACCOUNT="${service}-sa"
  if kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" &>/dev/null; then
    kubectl patch deployment "$service" -n "$NAMESPACE" --type='json' -p="[
      {
        \"op\": \"add\",
        \"path\": \"/spec/template/spec/serviceAccountName\",
        \"value\": \"$SERVICE_ACCOUNT\"
      }
    ]" || echo "    ⚠️  No se pudo actualizar serviceAccountName para $service"
  fi
  
  echo "    ✅ $service actualizado"
done

echo ""
echo "✅ Pod Security Standards aplicados a todos los deployments"
echo ""
echo "⚠️  NOTA: Algunos servicios pueden requerir ajustes adicionales:"
echo "   - Volúmenes temporales para directorios de escritura"
echo "   - Verificar que las aplicaciones funcionen con readOnlyRootFilesystem"
echo "   - Ajustar runAsUser si es necesario"

