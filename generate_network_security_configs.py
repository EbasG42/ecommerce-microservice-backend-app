#!/usr/bin/env python3
"""
Script para generar configuraciones de Networking y Seguridad
"""
import yaml
from pathlib import Path

BASE_DIR = Path('/home/user/plataformas-ii/ecommerce-microservice-backend-app')
K8S_DIR = BASE_DIR / 'k8s'

def create_network_policies():
    """Crear Network Policies"""
    
    # Default Deny All
    default_deny = {
        'apiVersion': 'networking.k8s.io/v1',
        'kind': 'NetworkPolicy',
        'metadata': {'name': 'default-deny-all', 'namespace': 'dev'},
        'spec': {
            'podSelector': {},
            'policyTypes': ['Ingress', 'Egress']
        }
    }
    
    # Allow Discovery
    allow_discovery = {
        'apiVersion': 'networking.k8s.io/v1',
        'kind': 'NetworkPolicy',
        'metadata': {'name': 'allow-to-discovery', 'namespace': 'dev'},
        'spec': {
            'podSelector': {'matchLabels': {'app': 'service-discovery'}},
            'policyTypes': ['Ingress'],
            'ingress': [{
                'from': [{'podSelector': {}}],
                'ports': [{'protocol': 'TCP', 'port': 8761}]
            }]
        }
    }
    
    # Allow Business Services
    allow_business = {
        'apiVersion': 'networking.k8s.io/v1',
        'kind': 'NetworkPolicy',
        'metadata': {'name': 'allow-business-services', 'namespace': 'dev'},
        'spec': {
            'podSelector': {'matchLabels': {'tier': 'business'}},
            'policyTypes': ['Ingress', 'Egress'],
            'ingress': [{
                'from': [{'podSelector': {'matchLabels': {'app': 'api-gateway'}}}],
                'ports': [
                    {'protocol': 'TCP', 'port': 8081},
                    {'protocol': 'TCP', 'port': 8082},
                    {'protocol': 'TCP', 'port': 8083},
                    {'protocol': 'TCP', 'port': 8084},
                    {'protocol': 'TCP', 'port': 8085},
                    {'protocol': 'TCP', 'port': 8086}
                ]
            }],
            'egress': [
                {
                    'to': [{'podSelector': {'matchLabels': {'app': 'service-discovery'}}}],
                    'ports': [{'protocol': 'TCP', 'port': 8761}]
                },
                {
                    'to': [{'podSelector': {'matchLabels': {'app': 'cloud-config-server'}}}],
                    'ports': [{'protocol': 'TCP', 'port': 8888}]
                },
                {
                    'to': [{'podSelector': {'matchLabels': {'app': 'postgres'}}}],
                    'ports': [{'protocol': 'TCP', 'port': 5432}]
                },
                {
                    'ports': [{'protocol': 'UDP', 'port': 53}, {'protocol': 'TCP', 'port': 53}]
                }
            ]
        }
    }
    
    return [default_deny, allow_discovery, allow_business]

def create_rbac():
    """Crear RBAC configurations"""
    
    service_account = {
        'apiVersion': 'v1',
        'kind': 'ServiceAccount',
        'metadata': {'name': 'microservice-sa', 'namespace': 'dev'}
    }
    
    role = {
        'apiVersion': 'rbac.authorization.k8s.io/v1',
        'kind': 'Role',
        'metadata': {'name': 'microservice-role', 'namespace': 'dev'},
        'rules': [
            {
                'apiGroups': [''],
                'resources': ['pods', 'services', 'configmaps'],
                'verbs': ['get', 'list', 'watch']
            },
            {
                'apiGroups': [''],
                'resources': ['secrets'],
                'verbs': ['get']
            }
        ]
    }
    
    role_binding = {
        'apiVersion': 'rbac.authorization.k8s.io/v1',
        'kind': 'RoleBinding',
        'metadata': {'name': 'microservice-rolebinding', 'namespace': 'dev'},
        'subjects': [{'kind': 'ServiceAccount', 'name': 'microservice-sa', 'namespace': 'dev'}],
        'roleRef': {'kind': 'Role', 'name': 'microservice-role', 'apiGroup': 'rbac.authorization.k8s.io'}
    }
    
    return [service_account, role, role_binding]

