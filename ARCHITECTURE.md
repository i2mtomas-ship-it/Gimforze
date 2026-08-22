# Arquitectura EvolvAI v0.1

## Decisión
Flutter/Dart para el cliente. Es la mejor opción inicial para mantener una base de código móvil única para iOS y Android sin convertir la aplicación en una web embebida.

## Capas

- `features/`: módulos de producto.
- `core/`: estado transversal, tema y componentes reutilizables.
- Dominio crítico aislado de la interfaz (ejemplo: `NutritionCalculator`).
- Persistencia encapsulada detrás de `AppState`; en la siguiente iteración se sustituirá por repositorios + SQLite/Drift cuando aumente el modelo de datos.
- Futuro backend: API propia para IA y sincronización; nunca se incluirán claves de proveedor de IA en el cliente.

## Evolución prevista

1. MVP local.
2. Modelo de entrenamiento y progresión.
3. Nutrición y alimentos.
4. Motor de adaptación y API de IA.
5. HealthKit.
6. Integraciones externas.
7. Cuenta/sincronización y backend cuando sean necesarias.
