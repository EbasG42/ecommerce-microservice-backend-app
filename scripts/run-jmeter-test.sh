#!/bin/bash

# Script para ejecutar pruebas de carga con JMeter
# Uso: ./scripts/run-jmeter-test.sh [host] [port] [threads] [duration]

HOST=${1:-"localhost"}
PORT=${2:-8080}
THREADS=${3:-10}
DURATION=${4:-300}

echo "=========================================="
echo "PRUEBA DE CARGA CON JMETER - E-COMMERCE"
echo "=========================================="
echo ""
echo "Host: $HOST"
echo "Port: $PORT"
echo "Threads: $THREADS"
echo "Duración: ${DURATION}s"
echo ""

# Verificar que JMeter esté instalado
if ! command -v jmeter &> /dev/null; then
    echo "❌ JMeter no está instalado"
    echo "Instalar JMeter desde: https://jmeter.apache.org/download_jmeter.cgi"
    exit 1
fi

# Verificar que el archivo de test plan existe
if [ ! -f "tests/jmeter-test-plan.jmx" ]; then
    echo "❌ Archivo tests/jmeter-test-plan.jmx no encontrado"
    exit 1
fi

# Crear directorio de reportes si no existe
mkdir -p reports

echo "🚀 Iniciando prueba de carga con JMeter..."
echo ""

# Ejecutar JMeter en modo no-GUI
jmeter -n \
    -t tests/jmeter-test-plan.jmx \
    -JHOST="$HOST" \
    -JPORT="$PORT" \
    -JTHREADS="$THREADS" \
    -JDURATION="$DURATION" \
    -l reports/jmeter-results.jtl \
    -e -o reports/jmeter-report

echo ""
echo "✅ Prueba de carga completada"
echo "📊 Reporte generado en: reports/jmeter-report/index.html"

