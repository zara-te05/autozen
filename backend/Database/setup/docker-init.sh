#!/bin/bash
# Ejecutado por la imagen de postgres solo cuando el volumen está vacío.
set -euo pipefail
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" \
     -v owner_password="$AUTOZEN_OWNER_PASSWORD" \
     -v app_password="$AUTOZEN_APP_PASSWORD" \
     -f /autozen/01_crear_bd_y_usuarios.sql
