#!/bin/bash

# Script para instalar KEDA en el cluster

set -e

NAMESPACE="keda"

echo "=========================================="
echo "INSTALANDO KEDA"
echo "=========================================="
echo ""

# Verificar que Helm esté instalado
if ! command -v helm &> /dev/null; then
    echo "❌ Helm no está instalado"
    echo "Instalar Helm desde: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Agregar repositorio de KEDA
echo "📚 Agregando repositorio de Helm para KEDA..."
helm repo add kedacore https://kedacore.github.io/charts || true
helm repo update

# Crear namespace
echo "📦 Creando namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Instalar KEDA
echo "🚀 Instalando KEDA..."
helm upgrade --install keda kedacore/keda \
    --namespace $NAMESPACE \
    --version 2.13.0 \
    --wait --timeout=5m

echo ""
echo "⏳ Esperando a que KEDA esté listo..."
kubectl wait --for=condition=ready pod -l app=keda-operator -n $NAMESPACE --timeout=5m || true
kubectl wait --for=condition=ready pod -l app=keda-operator-metrics-apiserver -n $NAMESPACE --timeout=5m || true

echo ""
echo "✅ KEDA instalado exitosamente!"
echo ""
echo "Verificar estado:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""

