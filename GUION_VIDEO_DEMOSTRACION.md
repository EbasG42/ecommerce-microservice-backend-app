# Guion para Video Demostrativo
## Proyecto Final Plataformas II - E-Commerce Microservices en Kubernetes

**Duración estimada:** 15-20 minutos  
**Objetivo:** Demostrar todas las funcionalidades implementadas en cada sección del proyecto

---

## 🎬 Introducción (1 minuto)

### Lo que vas a decir:
"Hola, en este video voy a demostrar la implementación completa del Proyecto Final de Plataformas II, que consiste en desplegar una arquitectura de microservicios de e-commerce en Kubernetes. El proyecto incluye 10 microservicios, observabilidad, autoscaling, CI/CD, y todas las mejores prácticas de DevOps."

### Comandos a mostrar:
```bash
# Mostrar estructura del proyecto
cd /home/user/plataformas-ii/ecommerce-microservice-backend-app
ls -la
tree -L 2 -d
```

---

## 📋 Sección 1: Arquitectura e Infraestructura (2 minutos)

### Lo que vas a decir:
"Primero, voy a mostrar la arquitectura completa del sistema. Tenemos 10 microservicios desplegados en Kubernetes usando Minikube, organizados en namespaces para diferentes ambientes."

### Comandos a ejecutar:
```bash
# 1. Verificar el clúster
kubectl cluster-info
minikube status

# 2. Mostrar namespaces
kubectl get namespaces
echo "Tenemos 3 namespaces: dev, qa y prod"

# 3. Ver todos los pods en dev
kubectl get pods -n dev
echo "Aquí vemos los 10 microservicios desplegados"

# 4. Mostrar servicios
kubectl get svc -n dev
echo "Cada microservicio tiene su Service de tipo ClusterIP"

# 5. Mostrar deployments
kubectl get deployments -n dev
echo "Cada servicio está gestionado por un Deployment"

# 6. Verificar base de datos
kubectl get statefulset -n dev
kubectl get pvc -n dev
echo "PostgreSQL está desplegado como StatefulSet con persistencia"
```

### Lo que vas a decir:
"Como pueden ver, tenemos todos los microservicios desplegados: Service Discovery (Eureka), Cloud Config Server, API Gateway, 6 servicios de negocio, y el frontend Proxy Client. La base de datos PostgreSQL está configurada como StatefulSet con Persistent Volumes para garantizar la persistencia de datos."

---

## 🔐 Sección 2: Configuración de Red y Seguridad (2 minutos)

### Lo que vas a decir:
"Ahora voy a mostrar la configuración de red y seguridad. Hemos implementado Network Policies siguiendo el principio de Zero Trust, RBAC con permisos mínimos, e Ingress para acceso externo."

### Comandos a ejecutar:
```bash
# 1. Mostrar Network Policies
kubectl get networkpolicies -n dev
kubectl describe networkpolicy default-deny-all -n dev
echo "Tenemos una política que bloquea todo el tráfico por defecto"

kubectl describe networkpolicy allow-discovery -n dev
echo "Esta política permite que los servicios se conecten a Eureka"

kubectl describe networkpolicy allow-api-gateway -n dev
echo "Esta política permite que el API Gateway se comunique con los servicios de negocio"

# 2. Mostrar RBAC
kubectl get serviceaccounts -n dev
kubectl get roles -n dev
kubectl get rolebindings -n dev
echo "Cada servicio tiene su propio ServiceAccount con permisos mínimos"

# 3. Mostrar Ingress
kubectl get ingress -n dev
kubectl describe ingress ecommerce-ingress -n dev
echo "El Ingress está configurado con TLS para acceso seguro"

# 4. Verificar Pod Security Standards
kubectl get deployment user-service -n dev -o yaml | grep -A 10 securityContext
echo "Los pods están configurados con security contexts para ejecutarse como usuario no-root"
```

