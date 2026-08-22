# Gimforze v2.0.0

## Cambio de marca
- EvolvAI pasa a llamarse **Gimforze**.
- Nueva identidad visual oscura, morado eléctrico y logotipo de puño sujetando una mancuerna.
- Se conserva el almacenamiento local existente para facilitar la actualización en Android.

## Correcciones funcionales
- Guardado de rutinas protegido frente a notificaciones durante ciclos de construcción de Flutter.
- Guardado de series protegido y con confirmación visual dentro del entrenamiento, sin depender de SnackBar.
- Finalización de entrenamiento devuelve el resultado al flujo anterior sin usar un `BuildContext` después de hacer `pop`.
- Próximas rutinas son completamente pulsables y abren la rutina correspondiente.
- Catálogo bilingüe ES/EN: se evita mostrar nombres latinos o traducciones no deseadas como segundo nombre.
- Locale español inicializado al arrancar.

## Gamificación
- Logros y medallas por continuidad, entrenamientos, récords y volumen.
- Rachas de entrenamiento.
- XP y niveles.
- Detección de nuevos récords personales.
- Celebración de nuevos logros al finalizar una sesión.

## Coach
- EvolvAI Coach pasa a **Gimforze Coach**.
- Mantiene recomendaciones basadas exclusivamente en datos registrados.
