# Cliente de Copias de Seguridad de Proxmox (ayudantes ddubsOS)

Este repositorio instala atajos (wrappers) sobre proxmox-backup-client para hacer copias y restaurar tu directorio home de forma consistente en todos los equipos.

Ayudantes instalados

- pbs-home-backup: crea/actualiza una copia de tu home (archivo pxar)
- pbs-home-ls: lista snapshots de tu grupo de copia
- pbs-home-last: muestra el ID del snapshot más reciente
- pbs-home-restore: restaura un snapshot específico a un directorio
- pbs-home-restore-last: restaura el snapshot más reciente
- pbs-home-ls-all: lista todos los snapshots del repositorio (no filtrado por BACKUP_ID)
- pbs-home-show: muestra repo/huella/backup-id/ruta origen efectivos
- pbs-home-prune: elimina snapshots según política de retención del grupo
- pbs-home-verify: verifica el último (por defecto) o todos los snapshots del grupo

Valores por defecto (puedes sobreescribirlos con variables de entorno)

- Repositorio: root@pam@192.168.40.15:8007:PBS-LUN2
- Huella (SHA-256): 4b:c6:2a:49:62:2e:c6:0d:63:0c:d1:b6:8b:78:be:af:28:2a:94:eb:d4:e7:77:ab:d1:af:c9:ea:c9:07:ef:26
- Grupo de copia (BACKUP_ID): <hostname>-dwilliams-home
- Ruta origen: /home/dwilliams

Variables de entorno (todas opcionales)

- PBS_REPOSITORY: repositorio de Proxmox Backup Server (user@realm@host:port:datastore)
- PBS_FINGERPRINT: huella SHA-256 del certificado TLS del PBS
- PBS_PASSWORD: contraseña del usuario PBS (o secreto del token API)
- BACKUP_ID: ID del grupo de copia (por defecto: <hostname>-dwilliams-home)
- PBS_ENCRYPTION_KEY_FILE: ruta de la clave de cifrado del cliente (opcional)

Los ayudantes pedirán PBS_PASSWORD si no está definido.

Requisitos previos

1) Verifica la huella TLS del servidor PBS:
   openssl s_client -connect 192.168.40.15:8007 -servername 192.168.40.15 </dev/null 2>/dev/null \
   | openssl x509 -noout -fingerprint -sha256
   Compara con la huella indicada arriba; si difiere:
   - exporta PBS_FINGERPRINT=... en tu shell, o
   - actualiza el valor por defecto en el módulo y reconstruye.

2) Credenciales:
   - Usuario con contraseña: root@pam con la contraseña de root en PBS
   - Token API: root@pam!TOKENID con PBS_PASSWORD igual al secreto del token

Cifrado del lado del cliente (opcional y recomendado)

Puedes cifrar los archivos pxar en el cliente; guarda la clave de forma segura.

mkdir -p ~/.config/proxmox-backup
proxmox-backup-client key create --kdf scrypt --out ~/.config/proxmox-backup/home.enc.key
chmod 600 ~/.config/proxmox-backup/home.enc.key
export PBS_ENCRYPTION_KEY_FILE=$HOME/.config/proxmox-backup/home.enc.key

Uso

Configura el entorno (opcional; hay valores por defecto):

export PBS_REPOSITORY="root@pam@192.168.40.15:8007:PBS-LUN2"
export PBS_FINGERPRINT="4b:c6:2a:49:62:2e:c6:0d:63:0c:d1:b6:8b:78:be:af:28:2a:94:eb:d4:e7:77:ab:d1:af:c9:ea:c9:07:ef:26"
# Opcional: sobrescribe el grupo si tu hostname difiere
# export BACKUP_ID=ixas-dwilliams-home
read -s PBS_PASSWORD && export PBS_PASSWORD

1) Crear una copia de tu home

pbs-home-backup \
  --exclude '.cache/**' \
  --exclude '.local/share/Trash/**'

Notas:
- Puedes añadir más patrones --exclude según necesites.
- Si PBS_ENCRYPTION_KEY_FILE está definido, la copia se cifra en el cliente.

2) Listar snapshots de tu grupo de copia

pbs-home-ls
# Salida JSON bonita:
pbs-home-ls --output-format json-pretty

3) Mostrar el snapshot más reciente

pbs-home-last

4) Restaurar un snapshot específico en un directorio

# Usa un ID de snapshot de pbs-home-ls o pbs-home-last
pbs-home-restore 2025-09-24T02:10:45Z /home/dwilliams/restore

5) Restaurar el snapshot más reciente

pbs-home-restore-last /home/dwilliams/restore
# O sin directorio destino para restaurar a ~/restore-<SNAPSHOT>
pbs-home-restore-last

Restaurar solo un archivo o subdirectorio

Puedes restaurar selectivamente rutas del archivo pxar usando --include. Las rutas son relativas a la raíz del archivo (tu home).

