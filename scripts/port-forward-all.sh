#!/bin/bash
# Port Forwarding para todos los servicios
# E-Commerce Microservices

echo "🚀 Iniciando port-forwarding para todos los servicios..."
echo "⚠️  Presiona Ctrl+C para detener todos"
echo ""

# Service Discovery
kubectl port-forward -n dev svc/service-discovery 8761:8761 > /dev/null 2>&1 &
PF1=$!

# API Gateway
kubectl port-forward -n dev svc/api-gateway 8080:8080 > /dev/null 2>&1 &
PF2=$!

# Cloud Config
kubectl port-forward -n dev svc/cloud-config-server 8888:8888 > /dev/null 2>&1 &
PF3=$!

# User Service
kubectl port-forward -n dev svc/user-service 8081:8081 > /dev/null 2>&1 &
PF4=$!

# Product Service
kubectl port-forward -n dev svc/product-service 8082:8082 > /dev/null 2>&1 &
PF5=$!

# Order Service
kubectl port-forward -n dev svc/order-service 8084:8084 > /dev/null 2>&1 &
PF6=$!

# Proxy Client
kubectl port-forward -n dev svc/proxy-client 4200:4200 > /dev/null 2>&1 &
PF7=$!

sleep 2

echo "✅ Port-forwarding activo:"
echo "  - Service Discovery: http://localhost:8761"
echo "  - API Gateway: http://localhost:8080"
echo "  - Cloud Config: http://localhost:8888"
echo "  - User Service: http://localhost:8081"
echo "  - Product Service: http://localhost:8082"
echo "  - Order Service: http://localhost:8084"
echo "  - Proxy Client: http://localhost:4200"
echo ""
echo "Presiona Ctrl+C para detener..."

trap "kill $PF1 $PF2 $PF3 $PF4 $PF5 $PF6 $PF7 2>/dev/null; exit" INT
wait

