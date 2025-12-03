# Corrección: Guion de Video - Sección de Almacenamiento

## Problemas Identificados

1. **PVC de PostgreSQL**: El guion usaba `postgres-pvc` pero el nombre correcto es `postgres-storage-postgres-0`
2. **CronJob de backups**: El guion hace referencia a `postgres-backup` pero no está desplegado actualmente
3. **PVC de backups**: El guion hace referencia a `backup-storage` pero no está desplegado actualmente

## Soluciones Aplicadas

### 1. PVC de PostgreSQL

**Nombre correcto**: `postgres-storage-postgres-0`

Este nombre se genera automáticamente por el StatefulSet usando `volumeClaimTemplates`:
- Template name: `postgres-storage`
- StatefulSet name: `postgres`
- Pod ordinal: `0`
- Resultado: `postgres-storage-postgres-0`

**Comando actualizado**:
```bash
kubectl describe pvc postgres-storage-postgres-0 -n dev
```

### 2. CronJob de Backups

**Estado actual**: No está desplegado

El archivo existe en `k8s/backups/postgres-backup-cronjob.yaml` con el nombre `postgres-backup`, pero no está aplicado en el cluster.

**Comando para desplegar**:
```bash
kubectl apply -f k8s/backups/postgres-backup-cronjob.yaml
```

**Actualización en el guion**: Se agregó una verificación condicional que indica si el CronJob está desplegado o no.

### 3. PVC de Backups

**Estado actual**: No está desplegado

El archivo existe en `k8s/storage/backup-pvc.yaml` con el nombre `backup-storage`, pero no está aplicado en el cluster.

**Comando para desplegar**:
```bash
kubectl apply -f k8s/storage/backup-pvc.yaml
```

**Nota**: El CronJob de backups requiere que este PVC esté desplegado antes de poder funcionar.

**Actualización en el guion**: Se agregó una verificación condicional que indica si el PVC está desplegado o no.

## Cambios en el Guion

El guion ahora incluye:

1. **Verificación condicional del CronJob**:
   ```bash
   if kubectl get cronjob postgres-backup -n dev &>/dev/null; then
       kubectl describe cronjob postgres-backup -n dev
       echo "Tenemos un CronJob que ejecuta backups diarios a las 2 AM"
   else
       echo "Nota: El CronJob de backups no está desplegado actualmente"
       echo "Para desplegarlo: kubectl apply -f k8s/backups/postgres-backup-cronjob.yaml"
   fi
   ```

2. **Verificación condicional del PVC de backups**:
   ```bash
   if kubectl get pvc backup-storage -n dev &>/dev/null; then
       kubectl describe pvc backup-storage -n dev
       echo "Hay un PVC dedicado de 20Gi para almacenar los backups"
   else
       echo "Nota: El PVC de backups no está desplegado actualmente"
       echo "Para desplegarlo: kubectl apply -f k8s/storage/backup-pvc.yaml"
   fi
   ```

## Para Desplegar los Componentes de Backup

Si deseas desplegar los componentes de backup durante la grabación del video:

```bash
# 1. Desplegar el PVC de backups
kubectl apply -f k8s/storage/backup-pvc.yaml

# 2. Verificar que el PVC esté Bound
kubectl get pvc backup-storage -n dev

# 3. Desplegar el CronJob de backups
kubectl apply -f k8s/backups/postgres-backup-cronjob.yaml

# 4. Verificar que el CronJob esté creado
kubectl get cronjob postgres-backup -n dev
```

## Estado Actual

✅ **Desplegado**:
- PVC de PostgreSQL: `postgres-storage-postgres-0` (Bound, 10Gi)

❌ **No desplegado** (archivos existen pero no aplicados):
- CronJob de backups: `postgres-backup`
- PVC de backups: `backup-storage` (20Gi)

