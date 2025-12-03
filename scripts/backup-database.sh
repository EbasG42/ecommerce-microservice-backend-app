#!/bin/bash
# Script para realizar backup manual de bases de datos
# Uso: ./backup-database.sh [database-name]

set -e

NAMESPACE="${NAMESPACE:-dev}"
DATABASE_NAME="$1"

if [ -z "$DATABASE_NAME" ]; then
    echo "Uso: $0 <database-name>"
    echo "Bases de datos disponibles: userdb, productdb, favouritedb, orderdb, shippingdb, paymentdb"
    exit 1
fi

echo "🔄 Iniciando backup manual de la base de datos: $DATABASE_NAME"

# Crear Job de backup
kubectl create job --from=cronjob/postgres-backup "backup-${DATABASE_NAME}-$(date +%Y%m%d-%H%M%S)" \
    -n "$NAMESPACE" || {
    echo "⚠️  CronJob no existe, creando Job manual..."
    
    # Crear Job manual
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-${DATABASE_NAME}-$(date +%Y%m%d-%H%M%S)
  namespace: ${NAMESPACE}
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: backup
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
          BACKUP_FILE="/backups/${DATABASE_NAME}-\$(date +%Y%m%d-%H%M%S).dump"
          echo "Respaldando ${DATABASE_NAME} a \$BACKUP_FILE"
          pg_dump -h \$PGHOST -U \$PGUSER -F c -f "\$BACKUP_FILE" "${DATABASE_NAME}"
          echo "✅ Backup completado: \$BACKUP_FILE"
          ls -lh /backups/
        volumeMounts:
        - name: backup-storage
          mountPath: /backups
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-storage
EOF
}

echo "⏳ Esperando a que el backup se complete..."
kubectl wait --for=condition=complete \
    job/backup-${DATABASE_NAME}-$(date +%Y%m%d-%H%M%S) \
    -n "$NAMESPACE" \
    --timeout=300s || {
    echo "❌ El backup falló"
    kubectl logs -n "$NAMESPACE" -l job-name=backup-${DATABASE_NAME}-$(date +%Y%m%d-%H%M%S) --tail=50
    exit 1
}

echo "✅ Backup completado exitosamente"

# Mostrar logs
echo ""
echo "📋 Logs del backup:"
kubectl logs -n "$NAMESPACE" -l job-name=backup-${DATABASE_NAME}-$(date +%Y%m%d-%H%M%S) --tail=20

