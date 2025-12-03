#!/usr/bin/env python3
import yaml
import sys
from pathlib import Path

errors = []
files_checked = 0

def validate_yaml_file(filepath):
    global files_checked
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            # Handle multiple YAML documents
            for doc in yaml.safe_load_all(content):
                if doc is not None:
                    files_checked += 1
        return True
    except yaml.YAMLError as e:
        errors.append(f'{filepath}: {e}')
        return False
    except Exception as e:
        errors.append(f'{filepath}: {e}')
        return False

# Validate key files
key_files = [
    'k8s/namespaces/namespaces.yaml',
    'k8s/storage/storage-class.yaml',
    'k8s/databases/postgres-statefulset.yaml',
    'k8s/services/user_service/deployment.yaml',
    'k8s/config/user-service-configmap.yaml',
    'k8s/secrets/user-service-secret.yaml',
    'k8s/ingress/ingress.yaml',
    'k8s/network-policies/default-deny.yaml',
    'k8s/rbac/service-accounts.yaml',
    'k8s/autoscaling/hpa-user-service.yaml'
]

print('Validando archivos YAML clave...')
for file in key_files:
    path = Path(file)
    if path.exists():
        if validate_yaml_file(path):
            print(f'  âœ… {file}')
        else:
            print(f'  âŒ {file}')
    else:
        print(f'  âš ï¸  {file} no encontrado')

if errors:
    print(f'\nâŒ Errores encontrados: {len(errors)}')
    for error in errors:
        print(f'  {error}')
    sys.exit(1)
else:
    print(f'\nâœ… Todos los archivos validados correctamente ({files_checked} documentos)')
