#!/bin/bash
# Script de Health Check
# E-Commerce Microservices Platform

NAMESPACE=${1:-dev}

echo "🏥 Health Check - Namespace: $NAMESPACE"
echo "========================================"
echo ""

# Verificar pods
echo "📦 Estado de Pods:"
kubectl get pods -n $NAMESPACE --no-headers | awk '{
    status=$3; 
    if(status!="Running" && status!="Completed") 
        print "  ❌ "$1" - "$3; 
    else 
        print "  ✅ "$1" - "$3
}'

echo ""

# Verificar servicios
echo "🌐 Servicios Expuestos:"
kubectl get svc -n $NAMESPACE --no-headers | awk '{print "  - "$1" ("$2") - "$5}'

echo ""

# Verificar HPA
echo "📊 Autoscaling Status:"
kubectl get hpa -n $NAMESPACE --no-headers 2>/dev/null | awk '{
    print "  - "$1": "$3"/"$4" réplicas (CPU: "$5")"
}' || echo "  No HPAs configurados"

echo ""

# Verificar eventos recientes
echo "📋 Eventos Recientes (últimos 10):"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

echo ""
echo "✅ Health check completado"
