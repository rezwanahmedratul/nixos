[English](./HOWTO-create-new-git-Branch-and-tag.md) | Español

# CÓMO HACER: Crear Nueva Rama Git y Etiqueta

Esta guía te lleva paso a paso por el proceso de crear una nueva rama de lanzamiento estable y su etiqueta asociada para las versiones de ddubsOS.

## Tabla de Contenidos
- [Resumen](#resumen)
- [Requisitos Previos](#requisitos-previos)
- [Pasos Detallados](#pasos-detallados)
- [Resumen Rápido de Comandos](#resumen-rápido-de-comandos)
- [Mejores Prácticas](#mejores-prácticas)
- [Solución de Problemas](#solución-de-problemas)

## Resumen

Crear un nuevo lanzamiento estable involucra:
1. Crear una nueva rama desde main
2. Crear una etiqueta anotada con notas de lanzamiento
3. Subir tanto la rama como la etiqueta al origin

Este proceso asegura que tengamos instantáneas estables de nuestro código base para lanzamientos mientras mantenemos un flujo de desarrollo limpio.

## Requisitos Previos

- Directorio de trabajo limpio (sin cambios sin confirmar)
- Acceso para subir al repositorio origin
- Rama main más reciente descargada localmente
- Conocimiento de versionado semántico (ej., v2.5.5)

## Pasos Detallados

### Paso 1: Cambiar a la Rama Main y Actualizar

Primero, asegúrate de estar en la rama main y tener los cambios más recientes:

```bash
git checkout main
```

**Salida esperada**: 
```
Already on 'main'
Your branch is up to date with 'origin/main'.
```
*O si cambias desde otra rama:*
```
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```

Descarga los cambios más recientes desde origin:

```bash
git pull origin main
```

**Salida esperada**:
```
From gitlab.com:dwilliam62/ddubsos
 * branch            main       -> FETCH_HEAD
Already up to date.
```
*O si hubo actualizaciones:*
```
From gitlab.com:dwilliam62/ddubsos
 * branch            main       -> FETCH_HEAD
Updating abc1234..def5678
Fast-forward
 file.nix | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

**Propósito**: Esto asegura que tu rama main local coincida exactamente con la rama main remota, para que tu nueva rama de lanzamiento incluya todas las características fusionadas más recientes.

### Paso 2: Crear Nueva Rama Estable

Crea y cambia a una nueva rama estable siguiendo la convención de nombres `Stable-v[VERSIÓN]`:

```bash
git checkout -b Stable-v2.5.5
```

**Salida esperada**:
```
Switched to a new branch 'Stable-v2.5.5'
```

**Propósito**: La bandera `-b` crea una nueva rama e inmediatamente cambia a ella. La rama se basará en cualquier commit en el que te encuentres actualmente (debería ser el main más reciente).

### Paso 3: Verificar Creación de la Rama

Confirma que estás en la nueva rama y verifica que el directorio de trabajo esté limpio:

```bash
git status
```

**Salida esperada**:
```
On branch Stable-v2.5.5
nothing to commit, working tree clean
```

Verifica el historial de commits recientes para confirmar que estás en el commit correcto:

```bash
git log --oneline -3
```

**Salida esperada** (ejemplo):
```
8cd6bf3 (HEAD -> refs/heads/Stable-v2.5.5, refs/remotes/origin/main, refs/remotes/origin/HEAD, refs/heads/main) Merge branch 'wlogout' into 'main'
d828b43 Updated CHANGELOG  with new Spanish text on power menu with -es flag
c78b8ea Merge branch 'wlogout' into 'main'
```

**Propósito**: Esto confirma que la rama fue creada exitosamente y muestra en qué commit se basa. El HEAD debería apuntar a tu nueva rama, y deberías ver los mismos commits que main.

### Paso 4: Crear Etiqueta Anotada con Notas de Lanzamiento

Crea una etiqueta anotada con un mensaje de lanzamiento completo:

```bash
git tag -a v2.5.5 -m "Nuevo Menú de Energía QS - English/Español

La versión v2.5.5 introduce un menú de energía completamente reescrito (qs-wlogout) con:

🔓 Implementación compacta del menú de energía Qt6 QML
  - Ventana flotante pequeña y centrada (520x320px) 
  - Seis opciones de energía: Bloquear, Cerrar Sesión, Suspender, Hibernar, Apagar, Reiniciar
  - Integración adecuada con Hyprland usando hyprctl dispatch exit
  - Estilo semitransparente con esquinas redondeadas
  - Atajos de teclado (L, E, U, H, S, R) y Escape para cerrar

🇪🇸 Soporte de idioma español
  - Usa la bandera -es o la variable de entorno QS_WLOGOUT_SPANISH=1
  - Traducciones completas al español: Bloquear, Cerrar Sesión, Suspender, Hibernar, Apagar, Reiniciar
  - Vinculación configurable de Hyprland para modo español predeterminado

✨ Experiencia de usuario mejorada
  - Eliminadas las cajas grandes de sombra/desenfoque alrededor del área del menú
  - Funcionalidad de click-para-cerrar
  - Iconos PNG de 64x64 con generación de respaldo
  - Runtime Qt6 QML para mejor rendimiento"
```

**Salida esperada**: *(Sin salida en caso de éxito)*

**Propósito**: La bandera `-a` crea una etiqueta anotada (recomendada para lanzamientos) y `-m` proporciona el mensaje. Las etiquetas anotadas almacenan la información del etiquetador y se tratan como objetos completos en Git.

**Pautas para Mensajes de Etiqueta**:
- Comienza con un título corto y descriptivo
- Incluye características principales y mejoras
- Usa emojis para claridad visual
- Sé específico sobre cambios visibles al usuario
- Menciona cambios incompatibles si los hay

### Paso 5: Verificar Creación de la Etiqueta

Verifica que la etiqueta fue creada correctamente:

```bash
git tag -l -n9 v2.5.5
```

**Salida esperada**:
```
v2.5.5          Nuevo Menú de Energía QS - English/Español
    
    La versión v2.5.5 introduce un menú de energía completamente reescrito (qs-wlogout) con:
    
    🔓 Implementación compacta del menú de energía Qt6 QML
      - Ventana flotante pequeña y centrada (520x320px)
      - Seis opciones de energía: Bloquear, Cerrar Sesión, Suspender, Hibernar, Apagar, Reiniciar
      - Integración adecuada con Hyprland usando hyprctl dispatch exit
      - Estilo semitransparente con esquinas redondeadas
```

**Propósito**: La bandera `-l` lista etiquetas, `-n9` muestra las primeras 9 líneas de la anotación. Esto confirma que la etiqueta existe y tiene el mensaje correcto.

### Paso 6: Subir Rama al Origin

Sube la nueva rama al repositorio remoto:

```bash
git push origin Stable-v2.5.5
```

**Salida esperada**:
```
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
remote: 
remote: To create a merge request for Stable-v2.5.5, visit:
remote:   https://gitlab.com/dwilliam62/ddubsos/-/merge_requests/new?merge_request%5Bsource_branch%5D=Stable-v2.5.5
remote: 
To gitlab.com:dwilliam62/ddubsos
 * [new branch]      Stable-v2.5.5 -> Stable-v2.5.5
```

**Propósito**: Esto crea la rama en el repositorio remoto (GitLab/GitHub). El `* [new branch]` indica que es una nueva rama remota.

### Paso 7: Subir Etiqueta al Origin

Sube la etiqueta al repositorio remoto:

```bash
git push origin v2.5.5
```

**Salida esperada**:
```
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 733 bytes | 733.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To gitlab.com:dwilliam62/ddubsos
 * [new tag]         v2.5.5 -> v2.5.5
```

**Propósito**: Esto crea la etiqueta en el repositorio remoto. El `* [new tag]` indica que es una nueva etiqueta remota. Las etiquetas deben subirse explícitamente (no se suben automáticamente con `git push`).

### Paso 8: Verificar Creación Remota

Confirma que tanto la rama como la etiqueta existen localmente y remotamente:

```bash
git branch -v
```

**Salida esperada**:
```
  Stable-v2.5.4 5a8e18f Refixing guestures.nix for 0.51
* Stable-v2.5.5 8cd6bf3 Merge branch 'wlogout' into 'main'
  main          8cd6bf3 Merge branch 'wlogout' into 'main'
```

El `*` indica la rama actual.

```bash
git tag --list | tail -5
```

**Salida esperada**:
```
v2.5.1
v2.5.2
v2.5.3
v2.5.4
v2.5.5
```

**Propósito**: Esto confirma que tanto la rama como la etiqueta fueron creadas exitosamente y muestra la progresión de versiones.

## Resumen Rápido de Comandos

Para usuarios experimentados, aquí están los comandos esenciales para crear una nueva rama de lanzamiento y etiqueta:

```bash
# 1. Cambiar y actualizar main
git checkout main
git pull origin main

# 2. Crear y cambiar a nueva rama estable
git checkout -b Stable-v2.5.5

# 3. Crear etiqueta anotada con notas de lanzamiento
git tag -a v2.5.5 -m "Título del Lanzamiento

Notas detalladas del lanzamiento con:
- Descripciones de características
- Mejoras
- Cambios incompatibles
- Ejemplos de uso"

# 4. Subir rama y etiqueta al origin
git push origin Stable-v2.5.5
git push origin v2.5.5

# 5. Opcional: Regresar a main para desarrollo continuo
git checkout main
```

## Mejores Prácticas

### Convenciones de Nomenclatura
- **Ramas**: `Stable-v[MAYOR].[MENOR].[PARCHE]` (ej., `Stable-v2.5.5`)
- **Etiquetas**: `v[MAYOR].[MENOR].[PARCHE]` (ej., `v2.5.5`)
- Sigue [Versionado Semántico](https://semver.org/):
  - **MAYOR**: Cambios incompatibles de API
  - **MENOR**: Nueva funcionalidad, compatible hacia atrás
  - **PARCHE**: Corrección de errores, compatible hacia atrás

### Pautas para Notas de Lanzamiento
- Usa un título claro y descriptivo
- Agrupa cambios por categoría (🔓 Características, 🐛 Corrección de Errores, ✨ Mejoras)
- Usa emojis para organización visual
- Incluye ejemplos específicos e instrucciones de uso
- Menciona cualquier cambio incompatible de manera prominente
- Mantén lenguaje orientado al usuario (evita jerga técnica)

### Gestión de Ramas
- Siempre crea ramas estables desde main
- Mantén ramas estables para lanzamientos importantes
- No hagas commits directos a ramas estables después de crearlas
- Usa ramas estables para hotfixes si es necesario

### Gestión de Etiquetas
- Siempre usa etiquetas anotadas para lanzamientos (bandera `-a`)
- Las etiquetas son inmutables - no modifiques después de subir
- Incluye notas de lanzamiento completas en mensajes de etiqueta
- Sube etiquetas explícitamente (`git push origin nombre-etiqueta`)

## Solución de Problemas

### Problemas Comunes y Soluciones

#### Error "Already exists" (Ya existe)
```bash
error: tag 'v2.5.5' already exists
```
**Solución**: Verifica etiquetas existentes e incrementa la versión:
```bash
git tag --list | grep v2.5
# Usa el siguiente número de versión disponible
```

#### La Rama Ya Existe
```bash
fatal: A branch named 'Stable-v2.5.5' already exists.
```
**Solución**: Usa la rama existente o elimínala primero:
```bash
git branch -D Stable-v2.5.5  # Elimina rama local
git push origin --delete Stable-v2.5.5  # Elimina rama remota (si existe)
```

#### No Está en el Main Más Reciente
Si tu rama main está detrás de origin/main:
```bash
git pull origin main  # Descarga cambios más recientes
# Luego reinicia el proceso
```

#### Permiso Denegado al Subir
```bash
error: failed to push some refs to 'origin'
```
**Solución**: Asegúrate de tener acceso de escritura al repositorio y estar autenticado correctamente.

#### Push Accidental al Remote Equivocado
**Prevención**: Siempre verifica el remote con:
```bash
git remote -v
```

#### La Etiqueta Apunta al Commit Equivocado
**Solución**: Elimina y recrea la etiqueta (si aún no se ha subido):
```bash
git tag -d v2.5.5  # Elimina etiqueta local
git tag -a v2.5.5 -m "Mensaje correcto"  # Recrea
```

### Comandos de Verificación

Antes de crear lanzamientos, verifica tu entorno:

```bash
# Verifica rama actual y estado
git status

# Verifica commits recientes
git log --oneline -5

# Verifica ramas existentes
git branch -a

# Verifica etiquetas existentes
git tag --list

# Verifica configuración remota
git remote -v
```

---

## Notas

- Este proceso está diseñado para el flujo de trabajo de desarrollo de ddubsOS
- Adapta los mensajes de etiqueta para tu contenido de lanzamiento específico
- Considera actualizar CHANGELOG.ddubs.md antes de crear lanzamientos
- Las ramas estables pueden usarse para hotfixes si es necesario
- Las etiquetas crean instantáneas inmutables para fácil rollback

Para preguntas o problemas con este proceso, consulta la documentación de ddubsOS o crea un issue en el repositorio.