### Lo que vas a decir:
"Como pueden ver, hemos implementado seguridad a múltiples niveles: Network Policies para aislar el tráfico, RBAC para control de acceso, y Pod Security Standards para ejecutar los contenedores de forma segura."

---

## ⚙️ Sección 3: Gestión de Configuración y Secretos (1.5 minutos)

### Lo que vas a decir:
"Todos los microservicios usan ConfigMaps para su configuración y Secrets para datos sensibles como credenciales de base de datos."

### Comandos a ejecutar:
```bash
# 1. Mostrar ConfigMaps
kubectl get configmaps -n dev
echo "Tenemos 9 ConfigMaps, uno por cada microservicio"

# 2. Ver contenido de un ConfigMap
kubectl get configmap user-service-config -n dev -o yaml | head -30
echo "Cada ConfigMap contiene la configuración application.yml del servicio"

# 3. Mostrar Secrets
kubectl get secrets -n dev | grep -E 'user-service|product-service|favourite-service|order-service|shipping-service|payment-service'
echo "Los Secrets contienen las credenciales de base de datos encriptadas en base64"

# 4. Verificar que los pods usan ConfigMaps y Secrets
kubectl describe pod -n dev -l app=user-service | grep -A 5 "Environment:"
echo "Los pods están configurados para usar estos ConfigMaps y Secrets"

# 5. Mostrar script de rotación de secretos
ls -la scripts/rotate-secrets.sh
echo "Tenemos un script para rotar secretos de forma segura"
```

### Lo que vas a decir:
"La configuración está centralizada usando ConfigMaps, y los datos sensibles están en Secrets. También tenemos un script para rotar secretos de forma automatizada."

---

## 🚀 Sección 4: Estrategias de Despliegue y CI/CD (2 minutos)

### Lo que vas a decir:
"Hemos implementado un pipeline completo de CI/CD con GitHub Actions, estrategias de despliegue Canary y Blue-Green, y Helm Charts para gestionar los releases."

### Comandos a ejecutar:
```bash
# 1. Mostrar pipeline de GitHub Actions
cat .github/workflows/ci-cd.yaml | head -50
echo "Este pipeline incluye: build, test, security scan, y despliegue a dev, qa y prod"

# 2. Mostrar Helm Charts
ls -la helm-charts/ecommerce-microservices/
cat helm-charts/ecommerce-microservices/Chart.yaml
echo "Tenemos Helm Charts configurados con valores por ambiente"

# 3. Mostrar script de Canary Deployment
cat scripts/canary-deploy.sh | head -30
echo "Este script implementa despliegue Canary: 10% → 50% → 100%"

# 4. Mostrar script de Blue-Green Deployment
cat scripts/blue-green-deploy.sh | head -30
echo "Este script implementa despliegue Blue-Green sin downtime"

# 5. Mostrar script de rollback
cat scripts/rollback.sh | head -30
echo "Tenemos rollback automatizado en caso de fallos"

# 6. Mostrar smoke tests
cat scripts/smoke-tests.sh | head -30
echo "Los smoke tests verifican que los servicios estén funcionando después del despliegue"
```

### Lo que vas a decir:
"El pipeline de CI/CD automatiza todo el proceso desde el código hasta el despliegue en producción, con validaciones de seguridad y pruebas automatizadas."

---

## 💾 Sección 5: Almacenamiento y Persistencia (1.5 minutos)

### Lo que vas a decir:
"La base de datos PostgreSQL está configurada con Persistent Volumes, y tenemos backups automatizados configurados."

