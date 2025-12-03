#!/bin/bash
# Script optimizado para instalar el stack de observabilidad en Minikube
# Versión ligera con recursos reducidos

set -e

NAMESPACE_MONITORING="${NAMESPACE_MONITORING:-monitoring}"
NAMESPACE_LOGGING="${NAMESPACE_LOGGING:-logging}"
NAMESPACE_TRACING="${NAMESPACE_TRACING:-tracing}"

echo "🔍 Instalando stack de Observabilidad (versión optimizada para Minikube)..."

# Crear namespaces
echo "📦 Creando namespaces..."
kubectl apply -f k8s/monitoring/namespace.yaml

# Agregar repositorios de Helm
echo "📚 Agregando repositorios de Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts 2>/dev/null || true
helm repo update

# Instalar Prometheus Stack (versión ligera)
echo "📊 Instalando Prometheus Stack (esto puede tardar varios minutos)..."
echo "   Usando configuración optimizada para Minikube..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE_MONITORING \
  --create-namespace \
  --values k8s/monitoring/prometheus-operator-values-minikube.yaml \
  --timeout=20m \
  --wait=false

echo ""
echo "⏳ Prometheus Stack se está instalando en segundo plano..."
echo "   Puedes verificar el progreso con: kubectl get pods -n monitoring -w"
echo ""

# Esperar un poco antes de continuar
sleep 30

# Aplicar ServiceMonitors
echo "📡 Aplicando ServiceMonitors..."
kubectl apply -f k8s/monitoring/service-monitors.yaml || echo "⚠️  Algunos ServiceMonitors pueden fallar si Prometheus aún no está listo"

# Aplicar PrometheusRules
echo "🚨 Aplicando PrometheusRules..."
kubectl apply -f k8s/monitoring/prometheus-rules.yaml || echo "⚠️  PrometheusRules pueden fallar si Prometheus aún no está listo"

# Instalar Loki Stack (versión ligera)
echo ""
echo "📝 Instalando Loki Stack (versión ligera)..."
helm upgrade --install loki grafana/loki-stack \
  --namespace $NAMESPACE_LOGGING \
  --create-namespace \
  --set loki.persistence.enabled=false \
  --set loki.resources.requests.memory=256Mi \
  --set loki.resources.requests.cpu=200m \
  --set loki.resources.limits.memory=512Mi \
  --set loki.resources.limits.cpu=500m \
  --set promtail.enabled=true \
  --set grafana.enabled=false \
  --timeout=10m \
  --wait=false

echo "⏳ Loki Stack se está instalando en segundo plano..."

# Instalar cert-manager (requerido para Jaeger)
echo ""
echo "🔐 Instalando cert-manager (requerido para Jaeger)..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
echo "⏳ Esperando a que cert-manager esté listo (30 segundos)..."
sleep 30

# Instalar Jaeger Operator (versión ligera)
echo ""
echo "🔎 Instalando Jaeger Operator..."
helm upgrade --install jaeger-operator jaegertracing/jaeger-operator \
  --namespace $NAMESPACE_TRACING \
  --create-namespace \
  --set operator.resources.requests.memory=128Mi \
  --set operator.resources.requests.cpu=100m \
  --set operator.resources.limits.memory=256Mi \
  --set operator.resources.limits.cpu=200m \
  --timeout=10m \
  --wait=false

# Aplicar instancia de Jaeger
echo "🔎 Creando instancia de Jaeger..."
kubectl apply -f k8s/monitoring/jaeger-instance.yaml || echo "⚠️  Jaeger puede fallar si el operator aún no está listo"

echo ""
echo "✅ Instalación iniciada. Los componentes se están desplegando en segundo plano."
echo ""
echo "📊 Para verificar el estado:"
echo "   kubectl get pods -n monitoring"
echo "   kubectl get pods -n logging"
echo "   kubectl get pods -n tracing"
echo ""
echo "⏳ Espera 5-10 minutos para que todos los pods estén listos."
echo ""
echo "📊 Acceso a Grafana (cuando esté listo):"
echo "   kubectl port-forward -n $NAMESPACE_MONITORING svc/prometheus-grafana 3000:80"
echo "   Usuario: admin"
echo "   Contraseña: admin123"
echo ""
echo "🔎 Acceso a Jaeger UI (cuando esté listo):"
echo "   kubectl port-forward -n $NAMESPACE_TRACING svc/jaeger-query 16686:16686"
echo "   URL: http://localhost:16686"
echo ""
echo "📈 Acceso a Prometheus (cuando esté listo):"
echo "   kubectl port-forward -n $NAMESPACE_MONITORING svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""

