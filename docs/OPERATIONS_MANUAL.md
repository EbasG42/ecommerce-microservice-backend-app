# Manual de Operaciones
## Sistema E-Commerce Microservices en Kubernetes

**Versión:** 1.0  
**Fecha:** 2 de Diciembre, 2025

---

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Procedimientos de Despliegue](#procedimientos-de-despliegue)
3. [Procedimientos de Rollback](#procedimientos-de-rollback)
4. [Procedimientos de Backup y Restauración](#procedimientos-de-backup-y-restauración)
5. [Monitoreo y Alertas](#monitoreo-y-alertas)
6. [Escalado Manual](#escalado-manual)
7. [Troubleshooting](#troubleshooting)
8. [Mantenimiento](#mantenimiento)
9. [Procedimientos de Emergencia](#procedimientos-de-emergencia)

---

## 1. Introducción

Este manual describe los procedimientos operativos para gestionar el sistema de e-commerce basado en microservicios desplegado en Kubernetes. Incluye procedimientos para despliegue, rollback, backup, monitoreo y troubleshooting.

### Componentes del Sistema

- **10 Microservicios**: Service Discovery, Cloud Config, API Gateway, 6 servicios de negocio, Frontend
- **PostgreSQL**: Base de datos (StatefulSet)
- **Observabilidad**: Prometheus, Grafana, Loki, Jaeger
- **Autoscaling**: HPA y KEDA

### Ambientes

- **dev**: Desarrollo y pruebas
- **qa**: Pruebas de calidad
- **prod**: Producción

---

## 2. Procedimientos de Despliegue

### 2.1 Despliegue Completo

#### Despliegue Inicial

```bash
# 1. Verificar que el clúster esté disponible
kubectl cluster-info

# 2. Crear namespaces
kubectl apply -f k8s/namespaces/namespaces.yaml

# 3. Desplegar storage
kubectl apply -f k8s/storage/storage-class.yaml
kubectl apply -f k8s/storage/backup-pvc.yaml

# 4. Desplegar base de datos
kubectl apply -f k8s/databases/postgres-secret.yaml
kubectl apply -f k8s/databases/postgres-init-scripts.yaml
# (Aplicar StatefulSet de PostgreSQL)

# 5. Esperar a que PostgreSQL esté listo
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=300s

# 6. Desplegar infraestructura
kubectl apply -f k8s/config/service-discovery-configmap.yaml
# (Aplicar Deployment y Service de service-discovery)
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=300s

# 7. Desplegar Cloud Config
kubectl apply -f k8s/config/cloud-config-server-configmap.yaml
# (Aplicar Deployment y Service de cloud-config-server)
kubectl wait --for=condition=ready pod -l app=cloud-config-server -n dev --timeout=300s

# 8. Desplegar servicios de negocio
for service in user-service product-service favourite-service order-service shipping-service payment-service; do
  kubectl apply -f k8s/config/${service}-configmap.yaml
  kubectl apply -f k8s/secrets/${service}-secret.yaml
  # (Aplicar Deployment y Service)
  kubectl wait --for=condition=ready pod -l app=${service} -n dev --timeout=300s
done

# 9. Desplegar API Gateway
kubectl apply -f k8s/config/api-gateway-configmap.yaml
# (Aplicar Deployment y Service de api-gateway)
kubectl wait --for=condition=ready pod -l app=api-gateway -n dev --timeout=300s

# 10. Desplegar Frontend
kubectl apply -f k8s/config/proxy-client-eureka-configmap.yaml
# (Aplicar Deployment y Service de proxy-client)

# 11. Desplegar Ingress
kubectl apply -f k8s/ingress/ingress-tls.yaml

# 12. Desplegar Network Policies
kubectl apply -f k8s/network-policies/

# 13. Desplegar RBAC
kubectl apply -f k8s/rbac/rbac-complete.yaml

# 14. Desplegar Autoscaling
kubectl apply -f k8s/autoscaling/

# 15. Verificar estado
./scripts/health-check.sh dev
```

#### Usando Script de Despliegue

```bash
# Desplegar todo el stack
./scripts/deploy-all.sh dev

# Verificar estado
kubectl get pods -n dev
```

### 2.2 Despliegue de un Servicio Específico

```bash
# Actualizar ConfigMap (si es necesario)
kubectl apply -f k8s/config/<service-name>-configmap.yaml

# Actualizar Secret (si es necesario)
kubectl apply -f k8s/secrets/<service-name>-secret.yaml

# Actualizar Deployment
kubectl apply -f k8s/services/<service-name>/deployment.yaml

# Verificar rollout
kubectl rollout status deployment/<service-name> -n dev

# Verificar que el servicio esté funcionando
kubectl get pods -n dev -l app=<service-name>
```

### 2.3 Despliegue con Helm

```bash
# Desplegar con Helm
helm install ecommerce ./helm-charts/ecommerce-microservices \
  --namespace dev \
  --values ./helm-charts/ecommerce-microservices/values-dev.yaml

# Actualizar con Helm
helm upgrade ecommerce ./helm-charts/ecommerce-microservices \
  --namespace dev \
  --values ./helm-charts/ecommerce-microservices/values-dev.yaml

# Verificar estado
helm status ecommerce -n dev
```

### 2.4 Canary Deployment

```bash
# Ejecutar Canary Deployment
./scripts/canary-deploy.sh <service-name> <new-version> dev

# El script ejecuta:
# 1. Despliegue del 10% del tráfico
# 2. Validación
# 3. Despliegue del 50% del tráfico
# 4. Validación
# 5. Despliegue del 100% del tráfico
# 6. Limpieza
```

### 2.5 Blue-Green Deployment

```bash
# Ejecutar Blue-Green Deployment
./scripts/blue-green-deploy.sh dev <new-version>

# El script ejecuta:
# 1. Detección del color actual (blue/green)
# 2. Despliegue del nuevo color
# 3. Health checks
# 4. Cambio de tráfico
# 5. Limpieza del deployment antiguo
```

---

## 3. Procedimientos de Rollback

### 3.1 Rollback Automatizado

```bash
# Rollback de un servicio específico
./scripts/rollback.sh dev <service-name>

# Rollback de todos los servicios
./scripts/rollback.sh dev

# El script:
# 1. Identifica la última revisión funcional
# 2. Ejecuta el rollback
# 3. Verifica que el servicio esté funcionando
```

### 3.2 Rollback Manual

```bash
# Ver historial de rollouts
kubectl rollout history deployment/<service-name> -n dev

# Ver detalles de una revisión específica
kubectl rollout history deployment/<service-name> -n dev --revision=<revision-number>

# Rollback a la revisión anterior
kubectl rollout undo deployment/<service-name> -n dev

# Rollback a una revisión específica
kubectl rollout undo deployment/<service-name> -n dev --to-revision=<revision-number>

# Verificar estado del rollback
kubectl rollout status deployment/<service-name> -n dev
```

### 3.3 Rollback con Helm

```bash
# Ver historial de releases
helm history ecommerce -n dev

# Rollback a una versión anterior
helm rollback ecommerce <revision-number> -n dev

# Verificar estado
helm status ecommerce -n dev
```

---

## 4. Procedimientos de Backup y Restauración

### 4.1 Backup Automatizado

Los backups se ejecutan automáticamente mediante un CronJob configurado para ejecutarse diariamente a las 2 AM.

```bash
# Verificar CronJob
kubectl get cronjob -n dev

# Ver historial de ejecuciones
kubectl get jobs -n dev -l app=postgres-backup

# Ver logs de la última ejecución
kubectl logs -n dev -l app=postgres-backup --tail=100
```

### 4.2 Backup Manual

```bash
# Ejecutar backup manual
./scripts/backup-database.sh

# El script:
# 1. Crea un Job de backup
# 2. Espera a que se complete
# 3. Verifica que el backup se haya creado
# 4. Muestra la ubicación del backup
```

### 4.3 Listar Backups

```bash
# Listar backups disponibles
./scripts/list-backups.sh

# O manualmente
kubectl exec -n dev <postgres-pod> -- ls -lh /backups/
```

### 4.4 Restaurar desde Backup

```bash
# Restaurar desde backup
./scripts/restore-database.sh <backup-file>

# El script:
# 1. Verifica que el backup existe
# 2. Crea un Job de restauración
# 3. Espera a que se complete
# 4. Verifica que la restauración fue exitosa
```

### 4.5 Backup de ConfigMaps y Secrets

```bash
# Exportar ConfigMaps
kubectl get configmaps -n dev -o yaml > configmaps-backup.yaml

# Exportar Secrets
kubectl get secrets -n dev -o yaml > secrets-backup.yaml

# Restaurar ConfigMaps
kubectl apply -f configmaps-backup.yaml

# Restaurar Secrets
kubectl apply -f secrets-backup.yaml
```

---

## 5. Monitoreo y Alertas

### 5.1 Acceso a Dashboards

#### Grafana

```bash
# Obtener contraseña
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d

# Port-forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Acceder: http://localhost:3000
# Usuario: admin
```

#### Prometheus

```bash
# Port-forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Acceder: http://localhost:9090
```

#### Jaeger

```bash
# Port-forward
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686

# Acceder: http://localhost:16686
```

### 5.2 Verificar Métricas

```bash
# Ver métricas de un pod
kubectl top pod <pod-name> -n dev

# Ver métricas de todos los pods
kubectl top pods -n dev

# Ver métricas de nodos
kubectl top nodes
```

### 5.3 Verificar Alertas

```bash
# Ver PrometheusRules
kubectl get prometheusrules -n monitoring

# Ver detalles de una regla
kubectl describe prometheusrule ecommerce-alerts -n monitoring

# Ver alertas activas en Prometheus
# (Acceder a http://localhost:9090/alerts)
```

### 5.4 Alertas Configuradas

1. **ServiceDown**: Servicio no disponible
2. **HighErrorRate**: Tasa de errores alta
3. **HighResponseTime**: Tiempo de respuesta alto
4. **HighMemoryUsage**: Uso de memoria alto
5. **HighCPUUsage**: Uso de CPU alto
6. **DatabaseConnectionPoolExhausted**: Pool de conexiones agotado
7. **HighJVMHeapUsage**: Uso de heap JVM alto
8. **HighRequestRate**: Tasa de requests alta
9. **PodRestartingFrequently**: Pod reiniciándose frecuentemente

---

## 6. Escalado Manual

### 6.1 Escalar Deployment

```bash
# Escalar a un número específico de réplicas
kubectl scale deployment <service-name> --replicas=<number> -n dev

# Verificar escalado
kubectl get deployment <service-name> -n dev
kubectl get pods -n dev -l app=<service-name>
```

### 6.2 Verificar HPA

```bash
# Ver HPAs
kubectl get hpa -n dev

# Ver detalles de un HPA
kubectl describe hpa <service-name>-hpa -n dev

# Ver métricas que usa el HPA
kubectl get --raw /apis/autoscaling/v2/namespaces/dev/horizontalpodautoscalers/<service-name>-hpa
```

### 6.3 Verificar KEDA

```bash
# Ver ScaledObjects
kubectl get scaledobjects -n dev

# Ver detalles de un ScaledObject
kubectl describe scaledobject <service-name>-scaler -n dev

# Ver métricas de KEDA
kubectl get --raw /apis/keda.sh/v1alpha1/namespaces/dev/scaledobjects/<service-name>-scaler
```

### 6.4 Ajustar Recursos

```bash
# Editar Deployment para ajustar recursos
kubectl edit deployment <service-name> -n dev

# O aplicar un archivo YAML actualizado
kubectl apply -f k8s/services/<service-name>/deployment.yaml
```

---

## 7. Troubleshooting

### 7.1 Pods no Inician

```bash
# Ver estado de pods
kubectl get pods -n dev

# Ver logs
kubectl logs <pod-name> -n dev

# Ver logs anteriores (si el pod se reinició)
kubectl logs <pod-name> -n dev --previous

# Describir pod
kubectl describe pod <pod-name> -n dev

# Ver eventos
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### 7.2 Servicios no se Registran en Eureka

```bash
# Verificar Service Discovery
kubectl get pods -n dev -l app=service-discovery
kubectl logs -n dev -l app=service-discovery --tail=100

# Verificar configuración del servicio
kubectl get configmap <service-name>-config -n dev -o yaml

# Verificar conectividad
kubectl exec -it <service-pod> -n dev -- wget -O- http://service-discovery:8761/eureka/
```

### 7.3 Problemas de Conectividad

```bash
# Verificar Network Policies
kubectl get networkpolicies -n dev
kubectl describe networkpolicy <policy-name> -n dev

# Verificar Services
kubectl get svc -n dev
kubectl describe svc <service-name> -n dev

# Probar conectividad desde un pod
kubectl run -it --rm debug --image=busybox --restart=Never -n dev -- sh
# Dentro del pod:
# wget -O- http://<service-name>:<port>/actuator/health
```

### 7.4 Problemas de Base de Datos

```bash
# Verificar PostgreSQL
kubectl get pods -n dev -l app=postgres
kubectl logs -n dev -l app=postgres --tail=100

# Conectar a PostgreSQL
kubectl exec -it <postgres-pod> -n dev -- psql -U postgres

# Verificar bases de datos
kubectl exec -it <postgres-pod> -n dev -- psql -U postgres -c "\l"

# Verificar conexiones
kubectl exec -it <postgres-pod> -n dev -- psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

### 7.5 Problemas de Recursos

```bash
# Ver uso de recursos
kubectl top pods -n dev
kubectl top nodes

# Ver límites y requests
kubectl describe pod <pod-name> -n dev | grep -A 5 "Limits\|Requests"

# Ver eventos relacionados con recursos
kubectl get events -n dev --field-selector reason=FailedScheduling
```

---

## 8. Mantenimiento

### 8.1 Actualización de Imágenes

```bash
# Actualizar imagen de un servicio
kubectl set image deployment/<service-name> \
  <container-name>=<new-image>:<tag> -n dev

# Verificar rollout
kubectl rollout status deployment/<service-name> -n dev
```

### 8.2 Rotación de Secretos

```bash
# Rotar secretos
./scripts/rotate-secrets.sh <service-name> <new-username> <new-password>

# El script:
# 1. Actualiza el Secret
# 2. Reinicia el Deployment
# 3. Espera a que el rollout se complete
```

### 8.3 Limpieza de Recursos

```bash
# Eliminar pods completados
kubectl delete pods --field-selector=status.phase=Succeeded -n dev

# Eliminar pods fallidos
kubectl delete pods --field-selector=status.phase=Failed -n dev

# Limpiar imágenes antiguas (en Minikube)
minikube ssh -- docker image prune -a
```

### 8.4 Actualización de ConfigMaps

```bash
# Actualizar ConfigMap
kubectl apply -f k8s/config/<service-name>-configmap.yaml

# Reiniciar pods para aplicar cambios
kubectl rollout restart deployment/<service-name> -n dev
```

---

## 9. Procedimientos de Emergencia

### 9.1 Servicio Crítico Caído

```bash
# 1. Verificar estado
kubectl get pods -n dev -l app=<service-name>

# 2. Ver logs
kubectl logs -n dev -l app=<service-name> --tail=100

# 3. Describir pod
kubectl describe pod -n dev -l app=<service-name>

# 4. Reiniciar servicio
kubectl rollout restart deployment/<service-name> -n dev

# 5. Si no funciona, hacer rollback
./scripts/rollback.sh dev <service-name>
```

### 9.2 Base de Datos Caída

```bash
# 1. Verificar PostgreSQL
kubectl get pods -n dev -l app=postgres

# 2. Ver logs
kubectl logs -n dev -l app=postgres --tail=100

# 3. Reiniciar PostgreSQL
kubectl delete pod -n dev -l app=postgres
# El StatefulSet recreará el pod automáticamente

# 4. Si es necesario, restaurar desde backup
./scripts/restore-database.sh <backup-file>
```

### 9.3 Pérdida de Datos

```bash
# 1. Detener servicios que usan la base de datos
kubectl scale deployment <service-name> --replicas=0 -n dev

# 2. Restaurar desde backup
./scripts/restore-database.sh <backup-file>

# 3. Verificar restauración
kubectl exec -it <postgres-pod> -n dev -- psql -U postgres -c "\l"

# 4. Reiniciar servicios
kubectl scale deployment <service-name> --replicas=<original-replicas> -n dev
```

### 9.4 Problemas de Red

```bash
# 1. Verificar Network Policies
kubectl get networkpolicies -n dev

# 2. Deshabilitar temporalmente Network Policies (solo en emergencia)
kubectl delete networkpolicy --all -n dev

# 3. Verificar conectividad
kubectl run -it --rm debug --image=busybox --restart=Never -n dev -- sh

# 4. Restaurar Network Policies
kubectl apply -f k8s/network-policies/
```

### 9.5 Escalado de Emergencia

```bash
# Escalar manualmente todos los servicios críticos
for service in api-gateway user-service product-service; do
  kubectl scale deployment $service --replicas=5 -n dev
done

# Verificar escalado
kubectl get pods -n dev
```

---

## 📞 Contacto y Soporte

Para problemas o preguntas:

1. Revisar logs y eventos de Kubernetes
2. Consultar documentación en `docs/`
3. Revisar issues en el repositorio
4. Contactar al equipo de DevOps

---

**Última actualización:** 2 de Diciembre, 2025

