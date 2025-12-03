#!/usr/bin/env python3
"""
Script para corregir el comando docker login en todos los workflows
"""
import os
import re
import glob

# Encontrar todos los workflows con el problema
workflows = glob.glob('.github/workflows/*.yml') + glob.glob('.github/workflows/*.yaml')
workflows = [w for w in workflows if 'ci-cd.yaml' not in w]  # Excluir el principal que ya está corregido

fixed_count = 0

for workflow_file in workflows:
    try:
        with open(workflow_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Buscar el patrón del comando docker login manual
        # Patrón más flexible para capturar variaciones
        pattern = r'(\s+- name: Docker Login\s+run: echo \$\{\{ secrets\.DOCKER_PASSWORD \}\} \| docker login -u \$\{\{ secrets\.DOCKER_USERNAME \}\} --password-stdin)'
        
        if re.search(pattern, content):
            # Reemplazar con la acción oficial
            replacement = '''    - name: Log in to Docker Hub
      uses: docker/login-action@v3
      with:
        registry: docker.io
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}'''
            
            content = re.sub(pattern, replacement, content)
            
            # También buscar si hay un paso anterior que configure variables de entorno
            # y removerlo si solo es para Docker login
            env_pattern = r'(\s+- name: Setup env variables for Docker\s+run: echo Setup env variables for Docker\s+env:\s+DOCKER_USERNAME: \$\{\{ secrets\.DOCKER_USERNAME \}\}\s+DOCKER_PASSWORD: \$\{\{ secrets\.DOCKER_PASSWORD \}\}\s+)'
            content = re.sub(env_pattern, '', content)
            
            if content != original_content:
                with open(workflow_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'✅ Corregido: {workflow_file}')
                fixed_count += 1
    except Exception as e:
        print(f'❌ Error en {workflow_file}: {e}')

print(f'\n✅ Total de workflows corregidos: {fixed_count}')

