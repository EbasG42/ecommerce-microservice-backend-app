#!/bin/bash
# Script para listar backups disponibles
# Uso: ./list-backups.sh

set -e

NAMESPACE="${NAMESPACE:-dev}"

echo "📦 Listando backups disponibles en el PVC..."

# Obtener el pod del backup más reciente
BACKUP_POD=$(kubectl get pods -n "$NAMESPACE" -l job-name --sort-by=.metadata.creationTimestamp | grep backup | tail -1 | awk '{print $1}')

if [ -z "$BACKUP_POD" ]; then
    echo "⚠️  No se encontró ningún pod de backup."
    echo "   Creando un pod temporal para listar backups..."
    
    # Crear pod temporal
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backup-lister
  namespace: ${NAMESPACE}
spec:
  restartPolicy: Never
  containers:
  - name: lister
    image: postgres:15
    command:
    - /bin/bash
    - -c
    - |
      echo "=== Backups disponibles ==="
      ls -lh /backups/ || echo "No hay backups disponibles"
      echo ""
      echo "=== Espacio utilizado ==="
      df -h /backups
    volumeMounts:
    - name: backup-storage
      mountPath: /backups
  volumes:
  - name: backup-storage
    persistentVolumeClaim:
      claimName: backup-storage
EOF

    echo "⏳ Esperando a que el pod se inicie..."
    kubectl wait --for=condition=ready pod/backup-lister -n "$NAMESPACE" --timeout=60s
    
    echo ""
    kubectl logs -n "$NAMESPACE" backup-lister
    
    echo ""
    echo "🧹 Limpiando pod temporal..."
    kubectl delete pod backup-lister -n "$NAMESPACE"
else
    echo "Usando pod: $BACKUP_POD"
    kubectl exec -n "$NAMESPACE" "$BACKUP_POD" -- ls -lh /backups/ || {
        echo "⚠️  No se pudo acceder al directorio de backups"
    }
fi

