FROM maven:3.8-openjdk-17-slim AS build
WORKDIR /app

# Copiar POM padre y archivos Maven
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
RUN chmod +x mvnw

# Instalar POM padre en repositorio local
RUN mvn install -N -DskipTests

# Copiar POM del servicio
COPY shipping-service/pom.xml ./shipping-service/pom.xml

# Descargar dependencias del servicio
WORKDIR /app/shipping-service
RUN mvn dependency:go-offline -B || true

# Copiar código fuente del servicio
COPY shipping-service/src ./src

# Construir aplicación
RUN mvn clean package -DskipTests

# Imagen final
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app

# Instalar curl para health checks
RUN apk add --no-cache curl

# Copiar JAR desde etapa de build
COPY --from=build /app/shipping-service/target/*.jar app.jar

# Exponer puerto
EXPOSE 8085

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8085/actuator/health || exit 1

# Ejecutar aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
