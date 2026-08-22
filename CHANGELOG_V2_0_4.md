# Gimforze v2.0.4

## Corrección de estabilidad Flutter

- Corregido el ciclo de vida de `TextEditingController` usados por diálogos y bottom sheets: se liberan después del frame en el que termina la ruta.
- Corregido el flujo de creación de rutinas para no notificar `AppState` mientras se está cerrando el diálogo/abriendo el editor.
- El editor guarda sin notificar durante la transición y la pantalla de rutinas refresca cuando el editor ya ha terminado de desmontarse.
- Corregido el mismo patrón en la edición de ejercicios, objetivos de progresión y registro de series.
- Objetivo: eliminar el error Flutter `'_dependents.isEmpty': is not true` que aparecía aunque los datos sí se guardaban.