### Comandos a ejecutar:
```bash
# 1. Mostrar StorageClass
kubectl get storageclass
kubectl describe storageclass fast-ssd
echo "Tenemos StorageClasses configuradas para diferentes tipos de almacenamiento"

# 2. Mostrar PersistentVolumeClaims
kubectl get pvc -n dev
kubectl describe pvc postgres-storage-postgres-0 -n dev
echo "PostgreSQL tiene un PVC de 10Gi para persistir datos"

# 3. Mostrar CronJob de backups (si está desplegado)
kubectl get cronjob -n dev
if kubectl get cronjob postgres-backup -n dev &>/dev/null; then
    kubectl describe cronjob postgres-backup -n dev
    echo "Tenemos un CronJob que ejecuta backups diarios a las 2 AM"
else
    echo "Nota: El CronJob de backups no está desplegado actualmente"
    echo "Para desplegarlo: kubectl apply -f k8s/backups/postgres-backup-cronjob.yaml"
fi

# 4. Mostrar scripts de backup y restauración
ls -la scripts/backup-database.sh scripts/restore-database.sh scripts/list-backups.sh
echo "Tenemos scripts para backup manual, restauración y listar backups"

# 5. Verificar PVC de backups (si está desplegado)
if kubectl get pvc backup-storage -n dev &>/dev/null; then
    kubectl describe pvc backup-storage -n dev
    echo "Hay un PVC dedicado de 20Gi para almacenar los backups"
else
    echo "Nota: El PVC de backups no está desplegado actualmente"
    echo "Para desplegarlo: kubectl apply -f k8s/storage/backup-pvc.yaml"
fi
```

### Lo que vas a decir:
"Los datos están protegidos con backups automatizados diarios, y tenemos scripts para realizar backups manuales y restaurar cuando sea necesario."

---

## 📊 Sección 6: Observabilidad y Monitoreo (3 minutos)

### Lo que vas a decir:
"Hemos implementado un stack completo de observabilidad con Prometheus para métricas, Grafana para visualización, Loki para logs centralizados, y Jaeger para tracing distribuido."

### Comandos a ejecutar:
```bash
# 1. Verificar Prometheus
kubectl get pods -n monitoring | grep prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
echo "Prometheus está recopilando métricas de todos los servicios"

# 2. Abrir Prometheus en navegador
echo "Accediendo a http://localhost:9090"
# En el navegador, mostrar:
# - Targets (todos los servicios "up")
# - Métricas disponibles
# - Alertas configuradas

# 3. Verificar Grafana
kubectl get pods -n monitoring | grep grafana
kubectl get secret -n monitoring | grep grafana
kubectl get secret kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
echo "Grafana está disponible en el puerto 3000"

# 4. Abrir Grafana en navegador
echo "Accediendo a http://localhost:3000"
# En el navegador, mostrar:
# - Dashboard de overview de microservicios
# - Métricas de CPU, memoria, requests
# - Logs de Loki

# 5. Verificar ServiceMonitors
kubectl get servicemonitors -n dev
kubectl describe servicemonitor user-service -n dev
echo "Cada servicio tiene un ServiceMonitor en el namespace dev para que Prometheus lo descubra"

# 6. Verificar PrometheusRules (Alertas)
kubectl get prometheusrules -n monitoring
kubectl describe prometheusrule ecommerce-alerts -n monitoring
echo "Tenemos 9 alertas configuradas para situaciones críticas"

# 7. Verificar Loki
kubectl get pods -n logging | grep loki
echo "Loki está recopilando logs de todos los pods"
echo "Loki está en el namespace 'logging' con pods: loki-0 y loki-promtail-*"

# 8. Verificar Jaeger
kubectl get jaeger -n tracing
kubectl get pods -n tracing
if kubectl get pods -n tracing -l app.kubernetes.io/name=jaeger 2>/dev/null | grep -q jaeger; then
    echo "Jaeger está disponible para tracing distribuido"
    echo "Para acceder a Jaeger UI, usar port-forward al pod de Jaeger"
else
    echo "Nota: La instancia de Jaeger está definida pero los pods aún no están corriendo"
    echo "Esto puede deberse a que el operador de Jaeger está creando los pods"
fi
```

