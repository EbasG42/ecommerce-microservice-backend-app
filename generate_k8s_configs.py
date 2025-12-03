#!/usr/bin/env python3
"""
Script para generar todas las configuraciones de Kubernetes
E-Commerce Microservices Platform
"""
import os
import yaml
from pathlib import Path

BASE_DIR = Path('/home/user/plataformas-ii/ecommerce-microservice-backend-app')
K8S_DIR = BASE_DIR / 'k8s'
DOCKER_USER = 'ebasg42'
VERSION = '1.0.0'

SERVICES = {
    'service-discovery': {'port': 8761, 'replicas': 2, 'tier': 'infrastructure'},
    'cloud-config-server': {'port': 8888, 'replicas': 1, 'tier': 'infrastructure'},
    'api-gateway': {'port': 8080, 'replicas': 2, 'tier': 'infrastructure'},
    'user-service': {'port': 8081, 'replicas': 2, 'tier': 'business', 'db': 'userdb'},
    'product-service': {'port': 8082, 'replicas': 2, 'tier': 'business', 'db': 'productdb'},
    'favourite-service': {'port': 8083, 'replicas': 2, 'tier': 'business', 'db': 'favouritedb'},
    'order-service': {'port': 8084, 'replicas': 2, 'tier': 'business', 'db': 'orderdb'},
    'shipping-service': {'port': 8085, 'replicas': 2, 'tier': 'business', 'db': 'shippingdb'},
    'payment-service': {'port': 8086, 'replicas': 2, 'tier': 'business', 'db': 'paymentdb'},
    'proxy-client': {'port': 4200, 'replicas': 1, 'tier': 'client'},
}

def create_deployment(service_name, config):
    port = config['port']
    replicas = config['replicas']
    tier = config['tier']
    needs_db = 'db' in config
    
    deployment = {
        'apiVersion': 'apps/v1',
        'kind': 'Deployment',
        'metadata': {
            'name': service_name,
            'namespace': 'dev',
            'labels': {'app': service_name, 'tier': tier, 'version': 'v1'}
        },
        'spec': {
            'replicas': replicas,
            'selector': {'matchLabels': {'app': service_name}},
            'template': {
                'metadata': {'labels': {'app': service_name, 'tier': tier, 'version': 'v1', 'metrics': 'enabled'}},
                'spec': {
                    'securityContext': {'runAsNonRoot': True, 'runAsUser': 1000, 'fsGroup': 1000},
                    'containers': [{
                        'name': service_name,
                        'image': f'{DOCKER_USER}/{service_name}:{VERSION}',
                        'ports': [{'containerPort': port, 'name': 'http'}],
                        'env': [
                            {'name': 'SPRING_PROFILES_ACTIVE', 'value': 'kubernetes'},
                            {'name': 'EUREKA_CLIENT_SERVICEURL_DEFAULTZONE', 'value': 'http://service-discovery:8761/eureka/'},
                            {'name': 'SPRING_CLOUD_CONFIG_URI', 'value': 'http://cloud-config-server:8888'}
                        ],
                        'resources': {'requests': {'memory': '512Mi', 'cpu': '250m'}, 'limits': {'memory': '1Gi', 'cpu': '500m'}},
                        'livenessProbe': {'httpGet': {'path': '/actuator/health/liveness', 'port': port}, 'initialDelaySeconds': 90 if needs_db else 60, 'periodSeconds': 10},
                        'readinessProbe': {'httpGet': {'path': '/actuator/health/readiness', 'port': port}, 'initialDelaySeconds': 60 if needs_db else 30, 'periodSeconds': 5}
                    }]
                }
            }
        }
    }
    
    if needs_db:
        db_name = config['db']
        deployment['spec']['template']['spec']['initContainers'] = [{
            'name': 'wait-for-db',
            'image': 'busybox:1.35',
            'command': ['sh', '-c', 'until nc -z postgres 5432; do echo waiting for postgres; sleep 2; done;']
        }]
        deployment['spec']['template']['spec']['containers'][0]['env'].extend([
            {'name': 'SPRING_DATASOURCE_URL', 'valueFrom': {'configMapKeyRef': {'name': f'{service_name}-config', 'key': 'database.url'}}},
            {'name': 'SPRING_DATASOURCE_USERNAME', 'valueFrom': {'secretKeyRef': {'name': f'{service_name}-secret', 'key': 'database.username'}}},
            {'name': 'SPRING_DATASOURCE_PASSWORD', 'valueFrom': {'secretKeyRef': {'name': f'{service_name}-secret', 'key': 'database.password'}}}
        ])
    
    service = {
        'apiVersion': 'v1',
        'kind': 'Service',
        'metadata': {'name': service_name, 'namespace': 'dev', 'labels': {'app': service_name, 'metrics': 'enabled'}},
        'spec': {'type': 'ClusterIP', 'ports': [{'port': port, 'targetPort': port, 'protocol': 'TCP', 'name': 'http'}], 'selector': {'app': service_name}}
    }
    
    return deployment, service

