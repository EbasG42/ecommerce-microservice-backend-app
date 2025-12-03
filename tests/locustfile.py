"""
Locustfile para pruebas de carga del e-commerce
Ejecutar: locust -f tests/locustfile.py --host=http://localhost:8080
"""

from locust import HttpUser, task, between
import random

class EcommerceUser(HttpUser):
    """
    Simula un usuario del e-commerce realizando diferentes acciones
    """
    wait_time = between(1, 3)  # Espera entre 1 y 3 segundos entre requests
    
    def on_start(self):
        """Se ejecuta cuando un usuario virtual inicia"""
        # Opcional: login o inicialización
        pass
    
    @task(3)
    def get_products(self):
        """Obtener lista de productos (alta frecuencia)"""
        self.client.get("/product-service/api/products", name="Get Products")
    
    @task(2)
    def get_product_by_id(self):
        """Obtener un producto específico"""
        product_id = random.randint(1, 100)
        self.client.get(f"/product-service/api/products/{product_id}", name="Get Product by ID")
    
    @task(2)
    def get_users(self):
        """Obtener lista de usuarios"""
        self.client.get("/user-service/api/users", name="Get Users")
    
    @task(1)
    def get_user_by_id(self):
        """Obtener un usuario específico"""
        user_id = random.randint(1, 100)
        self.client.get(f"/user-service/api/users/{user_id}", name="Get User by ID")
    
    @task(1)
    def get_favourites(self):
        """Obtener favoritos de un usuario"""
        user_id = random.randint(1, 100)
        self.client.get(f"/favourite-service/api/favourites/user/{user_id}", name="Get Favourites")
    
    @task(1)
    def get_orders(self):
        """Obtener órdenes"""
        self.client.get("/order-service/api/orders", name="Get Orders")
    
    @task(1)
    def get_order_by_id(self):
        """Obtener una orden específica"""
        order_id = random.randint(1, 100)
        self.client.get(f"/order-service/api/orders/{order_id}", name="Get Order by ID")
    
    @task(1)
    def health_check(self):
        """Health check de los servicios"""
        services = ["user-service", "product-service", "order-service", "payment-service"]
        service = random.choice(services)
        self.client.get(f"/{service}/actuator/health", name="Health Check")