def create_ingress():
    """Crear Ingress configuration"""
    
    ingress = {
        'apiVersion': 'networking.k8s.io/v1',
        'kind': 'Ingress',
        'metadata': {
            'name': 'ecommerce-ingress',
            'namespace': 'dev',
            'annotations': {
                'nginx.ingress.kubernetes.io/rewrite-target': '/',
                'nginx.ingress.kubernetes.io/ssl-redirect': 'false'
            }
        },
        'spec': {
            'ingressClassName': 'nginx',
            'rules': [
                {
                    'host': 'api.ecommerce.local',
                    'http': {
                        'paths': [{
                            'path': '/',
                            'pathType': 'Prefix',
                            'backend': {'service': {'name': 'api-gateway', 'port': {'number': 8080}}}
                        }]
                    }
                },
                {
                    'host': 'ecommerce.local',
                    'http': {
                        'paths': [{
                            'path': '/',
                            'pathType': 'Prefix',
                            'backend': {'service': {'name': 'proxy-client', 'port': {'number': 4200}}}
                        }]
                    }
                }
            ]
        }
    }
    
    return ingress

def create_hpa():
    """Crear Horizontal Pod Autoscalers"""
    
    services = ['user-service', 'product-service', 'order-service', 'payment-service', 'shipping-service', 'favourite-service']
    hpas = []
    
    for service in services:
        hpa = {
            'apiVersion': 'autoscaling/v2',
            'kind': 'HorizontalPodAutoscaler',
            'metadata': {'name': f'{service}-hpa', 'namespace': 'dev'},
            'spec': {
                'scaleTargetRef': {
                    'apiVersion': 'apps/v1',
                    'kind': 'Deployment',
                    'name': service
                },
                'minReplicas': 2,
                'maxReplicas': 10,
                'metrics': [
                    {
                        'type': 'Resource',
                        'resource': {
                            'name': 'cpu',
                            'target': {'type': 'Utilization', 'averageUtilization': 70}
                        }
                    },
                    {
                        'type': 'Resource',
                        'resource': {
                            'name': 'memory',
                            'target': {'type': 'Utilization', 'averageUtilization': 80}
                        }
                    }
                ],
                'behavior': {
                    'scaleDown': {
                        'stabilizationWindowSeconds': 300,
                        'policies': [{'type': 'Percent', 'value': 50, 'periodSeconds': 60}]
                    },
                    'scaleUp': {
                        'stabilizationWindowSeconds': 0,
                        'policies': [
                            {'type': 'Percent', 'value': 100, 'periodSeconds': 30},
                            {'type': 'Pods', 'value': 2, 'periodSeconds': 30}
                        ],
                        'selectPolicy': 'Max'
                    }
                }
            }
        }
        hpas.append(hpa)
    
    return hpas

if __name__ == '__main__':
    print('🔒 Generando configuraciones de Networking y Seguridad...')
    
    # Network Policies
    (K8S_DIR / 'network-policies').mkdir(parents=True, exist_ok=True)
    policies = create_network_policies()
    for i, policy in enumerate(policies):
        filename = ['default-deny.yaml', 'allow-discovery.yaml', 'allow-business-services.yaml'][i]
        with open(K8S_DIR / 'network-policies' / filename, 'w') as f:
            yaml.dump(policy, f, default_flow_style=False, sort_keys=False)
    print('  ✅ Network Policies')
    
    # RBAC
    (K8S_DIR / 'rbac').mkdir(parents=True, exist_ok=True)
    rbac_configs = create_rbac()
    with open(K8S_DIR / 'rbac' / 'service-accounts.yaml', 'w') as f:
        for config in rbac_configs:
            yaml.dump(config, f, default_flow_style=False, sort_keys=False)
            f.write('---\n')
    print('  ✅ RBAC')
    
    # Ingress
    (K8S_DIR / 'ingress').mkdir(parents=True, exist_ok=True)
    ingress = create_ingress()
    with open(K8S_DIR / 'ingress' / 'ingress.yaml', 'w') as f:
        yaml.dump(ingress, f, default_flow_style=False, sort_keys=False)
    print('  ✅ Ingress')
    
    # HPA
    (K8S_DIR / 'autoscaling').mkdir(parents=True, exist_ok=True)
    hpas = create_hpa()
    for hpa in hpas:
        service_name = hpa['metadata']['name'].replace('-hpa', '')
        with open(K8S_DIR / 'autoscaling' / f'hpa-{service_name}.yaml', 'w') as f:
            yaml.dump(hpa, f, default_flow_style=False, sort_keys=False)
    print('  ✅ HPA')
    
    print('✅ Configuraciones de Networking y Seguridad generadas!')