# Restaurar un archivo concreto de un snapshot
proxmox-backup-client restore \
  --repository "$PBS_REPOSITORY" \
  host/$BACKUP_ID/2025-09-24T02:10:45Z \
  home.pxar \
  /home/dwilliams/restore \
  --allow-existing-dirs \
  --include 'Documents/important.pdf'

# Restaurar solo un subdirectorio
proxmox-backup-client restore \
  --repository "$PBS_REPOSITORY" \
  host/$BACKUP_ID/2025-09-24T02:10:45Z \
  home.pxar \
  /home/dwilliams/restore \
  --allow-existing-dirs \
  --include 'Pictures/Wallpapers/**'

Consejos:
- Omite --include para restaurar todo el archivo.
- Usa múltiples --include para varios archivos/rutas.

6) Listar todos los snapshots del repositorio (no filtrado por BACKUP_ID)

pbs-home-ls-all
# JSON-pretty con el comando base si lo necesitas:
proxmox-backup-client snapshot list --repository "$PBS_REPOSITORY" --output-format json-pretty

7) Mostrar configuración efectiva para depuración

pbs-home-show
# Ejemplo:
# Repository: root@pam@192.168.40.15:8007:PBS-LUN2
# Fingerprint: 4b:c6:...
# Backup ID: ixas-dwilliams-home
# Source: /home/dwilliams

8) Prune (política de retención)

Por defecto (sobrescribe con variables): KEEP_LAST=7 KEEP_DAILY=14 KEEP_WEEKLY=8 KEEP_MONTHLY=12

pbs-home-prune
# O personaliza al vuelo
KEEP_LAST=10 KEEP_DAILY=30 pbs-home-prune

9) Verificar copias

# Verificar el snapshot más reciente (por defecto)
pbs-home-verify

# Verificar todos los snapshots del grupo (puede tardar)
pbs-home-verify all

Uso de tokens API (recomendado para automatización)

1) En la UI de PBS: Datacenter > Permissions > API Tokens
2) Crea un token para root@pam (o un usuario dedicado)
3) Usa el token en el entorno:

export PBS_REPOSITORY='root@pam!TOKENID@192.168.40.15:8007:PBS-LUN2'
export PBS_PASSWORD='TOKEN_SECRET'

Guardar credenciales de forma segura

Evita poner secretos en archivos legibles por otros usuarios. Opciones:
- Archivo de entorno para systemd con permisos 600
- Gestor de secretos (p. ej., sops-nix/agenix) para almacenamiento declarativo y cifrado

Ejemplo: ~/.config/proxmox-backup/pbs-env (chmod 600)

PBS_REPOSITORY=root@pam@192.168.40.15:8007:PBS-LUN2
PBS_FINGERPRINT=4b:c6:2a:49:62:2e:c6:0d:63:0c:d1:b6:8b:78:be:af:28:2a:94:eb:d4:e7:77:ab:d1:af:c9:ea:c9:07:ef:26
# BACKUP_ID=ixas-dwilliams-home  # sobrescribir si hace falta
# PBS_ENCRYPTION_KEY_FILE=/home/dwilliams/.config/proxmox-backup/home.enc.key
PBS_PASSWORD=REDACTED_O_USA_SECRETOS_DE_SYSTEMD

Automatizar con systemd (opcional)

Servicio de usuario (~/.config/systemd/user/pbs-home-backup.service):

[Unit]
Description=Backup /home/dwilliams to Proxmox Backup Server

[Service]
Type=oneshot
EnvironmentFile=%h/.config/proxmox-backup/pbs-env
ExecStart=/usr/bin/pbs-home-backup \
  --exclude '.cache/**' \
  --exclude '.local/share/Trash/**'

Temporizador de usuario (~/.config/systemd/user/pbs-home-backup.timer):

[Unit]
Description=Daily PBS home backup

[Timer]
OnCalendar=03:00
Persistent=true
Unit=pbs-home-backup.service

[Install]
WantedBy=timers.target

Activar y arrancar:

systemctl --user daemon-reload
systemctl --user enable --now pbs-home-backup.timer
systemctl --user list-timers --all | grep pbs-home-backup

Solución de problemas

- Errores TLS/conexión (p. ej., "client error (Connect)")
  - Verifica que PBS_FINGERPRINT coincida con el certificado del servidor
  - openssl s_client -connect 192.168.40.15:8007 -servername 192.168.40.15 </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
- Errores de autenticación
  - Asegúrate de que PBS_PASSWORD sea correcto; para tokens, usa el secreto del token
- Sin salida en pbs-home-ls
  - Puede que aún no existan snapshots para tu BACKUP_ID; ejecuta pbs-home-backup primero
- Sobrescribir sin reconstruir
  - exporta PBS_REPOSITORY, PBS_FINGERPRINT, BACKUP_ID en tu shell y usa los ayudantes

Listo: usa estos ayudantes para estandarizar copias entre equipos, manteniendo flexibles los valores mediante variables de entorno.