def create_configmap(service_name, config):
    port = config['port']
    needs_db = 'db' in config
    
    app_yml = f'''server:
  port: {port}
spring:
  application:
    name: {service_name}
  cloud:
    config:
      uri: http://cloud-config-server:8888
eureka:
  client:
    service-url:
      defaultZone: http://service-discovery:8761/eureka/
  instance:
    prefer-ip-address: true
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: {service_name}
      environment: dev
'''
    
    data = {'application.yml': app_yml}
    
    if needs_db:
        db_name = config['db']
        data['database.url'] = f'jdbc:postgresql://postgres:5432/{db_name}'
        data['database.driver'] = 'org.postgresql.Driver'
        data['application.yml'] += f'''
spring:
  datasource:
    url: ${{database.url}}
    driver-class-name: ${{database.driver}}
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
'''
    
    return {'apiVersion': 'v1', 'kind': 'ConfigMap', 'metadata': {'name': f'{service_name}-config', 'namespace': 'dev'}, 'data': data}

def create_secret(service_name, config):
    if 'db' not in config:
        return None
    db_name = config['db']
    username = db_name.replace('db', 'service')
    return {
        'apiVersion': 'v1',
        'kind': 'Secret',
        'metadata': {'name': f'{service_name}-secret', 'namespace': 'dev'},
        'type': 'Opaque',
        'stringData': {'database.username': username, 'database.password': f'{username}pass123'}
    }

if __name__ == '__main__':
    print('🚀 Generando configuraciones de Kubernetes...')
    
    # Crear directorios
    (K8S_DIR / 'config').mkdir(parents=True, exist_ok=True)
    (K8S_DIR / 'secrets').mkdir(parents=True, exist_ok=True)
    for service_name in SERVICES.keys():
        (K8S_DIR / 'services' / service_name.replace('-', '_')).mkdir(parents=True, exist_ok=True)
    
    # Generar configuraciones
    for service_name, config in SERVICES.items():
        service_dir = K8S_DIR / 'services' / service_name.replace('-', '_')
        deployment, service = create_deployment(service_name, config)
        
        with open(service_dir / 'deployment.yaml', 'w') as f:
            yaml.dump(deployment, f, default_flow_style=False, sort_keys=False)
            f.write('---\n')
            yaml.dump(service, f, default_flow_style=False, sort_keys=False)
        
        configmap = create_configmap(service_name, config)
        with open(K8S_DIR / 'config' / f'{service_name}-configmap.yaml', 'w') as f:
            yaml.dump(configmap, f, default_flow_style=False, sort_keys=False)
        
        secret = create_secret(service_name, config)
        if secret:
            with open(K8S_DIR / 'secrets' / f'{service_name}-secret.yaml', 'w') as f:
                yaml.dump(secret, f, default_flow_style=False, sort_keys=False)
        
        print(f'  ✅ {service_name}')
    
    print('✅ Configuraciones generadas exitosamente!')

