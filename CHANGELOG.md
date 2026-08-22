# EvolvAI v0.5.1

Correcciones de compilación detectadas en la primera prueba Android de v0.5.0:
- Corrección del uso de Canvas.drawLine con Offset/Offset/Paint.
- Separación de Paint para ejes y curva.
- Eliminación del widget_test.dart generado automáticamente por `flutter create`.
- Incremento de versión a 0.5.1+6.

## v0.5.2
- Fixed ProfilePage inherited-widget lifecycle error by moving AppState access from initState to didChangeDependencies.
- Spanish UI terminology tightened in exercise catalog.
- Exercise localization is now a hard product requirement; English exercise instructions are not considered final.

## 0.6.0 — Rutinas + EvolvAI
- Navegación principal en español orientada al entrenamiento.
- Soporte para múltiples rutinas con día de la semana.
- Creación manual de rutinas.
- Plan semanal y pantalla de entrenamiento de hoy.
- Primera pantalla EvolvAI para generar propuestas de rutina localmente.
- Migración compatible desde `workout.plan` antiguo.
- Persistencia de rutinas múltiples.

## v0.6.3
- Volumen por grupo muscular en español.
- Barras comparativas de distribución del volumen mensual.
- Clasificación compatible con sesiones históricas que solo almacenan el nombre del ejercicio.
- Tests de clasificación y cálculo de volumen por grupo muscular.
