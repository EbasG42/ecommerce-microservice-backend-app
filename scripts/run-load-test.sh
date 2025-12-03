#!/bin/bash

# Script para ejecutar pruebas de carga con Locust
# Uso: ./scripts/run-load-test.sh [host] [users] [spawn-rate] [duration]

HOST=${1:-"http://localhost:8080"}
USERS=${2:-10}
SPAWN_RATE=${3:-2}
DURATION=${4:-"5m"}

echo "=========================================="
echo "PRUEBA DE CARGA - E-COMMERCE"
echo "=========================================="
echo ""
echo "Host: $HOST"
echo "Usuarios: $USERS"
echo "Spawn Rate: $SPAWN_RATE usuarios/segundo"
echo "Duración: $DURATION"
echo ""

# Verificar que Locust esté instalado
if ! command -v locust &> /dev/null; then
    echo "❌ Locust no está instalado"
    echo "Instalar con: pip install locust"
    exit 1
fi

# Verificar que el archivo locustfile.py existe
if [ ! -f "tests/locustfile.py" ]; then
    echo "❌ Archivo tests/locustfile.py no encontrado"
    exit 1
fi

echo "🚀 Iniciando prueba de carga..."
echo ""
echo "Abre tu navegador en: http://localhost:8089"
echo ""
echo "Presiona Ctrl+C para detener la prueba"
echo ""

# Ejecutar Locust
locust -f tests/locustfile.py \
    --host="$HOST" \
    --users="$USERS" \
    --spawn-rate="$SPAWN_RATE" \
    --run-time="$DURATION" \
    --headless \
    --html=reports/locust-report.html \
    --csv=reports/locust-stats

echo ""
echo "✅ Prueba de carga completada"
echo "📊 Reporte generado en: reports/locust-report.html"

