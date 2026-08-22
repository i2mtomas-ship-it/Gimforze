# Gimforze v2.0.3

## Corrección de creación/edición de rutinas

- Evita notificar el `InheritedNotifier` mientras se está cerrando/abriendo una ruta.
- La rutina se persiste y la interfaz se actualiza cuando la pantalla editora sigue montada.
- Se espera al final del frame antes de navegar, evitando la excepción fugaz `_dependents.isEmpty` al crear o guardar una rutina.
- Mantiene el guardado de datos y el `applicationId` existente para conservar los datos locales.
