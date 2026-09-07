# CÓMO: Personalizar procps-ng top (Español)

Audiencia: usuarios de ddubsOS en Linux usando procps-ng top. Esta guía explica teclas rápidas para obtener barras de estado y color (al estilo htop), cómo guardar, dónde vive el archivo de configuración y cómo este repositorio preserva tu tema con Home Manager.

Resumen rápido
- Inicia top
- Pulsa:
  - t: Resumen de CPU → barras
  - m: Resumen de memoria → barras
  - 1: CPU por núcleo
  - z: Activar/desactivar color
  - Shift+Z: Menú de colores (cambia colores por grupo)
  - x: Resaltar columna ordenada; y: mostrar campo de orden
  - Shift+W: Guardar en ~/.config/procps/toprc


1) Básicos: activar barras y color
- Barras de CPU: pulsa t varias veces hasta ver barras en el resumen de CPU.
- Barras de memoria: pulsa m varias veces hasta ver barras para Mem/Swap.
- Ver por CPU: pulsa 1 para expandir CPUs a líneas separadas.
- Modo color: pulsa z para activar/desactivar color global.
- Ajuste de color: pulsa Shift+Z (Z mayúscula) para abrir el menú de colores. Elige un grupo (Summary, Messages, Header, Task) y ajusta fg/bg/negrita. Sal con q.
- Guardar tu diseño/colores: pulsa Shift+W (W mayúscula).

Consejo: Si los colores se ven mal con tu tema de terminal, usa Shift+Z para cambiar la paleta y luego Shift+W para guardar.


2) Orden, columnas y legibilidad
- Resaltar columna de orden: x
- Mostrar el campo de orden en el encabezado: y
- Elegir el campo de orden: F (mayúscula) o f abre el menú de Campos/Orden; selecciona el campo (p. ej., %CPU, %MEM, TIME+).
- Añadir/quitar columnas: f (Campos) activa/desactiva visibilidad por columna.
- Reordenar columnas: o (minúscula) dentro del menú de Campos permite cambiar el orden.
- Mostrar línea de comandos vs nombre del programa: c
- Mostrar hilos: H
- Ocultar tareas inactivas: i
- Vista en árbol (forest): V

Notas: Las teclas pueden variar ligeramente según la versión de procps-ng. Presiona h dentro de top para la ayuda integrada.


3) Unidades y modos
- Escalas de memoria: E (global) y/o e (área de tareas) alterna entre KiB/MiB/GiB.
- CPU acumulado: S activa el modo acumulado por proceso.
- Modo Irix vs Solaris (normalización de CPU): I alterna si un proceso puede exceder 100% en sistemas multinúcleo.


4) Dónde se guarda la configuración
- procps-ng top escribe en la ruta XDG:
  - ~/.config/procps/toprc
- Documentación antigua menciona ~/.toprc, pero tu compilación usa la ruta anterior.


5) Solución de problemas
- Error "incompatible rcfile": elimina el rc actual para que top genere uno nuevo; luego vuelve a personalizar y guarda.
  ```bash path=null start=null
  rm -f ~/.config/procps/toprc
  # Reinicia top, aplica t/m/1/z/Z y luego Shift+W para guardar
  ```
- Sin barras o color: pulsa t y m para barras, z para color. Algunos temas reducen el contraste; usa Shift+Z para ajustar.
- Falta ver por CPU: pulsa 1.


6) Preservar tu tema en este repositorio (Home Manager)
Este repo tiene una activación de Home Manager que ayuda a preservar tu tema sin hacerlo de solo lectura:
- Ubicación en el repo: modules/home/cli/procps-toprc.nix
- Comportamiento (semilla-una-vez, editable):
  - Si ~/.config/procps/toprc existe y el repo NO tiene copia aún, copia vivo → repo en el rebuild (captura inicial).
  - Si el repo tiene copia y en tu home falta el archivo, instala repo → ~/.config/procps/toprc (semilla inicial).
  - Cuando ambos existen, no toca nada para que puedas seguir usando Shift+W.

Actualizar la copia del repo cuando estés conforme:
```bash path=null start=null
cp ~/.config/procps/toprc ~/ddubsos/modules/home/cli/procps-toprc
# Luego reconstruye para que la versión del repo quede bajo tu configuración
zcli rebuild
```


7) Flujo de trabajo de ejemplo
1. Ejecuta top, pulsa t, m, 1, z, Shift+Z para ajustar colores.
2. Pulsa Shift+W para guardar.
3. Ejecuta zcli rebuild. La activación detectará y capturará tu toprc vivo al repo si falta allí.
4. Haz commit de la copia en el repo si quieres.
