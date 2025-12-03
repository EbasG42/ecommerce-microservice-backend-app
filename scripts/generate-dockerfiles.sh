#!/bin/bash

echo "📝 Generando/Actualizando Dockerfiles para todos los servicios..."
echo ""

# Servicios con sus puertos correspondientes
declare -A SERVICES_PORTS=(
    ["service-discovery"]="8761"
    ["cloud-config"]="8888"
    ["api-gateway"]="8080"
    ["proxy-client"]="4200"
    ["user-service"]="8081"
    ["product-service"]="8082"
    ["favourite-service"]="8083"
    ["order-service"]="8084"
    ["shipping-service"]="8085"
    ["payment-service"]="8086"
)

UPDATED=0
CREATED=0
SKIPPED=0

for SERVICE in "${!SERVICES_PORTS[@]}"; do
    PORT="${SERVICES_PORTS[$SERVICE]}"
    
    if [ ! -d "$SERVICE" ]; then
        echo "⏭️  Saltando $SERVICE (directorio no existe)"
        ((SKIPPED++))
        continue
    fi
    
    # Backup si existe Dockerfile
    if [ -f "$SERVICE/Dockerfile" ]; then
        cp "$SERVICE/Dockerfile" "$SERVICE/Dockerfile.backup.$(date +%Y%m%d_%H%M%S)"
        echo "📝 Actualizando Dockerfile para $SERVICE (puerto $PORT)..."
        ((UPDATED++))
    else
        echo "✨ Creando Dockerfile para $SERVICE (puerto $PORT)..."
        ((CREATED++))
    fi
    
    # Crear Dockerfile optimizado
    cat > "$SERVICE/Dockerfile" <<DOCKERFILE_EOF
# Multi-stage build para optimizar tamaño e imagen
FROM maven:3.8.6-openjdk-17-slim AS build
WORKDIR /app

# Copiar pom.xml y descargar dependencias (capa cacheada)
COPY pom.xml .
RUN mvn dependency:go-offline -B || true

# Copiar código fuente y construir
COPY src ./src
RUN mvn clean package -DskipTests

# Imagen runtime optimizada y segura
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Instalar wget para health checks
RUN apk add --no-cache wget

# Crear usuario no-root para seguridad
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copiar JAR desde build stage
COPY --from=build /app/target/*.jar app.jar

# Variables de entorno
ENV SPRING_PROFILES_ACTIVE=kubernetes
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Health check para Kubernetes
HEALTHCHECK --interval=30s --timeout=3s --start-period=90s --retries=3 \\
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/actuator/health || exit 1

EXPOSE ${PORT}

# Entrypoint optimizado
ENTRYPOINT ["sh", "-c", "java \${JAVA_OPTS} -jar app.jar"]
DOCKERFILE_EOF
    
    echo "   ✅ Dockerfile creado/actualizado en $SERVICE/"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Creados: $CREATED"
echo "📝 Actualizados: $UPDATED"
echo "⏭️  Saltados: $SKIPPED"
echo ""
echo "🎉 Proceso completado!"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Revisar los Dockerfiles generados"
echo "   2. Construir imágenes con: ./build-images.sh"
echo "   3. O pushear a Docker Hub: ./build-images.sh true"
