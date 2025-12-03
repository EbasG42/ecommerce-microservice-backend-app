#!/bin/bash
# Script para restaurar una base de datos desde un backup
# Uso: ./restore-database.sh <database-name> <backup-file>

set -e

NAMESPACE="${NAMESPACE:-dev}"
DATABASE_NAME="$1"
BACKUP_FILE="$2"

if [ -z "$DATABASE_NAME" ] || [ -z "$BACKUP_FILE" ]; then
    echo "Uso: $0 <database-name> <backup-file>"
    echo "Ejemplo: $0 userdb userdb-20231201-020000.dump"
    echo ""
    echo "Para listar backups disponibles:"
    echo "  kubectl exec -n $NAMESPACE -it <backup-pod> -- ls -lh /backups/"
    exit 1
fi

echo "🔄 Iniciando restauración de la base de datos: $DATABASE_NAME"
echo "📦 Archivo de backup: $BACKUP_FILE"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "⚠️  El archivo $BACKUP_FILE no existe localmente."
    echo "   Si el backup está en el PVC, necesitarás copiarlo primero."
    echo ""
    echo "Para copiar desde el PVC:"
    echo "  1. Obtener pod del backup:"
    echo "     kubectl get pods -n $NAMESPACE | grep backup"
    echo "  2. Copiar archivo:"
    echo "     kubectl cp $NAMESPACE/<pod-name>:/backups/$BACKUP_FILE ./$BACKUP_FILE"
    exit 1
fi

# Crear Job de restauración
JOB_NAME="restore-${DATABASE_NAME}-$(date +%Y%m%d-%H%M%S)"

cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: ${NAMESPACE}
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: restore
        image: postgres:15
        env:
        - name: PGHOST
          value: postgres
        - name: PGPORT
          value: "5432"
        - name: PGUSER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        command:
        - /bin/bash
        - -c
        - |
          set -e
          echo "⚠️  ADVERTENCIA: Esta operación eliminará todos los datos existentes en ${DATABASE_NAME}"
          echo "Restaurando ${DATABASE_NAME} desde ${BACKUP_FILE}"
          
          # Eliminar base de datos existente (si existe)
          psql -h \$PGHOST -U \$PGUSER -c "DROP DATABASE IF EXISTS ${DATABASE_NAME};" || true
          
          # Crear base de datos
          psql -h \$PGHOST -U \$PGUSER -c "CREATE DATABASE ${DATABASE_NAME};"
          
          # Restaurar desde backup
          pg_restore -h \$PGHOST -U \$PGUSER -d ${DATABASE_NAME} -F c /backups/${BACKUP_FILE} || {
            echo "❌ Error al restaurar. Intentando con formato SQL..."
            psql -h \$PGHOST -U \$PGUSER -d ${DATABASE_NAME} < /backups/${BACKUP_FILE}
          }
          
          echo "✅ Restauración completada exitosamente"
        volumeMounts:
        - name: backup-storage
          mountPath: /backups
        - name: backup-file
          mountPath: /backups/${BACKUP_FILE}
          subPath: ${BACKUP_FILE}
          readOnly: true
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-storage
      - name: backup-file
        hostPath:
          path: $(pwd)/${BACKUP_FILE}
          type: File
EOF

echo "⏳ Esperando a que la restauración se complete..."
kubectl wait --for=condition=complete \
    job/${JOB_NAME} \
    -n "$NAMESPACE" \
    --timeout=600s || {
    echo "❌ La restauración falló"
    kubectl logs -n "$NAMESPACE" -l job-name=${JOB_NAME} --tail=50
    exit 1
}

echo "✅ Restauración completada exitosamente"

# Mostrar logs
echo ""
echo "📋 Logs de la restauración:"
kubectl logs -n "$NAMESPACE" -l job-name=${JOB_NAME} --tail=20

