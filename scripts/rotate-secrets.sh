#!/bin/bash
# Script para rotar secretos de base de datos
# Uso: ./rotate-secrets.sh <service-name> <new-username> <new-password>

set -e

NAMESPACE="dev"
SERVICE_NAME="$1"
NEW_USERNAME="$2"
NEW_PASSWORD="$3"

if [ -z "$SERVICE_NAME" ] || [ -z "$NEW_USERNAME" ] || [ -z "$NEW_PASSWORD" ]; then
    echo "Uso: $0 <service-name> <new-username> <new-password>"
    echo "Ejemplo: $0 user-service newuser newpass123"
    exit 1
fi

SECRET_NAME="${SERVICE_NAME}-secret"

echo "🔄 Rotando secretos para ${SERVICE_NAME}..."

# Actualizar el secret
kubectl create secret generic "${SECRET_NAME}" \
    --from-literal=database.username="${NEW_USERNAME}" \
    --from-literal=database.password="${NEW_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f - -n "${NAMESPACE}"

echo "✅ Secret actualizado: ${SECRET_NAME}"

# Reiniciar el deployment para que use el nuevo secret
echo "🔄 Reiniciando deployment ${SERVICE_NAME}..."
kubectl rollout restart deployment/"${SERVICE_NAME}" -n "${NAMESPACE}"

echo "⏳ Esperando a que el deployment se reinicie..."
kubectl rollout status deployment/"${SERVICE_NAME}" -n "${NAMESPACE}" --timeout=300s

echo "✅ Rotación de secretos completada para ${SERVICE_NAME}"

