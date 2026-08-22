# EvolvAI v1.2.1

- Corrige el bloqueo al iniciar un entrenamiento en Android.
- La restauración del borrador de entrenamiento ya no accede a AppStateScope durante initState.
- La restauración se difiere al primer frame para evitar que la pantalla quede indefinidamente en el spinner.
- A partir de esta versión, la validación funcional se prioriza en dispositivo Android real.
