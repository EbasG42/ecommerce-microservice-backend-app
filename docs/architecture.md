# Arquitectura E-Commerce Microservicios

## Servicios Identificados

### Servicios de Infraestructura
1. **Service Discovery (Eureka)**: Puerto 8761
2. **Cloud Config Server**: Puerto 8888
3. **API Gateway**: Puerto 8080

### Servicios de Negocio
4. **User Service**: Gestión de usuarios
5. **Product Service**: Catálogo de productos
6. **Favourite Service**: Favoritos de usuarios
7. **Order Service**: Gestión de pedidos
8. **Shipping Service**: Envíos
9. **Payment Service**: Pagos

### Cliente
10. **Proxy Client**: Interfaz de usuario

## Dependencias entre Servicios
```
Config Server (primero)
    ↓
Service Discovery (segundo)
    ↓
Servicios de Negocio (tercero)
    ↓
API Gateway (cuarto)
    ↓
Proxy Client (último)
```

## Bases de Datos Identificadas
- PostgreSQL para servicios de negocio
- MySQL (según configuración original)