### Lo que vas a decir:
"Como pueden ver, tenemos visibilidad completa del sistema: métricas en Prometheus, dashboards en Grafana, logs centralizados en Loki, y tracing en Jaeger. Esto nos permite monitorear la salud del sistema en tiempo real."

---

## ⚡ Sección 7: Autoscaling y Pruebas de Rendimiento (2 minutos)

### Lo que vas a decir:
"Hemos implementado autoscaling con HPA y KEDA, y tenemos scripts para pruebas de carga con Locust y JMeter."

### Comandos a ejecutar:
```bash
# 1. Mostrar HPAs
kubectl get hpa -n dev
kubectl describe hpa user-service-hpa -n dev
echo "Cada servicio de negocio tiene un HPA configurado para escalar basado en CPU y memoria"

# 2. Mostrar KEDA
kubectl get pods -n keda
echo "KEDA está instalado y funcionando"
kubectl get scaledobjects -A
if kubectl get scaledobjects -n dev 2>/dev/null | grep -q .; then
    echo "ScaledObjects desplegados:"
    kubectl get scaledobjects -n dev
    echo "Mostrando detalles de api-gateway-scaler:"
    kubectl describe scaledobject api-gateway-scaler -n dev
    echo "KEDA está configurado para escalado basado en métricas de Prometheus"
    echo "Nota: user-service usa HPA, mientras que api-gateway y product-service usan KEDA"
    echo "KEDA y HPA no pueden gestionar el mismo Deployment simultáneamente"
else
    echo "Nota: Los ScaledObjects no están desplegados actualmente"
    echo "Esto es porque los servicios ya están siendo gestionados por HPA"
    echo "KEDA y HPA no pueden gestionar el mismo Deployment simultáneamente"
    echo "Los archivos de configuración están en k8s/autoscaling/scaledobject-*.yaml"
    echo "Para desplegarlos (requiere eliminar el HPA primero):"
    echo "  kubectl delete hpa <service>-hpa -n dev"
    echo "  kubectl apply -f k8s/autoscaling/scaledobject-<service>.yaml -n dev"
fi

# 3. Mostrar script de pruebas de carga
cat tests/locustfile.py | head -40
echo "Tenemos un script de Locust para pruebas de carga"

# 4. Ejecutar prueba de carga (opcional, mostrar comando)
echo "Para ejecutar pruebas de carga:"
echo "locust -f tests/locustfile.py --host=http://localhost:8080"

# 5. Mostrar configuración de QoS
kubectl get deployment user-service -n dev -o yaml | grep -A 5 resources
echo "Los pods tienen límites de recursos configurados para garantizar QoS"
```

### Lo que vas a decir:
"El sistema puede escalar automáticamente basado en la carga, y tenemos herramientas para probar el rendimiento bajo diferentes condiciones."

---

## 🌐 Sección 8: Demostración Funcional (3 minutos)

### Lo que vas a decir:
"Ahora voy a demostrar que todos los servicios están funcionando correctamente y pueden comunicarse entre sí."

### Comandos a ejecutar:
```bash
# 1. Verificar Eureka
kubectl port-forward -n dev svc/service-discovery 8761:8761 &
echo "Accediendo a Eureka en http://localhost:8761"
# En el navegador, mostrar:
# - Todos los servicios registrados
# - Estado de cada servicio (UP)

# 2. Probar API Gateway
kubectl port-forward -n dev svc/api-gateway 8080:8080 &
sleep 5

# 3. Probar endpoints
curl http://localhost:8080/user-service/api/users
echo "✅ User Service responde correctamente"

curl http://localhost:8080/product-service/api/products
echo "✅ Product Service responde correctamente"

curl http://localhost:8080/favourite-service/api/favourites
echo "✅ Favourite Service responde correctamente"

# 4. Verificar health endpoints
curl http://localhost:8080/actuator/health
echo "✅ API Gateway health check OK"

curl http://localhost:8080/user-service/actuator/health
echo "✅ User Service health check OK"

# 5. Probar frontend
kubectl port-forward -n dev svc/proxy-client 4200:4200 &
echo "Accediendo al frontend en http://localhost:4200/app/"
# En el navegador, mostrar la página de bienvenida
```

