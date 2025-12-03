# Guía Completa de Verificación del Proyecto
## Proyecto Final Plataformas II - E-Commerce Microservices

**Fecha:** 2 de Diciembre, 2025

---

## 📋 Índice

1. [Verificación General del Sistema](#1-verificación-general-del-sistema)
2. [Sección 1: Arquitectura e Infraestructura](#2-sección-1-arquitectura-e-infraestructura)
3. [Sección 2: Configuración de Red y Seguridad](#3-sección-2-configuración-de-red-y-seguridad)
4. [Sección 3: Gestión de Configuración y Secretos](#4-sección-3-gestión-de-configuración-y-secretos)
5. [Sección 4: Estrategias de Despliegue y CI/CD](#5-sección-4-estrategias-de-despliegue-y-cicd)
6. [Sección 5: Almacenamiento y Persistencia](#6-sección-5-almacenamiento-y-persistencia)
7. [Sección 6: Observabilidad y Monitoreo](#7-sección-6-observabilidad-y-monitoreo)
8. [Sección 7: Autoscaling y Pruebas de Rendimiento](#8-sección-7-autoscaling-y-pruebas-de-rendimiento)
9. [Sección 8: Documentación](#9-sección-8-documentación)
10. [Troubleshooting Común](#10-troubleshooting-común)

---

## 1. Verificación General del Sistema

### 1.1 Estado del Cluster

```bash
# Verificar que Minikube esté corriendo
minikube status

# Verificar todos los pods
kubectl get pods -n dev

# Verificar todos los servicios
kubectl get svc -n dev

# Verificar deployments
kubectl get deployments -n dev
```

**Resultado esperado:**
- Todos los pods en estado `Running` (o al menos la mayoría)
- Todos los servicios con `ClusterIP` asignado
- Deployments con réplicas deseadas

### 1.2 Verificar Namespaces

```bash
kubectl get namespaces | grep -E 'dev|qa|prod'
```

**Resultado esperado:**
```
dev     Active    Xd
qa      Active    Xd
prod    Active    Xd
```

---

## 2. Sección 1: Arquitectura e Infraestructura

### 2.1 Verificar Microservicios Desplegados

```bash
# Listar todos los deployments
kubectl get deployments -n dev

# Verificar cada servicio individualmente
kubectl get pods -n dev -l app=service-discovery
kubectl get pods -n dev -l app=cloud-config-server
kubectl get pods -n dev -l app=api-gateway
kubectl get pods -n dev -l app=user-service
kubectl get pods -n dev -l app=product-service
kubectl get pods -n dev -l app=favourite-service
kubectl get pods -n dev -l app=order-service
kubectl get pods -n dev -l app=shipping-service
kubectl get pods -n dev -l app=payment-service
kubectl get pods -n dev -l app=proxy-client
```

**Resultado esperado:** Al menos 1 pod `Running` para cada servicio.

### 2.2 Verificar Dependencias (Orden de Inicio)

```bash
# Verificar que service-discovery esté primero
kubectl get pods -n dev -l app=service-discovery

# Verificar que cloud-config-server esté después
kubectl get pods -n dev -l app=cloud-config-server

# Verificar que api-gateway esté después
kubectl get pods -n dev -l app=api-gateway
```

### 2.3 Verificar Base de Datos

```bash
# Verificar PostgreSQL
kubectl get statefulset -n dev
kubectl get pods -n dev -l app=postgres
kubectl get pvc -n dev
```

**Resultado esperado:**
- StatefulSet `postgres` con 1 réplica
- Pod `postgres-0` en estado `Running`
- PVCs creados y `Bound`

---

## 3. Sección 2: Configuración de Red y Seguridad

### 3.1 Verificar Servicios Kubernetes

```bash
# Verificar todos los servicios
kubectl get svc -n dev

# Verificar tipo de servicio (debe ser ClusterIP)
kubectl get svc -n dev -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.type}{"\n"}{end}'
```

**Resultado esperado:** Todos los servicios con tipo `ClusterIP`.

### 3.2 Verificar Ingress

```bash
# Verificar Ingress Controller
minikube addons list | grep ingress

# Verificar Ingress resource
kubectl get ingress -n dev

# Ver detalles del Ingress
kubectl describe ingress -n dev
```

**Resultado esperado:**
- Ingress addon `enabled`
- Ingress resource creado
- Hosts configurados: `api.ecommerce.local`, `ecommerce.local`

### 3.3 Verificar Network Policies

```bash
# Listar Network Policies
kubectl get networkpolicies -n dev

# Ver detalles
kubectl describe networkpolicy -n dev
```

**Resultado esperado:**
- Al menos 4 Network Policies:
  - `default-deny-all`
  - `allow-eureka-access`
  - `allow-business-services`
  - `allow-api-gateway`

### 3.4 Verificar RBAC

```bash
# Verificar ServiceAccounts
kubectl get serviceaccounts -n dev

# Verificar Roles
kubectl get roles -n dev

# Verificar RoleBindings
kubectl get rolebindings -n dev
```

**Resultado esperado:**
- ServiceAccounts para cada servicio
- Roles con permisos mínimos
- RoleBindings conectando ServiceAccounts con Roles

---

## 4. Sección 3: Gestión de Configuración y Secretos

### 4.1 Verificar ConfigMaps

```bash
# Listar ConfigMaps
kubectl get configmaps -n dev

# Verificar contenido de un ConfigMap
kubectl get configmap user-service-config -n dev -o yaml
```

**Resultado esperado:**
- 9 ConfigMaps (uno por cada servicio)
- Cada ConfigMap contiene `application.yml`

### 4.2 Verificar Secrets

```bash
# Listar Secrets
kubectl get secrets -n dev

# Verificar que los secrets existen (sin mostrar contenido)
kubectl get secrets -n dev | grep -E 'user-service|product-service|favourite-service|order-service|shipping-service|payment-service'
```

**Resultado esperado:**
- 6 Secrets (uno por cada servicio con base de datos)
- Cada Secret contiene `database.username` y `database.password`

### 4.3 Verificar Cloud Config Server

```bash
# Verificar que Cloud Config Server esté corriendo
kubectl get pods -n dev -l app=cloud-config-server

# Probar Cloud Config Server
kubectl port-forward -n dev svc/cloud-config-server 8888:8888 &
sleep 3
curl http://localhost:8888/actuator/health
pkill -f 'port-forward.*8888'
```

**Resultado esperado:**
- Pod `Running`
- Health check retorna `UP`

---

## 5. Sección 4: Estrategias de Despliegue y CI/CD

### 5.1 Verificar GitHub Actions

```bash
# Verificar que el workflow existe
ls -la .github/workflows/ci-cd.yaml

# Verificar contenido del workflow
cat .github/workflows/ci-cd.yaml | head -50
```

**Resultado esperado:**
- Archivo `.github/workflows/ci-cd.yaml` existe
- Contiene jobs: build, test, security-scan, deploy-dev, deploy-qa, deploy-prod

### 5.2 Verificar Scripts de Despliegue

```bash
# Verificar scripts
ls -la scripts/canary-deploy.sh
ls -la scripts/blue-green-deploy.sh
ls -la scripts/rollback.sh
ls -la scripts/smoke-tests.sh

# Verificar permisos
ls -l scripts/*.sh | grep -E 'canary|blue-green|rollback|smoke'
```

**Resultado esperado:**
- Todos los scripts existen
- Permisos de ejecución (`-rwxr-xr-x`)

### 5.3 Verificar Helm Charts

```bash
# Verificar estructura de Helm Charts
ls -la helm-charts/ecommerce-microservices/

# Verificar Chart.yaml
cat helm-charts/ecommerce-microservices/Chart.yaml

# Verificar templates
ls -la helm-charts/ecommerce-microservices/templates/
```

**Resultado esperado:**
- `Chart.yaml` existe
- `values.yaml` y `values-{dev,qa,prod}.yaml` existen
- Templates: `deployment.yaml`, `service.yaml`

---

## 6. Sección 5: Almacenamiento y Persistencia

### 6.1 Verificar StorageClasses

```bash
# Listar StorageClasses
kubectl get storageclass

# Ver detalles
kubectl describe storageclass fast-ssd
kubectl describe storageclass standard
```

**Resultado esperado:**
- `fast-ssd` con `reclaimPolicy: Retain`
- `standard` con `reclaimPolicy: Delete` (default)

### 6.2 Verificar Persistent Volumes

```bash
# Verificar PVCs
kubectl get pvc -n dev

# Verificar que están Bound
kubectl get pvc -n dev -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

**Resultado esperado:**
- PVCs para PostgreSQL y backups
- Estado `Bound`

### 6.3 Verificar Backups

```bash
# Verificar CronJob
kubectl get cronjob -n dev

# Verificar Jobs de backup
kubectl get jobs -n dev | grep backup

# Verificar scripts de backup
ls -la scripts/backup-database.sh
ls -la scripts/restore-database.sh
ls -la scripts/list-backups.sh
```

**Resultado esperado:**
- CronJob `postgres-backup` configurado
- Scripts de backup existen y tienen permisos de ejecución

---

## 7. Sección 6: Observabilidad y Monitoreo

### 7.1 Verificar Prometheus

```bash
# Verificar que Prometheus esté instalado
kubectl get pods -n monitoring | grep prometheus

# Verificar ServiceMonitors
kubectl get servicemonitors -n dev

# Acceder a Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
# Abrir en navegador: http://localhost:9090
```

**Resultado esperado:**
- Pods de Prometheus `Running`
- ServiceMonitors para todos los servicios
- Prometheus UI accesible

### 7.2 Verificar Grafana

```bash
# Verificar que Grafana esté instalado
kubectl get pods -n monitoring | grep grafana

# Acceder a Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
# Abrir en navegador: http://localhost:3000
# Usuario: admin, Contraseña: admin123
```

**Resultado esperado:**
- Pods de Grafana `Running`
- Dashboards personalizados disponibles

### 7.3 Verificar Loki

```bash
# Verificar que Loki esté instalado
kubectl get pods -n logging | grep loki

# Verificar Promtail
kubectl get pods -n logging | grep promtail
```

**Resultado esperado:**
- Pods de Loki y Promtail `Running`

### 7.4 Verificar Jaeger

```bash
# Verificar que Jaeger esté instalado
kubectl get pods -n tracing | grep jaeger

# Acceder a Jaeger UI
kubectl port-forward -n tracing svc/jaeger-query 16686:16686 &
# Abrir en navegador: http://localhost:16686
```

**Resultado esperado:**
- Pods de Jaeger `Running`
- Jaeger UI accesible

### 7.5 Verificar Alertas

```bash
# Verificar PrometheusRules
kubectl get prometheusrules -n dev

# Verificar AlertManager
kubectl get pods -n monitoring | grep alertmanager
```

**Resultado esperado:**
- PrometheusRules configuradas
- AlertManager `Running`

---

## 8. Sección 7: Autoscaling y Pruebas de Rendimiento

### 8.1 Verificar HPAs

```bash
# Listar HPAs
kubectl get hpa -n dev

# Ver detalles de un HPA
kubectl describe hpa user-service-hpa -n dev
```

**Resultado esperado:**
- 7 HPAs configurados
- Min replicas: 2, Max replicas: 10
- Métricas: CPU 70%, Memory 80%

### 8.2 Verificar KEDA

```bash
# Verificar pods de KEDA
kubectl get pods -n keda

# Verificar ScaledObjects
kubectl get scaledobjects -n dev
```

**Resultado esperado:**
- Pods de KEDA `Running`
- 3 ScaledObjects configurados

### 8.3 Verificar Metrics Server

```bash
# Verificar que metrics-server esté habilitado
minikube addons list | grep metrics-server

# Verificar métricas
kubectl top pods -n dev
```

**Resultado esperado:**
- Metrics-server `enabled`
- Métricas de CPU y memoria disponibles

### 8.4 Verificar Pruebas de Carga

```bash
# Verificar Locust
which locust
locust --version

# Verificar archivo de pruebas
ls -la tests/locustfile.py

# Verificar JMeter
which jmeter
jmeter --version

# Verificar plan de pruebas
ls -la tests/jmeter-test-plan.jmx
```

**Resultado esperado:**
- Locust y JMeter instalados
- Archivos de pruebas existen

---

## 9. Sección 8: Documentación

### 9.1 Verificar Documentación Técnica

```bash
# Verificar archivos de documentación
ls -la docs/ 2>/dev/null || echo "Directorio docs/ no existe"
ls -la *.md | head -20
```

**Resultado esperado:**
- Documentación de arquitectura
- Documentación de despliegue
- Guías de troubleshooting

### 9.2 Verificar README

```bash
# Verificar README principal
ls -la README.md
cat README.md | head -50
```

**Resultado esperado:**
- README.md existe
- Contiene información del proyecto
- Instrucciones de instalación

---

## 10. Troubleshooting Común

### 10.1 Pods en Estado Pending

**Problema:** Pods no pueden iniciar, estado `Pending`

**Solución:**
```bash
# Verificar recursos disponibles
kubectl describe pod <pod-name> -n dev

# Reducir réplicas si hay falta de recursos
kubectl scale deployment <deployment-name> --replicas=1 -n dev

# Verificar límites de recursos
kubectl top nodes
```

### 10.2 Servicios No Registrados en Eureka

**Problema:** Servicios no aparecen en Eureka Dashboard

**Solución:**
```bash
# Verificar logs del servicio
kubectl logs -n dev -l app=<service-name> --tail=50

# Verificar ConfigMap
kubectl get configmap <service-name>-config -n dev -o yaml

# Verificar que service-discovery esté accesible
kubectl get svc service-discovery -n dev
```

### 10.3 Errores 500 en API Gateway

**Problema:** Endpoints retornan error 500

**Solución:**
```bash
# Verificar logs del API Gateway
kubectl logs -n dev -l app=api-gateway --tail=50

# Verificar rutas configuradas
kubectl get configmap api-gateway-config -n dev -o yaml

# Probar servicio directamente
kubectl port-forward -n dev svc/<service-name> <port>:<port>
curl http://localhost:<port>/api/<endpoint>
```

### 10.4 Problemas de Conexión a Base de Datos

**Problema:** Servicios no pueden conectar a PostgreSQL

**Solución:**
```bash
# Verificar que PostgreSQL esté corriendo
kubectl get pods -n dev -l app=postgres

# Verificar Secret
kubectl get secret <service-name>-secret -n dev

# Verificar ConfigMap
kubectl get configmap <service-name>-config -n dev -o yaml | grep datasource
```

### 10.5 Prometheus Sin Targets

**Problema:** Prometheus no muestra servicios como targets

**Solución:**
```bash
# Verificar ServiceMonitors
kubectl get servicemonitors -n dev

# Verificar que los servicios expongan /actuator/prometheus
kubectl port-forward -n dev svc/<service-name> <port>:<port>
curl http://localhost:<port>/actuator/prometheus

# Verificar ConfigMap del servicio
kubectl get configmap <service-name>-config -n dev -o yaml | grep prometheus
```

---

## 📊 Checklist de Verificación Rápida

```bash
#!/bin/bash
# Script de verificación rápida

echo "=== VERIFICACIÓN RÁPIDA DEL PROYECTO ==="
echo ""

echo "1. Pods:"
kubectl get pods -n dev --no-headers | wc -l
echo "pods en namespace dev"

echo "2. Servicios:"
kubectl get svc -n dev --no-headers | wc -l
echo "servicios en namespace dev"

echo "3. ConfigMaps:"
kubectl get configmaps -n dev --no-headers | wc -l
echo "configmaps en namespace dev"

echo "4. Secrets:"
kubectl get secrets -n dev --no-headers | grep -v default | wc -l
echo "secrets en namespace dev"

echo "5. HPAs:"
kubectl get hpa -n dev --no-headers 2>/dev/null | wc -l
echo "HPAs configurados"

echo "6. Network Policies:"
kubectl get networkpolicies -n dev --no-headers 2>/dev/null | wc -l
echo "Network Policies configuradas"

echo "7. ServiceMonitors:"
kubectl get servicemonitors -n dev --no-headers 2>/dev/null | wc -l
echo "ServiceMonitors configurados"

echo ""
echo "✅ Verificación completada"
```

---

## 🎯 Conclusión

Esta guía cubre todos los aspectos del proyecto según los requerimientos del PDF. Usa esta guía para verificar que todo esté funcionando correctamente antes de la presentación.

**Última actualización:** 2 de Diciembre, 2025

