#!/bin/bash
# Script para instalar el stack completo de observabilidad
# Incluye: Prometheus, Grafana, Loki, Jaeger

set -e

NAMESPACE_MONITORING="${NAMESPACE_MONITORING:-monitoring}"
NAMESPACE_LOGGING="${NAMESPACE_LOGGING:-logging}"
NAMESPACE_TRACING="${NAMESPACE_TRACING:-tracing}"

echo "🔍 Instalando stack completo de Observabilidad y Monitoreo..."

# Crear namespaces
echo "📦 Creando namespaces..."
kubectl apply -f k8s/monitoring/namespace.yaml

# Agregar repositorios de Helm
echo "📚 Agregando repositorios de Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Instalar Prometheus Stack
echo "📊 Instalando Prometheus Stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE_MONITORING \
  --create-namespace \
  --values k8s/monitoring/prometheus-operator-values.yaml \
  --wait --timeout=10m

# Aplicar ServiceMonitors
echo "📡 Aplicando ServiceMonitors..."
kubectl apply -f k8s/monitoring/service-monitors.yaml

# Aplicar PrometheusRules
echo "🚨 Aplicando PrometheusRules..."
kubectl apply -f k8s/monitoring/prometheus-rules.yaml

# Instalar Loki Stack
echo "📝 Instalando Loki Stack..."
helm upgrade --install loki grafana/loki-stack \
  --namespace $NAMESPACE_LOGGING \
  --create-namespace \
  --values k8s/monitoring/loki-values.yaml \
  --wait --timeout=10m

# Instalar Jaeger Operator
echo "🔎 Instalando Jaeger Operator..."
helm upgrade --install jaeger-operator jaegertracing/jaeger-operator \
  --namespace $NAMESPACE_TRACING \
  --create-namespace \
  --values k8s/monitoring/jaeger-values.yaml \
  --wait --timeout=10m

# Aplicar instancia de Jaeger
echo "🔎 Creando instancia de Jaeger..."
kubectl apply -f k8s/monitoring/jaeger-instance.yaml

# Esperar a que Jaeger esté listo
echo "⏳ Esperando a que Jaeger esté listo..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jaeger -n $NAMESPACE_TRACING --timeout=5m || true

echo ""
echo "✅ Stack de Observabilidad instalado exitosamente!"
echo ""
echo "📊 Acceso a Grafana (Prometheus):"
echo "   kubectl port-forward -n $NAMESPACE_MONITORING svc/prometheus-grafana 3000:80"
echo "   Usuario: admin"
echo "   Contraseña: admin123"
echo ""
echo "📝 Acceso a Grafana (Loki):"
echo "   kubectl port-forward -n $NAMESPACE_LOGGING svc/loki-grafana 3001:80"
echo "   Usuario: admin"
echo "   Contraseña: admin123"
echo ""
echo "🔎 Acceso a Jaeger UI:"
echo "   kubectl port-forward -n $NAMESPACE_TRACING svc/jaeger-query 16686:16686"
echo "   URL: http://localhost:16686"
echo ""
echo "📈 Acceso a Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE_MONITORING svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""