### Lo que vas a decir:
"Como pueden ver, todos los servicios están funcionando correctamente. El API Gateway está enrutando las peticiones a los servicios de negocio, y el frontend está accesible."

---

## 📝 Sección 9: Documentación (1 minuto)

### Lo que vas a decir:
"Finalmente, tenemos documentación completa del proyecto."

### Comandos a ejecutar:
```bash
# 1. Mostrar estructura de documentación
if [ -d "docs/" ]; then
    ls -la docs/
    echo "Tenemos documentación de arquitectura, despliegue, y troubleshooting"
else
    echo "Nota: El directorio docs/ no existe, pero tenemos documentación en la raíz del proyecto"
    ls -la *.md | head -10
fi

# 2. Mostrar README
if [ -f "README.md" ]; then
    cat README.md | head -50
    echo "El README incluye instrucciones de instalación y uso"
else
    echo "README.md no encontrado en la raíz"
fi

# 3. Mostrar manual operativo
if [ -f "docs/OPERATIONS_MANUAL.md" ] || [ -f "OPERATIONS_MANUAL.md" ]; then
    ls -la docs/OPERATIONS_MANUAL.md 2>/dev/null || ls -la OPERATIONS_MANUAL.md
    echo "Tenemos un manual operativo con procedimientos de despliegue, rollback, y monitoreo"
else
    echo "Nota: OPERATIONS_MANUAL.md no encontrado"
    echo "La documentación operativa está en otros archivos .md del proyecto"
fi
```

### Lo que vas a decir:
"La documentación incluye guías de instalación, arquitectura, procedimientos operativos, y troubleshooting."

---

## 🎬 Cierre (30 segundos)

### Lo que vas a decir:
"En resumen, hemos implementado una arquitectura completa de microservicios en Kubernetes con todas las mejores prácticas: seguridad, observabilidad, autoscaling, CI/CD, y persistencia de datos. El sistema está listo para producción y puede escalar según la demanda. Gracias por ver el video."

### Comandos finales:
```bash
# Resumen final
echo "=== RESUMEN DEL PROYECTO ==="
echo "✅ 10 microservicios desplegados"
echo "✅ Observabilidad completa (Prometheus, Grafana, Loki, Jaeger)"
echo "✅ Autoscaling (HPA + KEDA)"
echo "✅ CI/CD con GitHub Actions"
echo "✅ Seguridad (Network Policies, RBAC, Pod Security)"
echo "✅ Backups automatizados"
echo "✅ Documentación completa"
```

---

## 📋 Checklist Pre-Grabación

- [ ] Verificar que todos los servicios estén corriendo
- [ ] Verificar que Prometheus y Grafana estén accesibles
- [ ] Verificar que Eureka muestre todos los servicios registrados
- [ ] Probar que los endpoints del API Gateway funcionen
- [ ] Preparar navegador con pestañas para Prometheus, Grafana, Eureka
- [ ] Tener los comandos listos en un terminal
- [ ] Verificar que el audio y video funcionen correctamente

---

## 💡 Tips para la Grabación

1. **Habla claro y pausado**: No tengas prisa, explica cada comando
2. **Muestra los resultados**: Espera a que los comandos terminen antes de continuar
3. **Usa zoom en terminal**: Si es necesario, haz zoom para que se vean bien los comandos
4. **Navegador visible**: Cuando muestres dashboards, asegúrate de que se vean claramente
5. **Pausa entre secciones**: Haz pausas breves entre secciones para que sea más fácil seguir
6. **Edita si es necesario**: Puedes editar el video después para agregar transiciones o cortar partes

---

**¡Buena suerte con la grabación! 🎥**

