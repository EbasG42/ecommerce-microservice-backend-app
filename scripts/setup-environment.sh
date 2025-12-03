#!/bin/bash

set -e

echo "🚀 Setup del Entorno E-Commerce Microservices"
echo "=============================================="
echo ""

# Verificar prerequisitos
echo "📋 Verificando prerequisitos..."

command -v docker >/dev/null 2>&1 || { echo "❌ Docker no instalado"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl no instalado"; exit 1; }
command -v minikube >/dev/null 2>&1 || { echo "❌ Minikube no instalado"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm no instalado"; exit 1; }

echo "✅ Todos los prerequisitos instalados"
echo ""

# Limpiar ambiente anterior si existe
echo "🧹 Limpiando ambiente anterior..."
minikube delete --all 2>/dev/null || true
docker system prune -f

echo ""
echo "🎯 Iniciando Minikube..."
minikube start \
  --cpus=4 \
  --memory=4500 \
  --disk-size=50g \
  --driver=docker

echo ""
echo "🔌 Habilitando addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

echo ""
echo "📦 Configurando Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

echo ""
echo "🏗️  Creando namespaces..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace qa --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "🌐 Configurando hosts locales..."
MINIKUBE_IP=$(minikube ip)
echo ""
echo "💡 Agrega estas líneas a tu /etc/hosts:"
echo "   $MINIKUBE_IP ecommerce.local api.ecommerce.local"
echo ""
echo "   Ejecuta: echo '$MINIKUBE_IP ecommerce.local api.ecommerce.local' | sudo tee -a /etc/hosts"

echo ""
echo "✅ Setup completado exitosamente!"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Generar Dockerfiles: ./scripts/generate-dockerfiles.sh"
echo "   2. Construir imágenes: ./build-images.sh"
echo "   3. Continuar con deployments en Kubernetes"
