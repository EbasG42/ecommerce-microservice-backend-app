#!/usr/bin/env python3
"""
Script para corregir los tags de Docker en todos los workflows
"""
import re
import glob

# Encontrar todos los workflows push
workflows = glob.glob('.github/workflows/*-push.yml')

for wf in workflows:
    with open(wf, 'r') as f:
        content = f.read()
    
    original = content
    
    # Reemplazar PROJECT_VERSION con un valor por defecto
    # Si PROJECT_VERSION está vacío, usar '1.0.0'
    
    # Patrón 1: ${{ secrets.PROJECT_VERSION }}dev
    content = re.sub(
        r'\$\{\{\s*secrets\.PROJECT_VERSION\s*\}\}dev',
        r"${{ secrets.PROJECT_VERSION || '1.0.0' }}dev",
        content
    )
    
    # Patrón 2: ${{ secrets.PROJECT_VERSION }}stage
    content = re.sub(
        r'\$\{\{\s*secrets\.PROJECT_VERSION\s*\}\}stage',
        r"${{ secrets.PROJECT_VERSION || '1.0.0' }}stage",
        content
    )
    
    # Patrón 3: ${{ secrets.PROJECT_VERSION }} (solo, sin sufijo)
    # Usar lookahead negativo para no capturar cuando hay sufijo
    content = re.sub(
        r'\$\{\{\s*secrets\.PROJECT_VERSION\s*\}\}(?![a-z])',
        r"${{ secrets.PROJECT_VERSION || '1.0.0' }}",
        content
    )
    
    if content != original:
        with open(wf, 'w') as f:
            f.write(content)
        print(f'✅ Corregido: {wf}')

print('\n✅ Todos los workflows corregidos')

