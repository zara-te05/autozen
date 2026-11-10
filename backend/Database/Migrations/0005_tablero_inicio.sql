-- ====================================================================
-- 0005 - Tablero de inicio (lo primero que se ve en el dashboard):
--   1. Programación de entregas de unidades de la semana (captura manual).
--   2. Coordinación operativa del día: notas tipo post-it para asignar cuadrillas.
--      Se borran todos los días a las 19:00 (hora de la Ciudad de México).
--   3. Anuncios generales (captura manual).
-- Solo el Admin escribe; cualquier usuario autenticado los lee.
-- ====================================================================

CREATE TABLE IF NOT EXISTS TABLERO_ENTREGA (
    id_entrega SERIAL PRIMARY KEY,
    unidad VARCHAR(120) NOT NULL,
    cliente VARCHAR(150),
    fecha_entrega DATE NOT NULL,
    notas TEXT,
    entregada BOOLEAN NOT NULL DEFAULT FALSE,
    creado_por VARCHAR(120),
    creado TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_tablero_entrega_fecha ON TABLERO_ENTREGA (fecha_entrega);

CREATE TABLE IF NOT EXISTS TABLERO_COORDINACION (
    id_coordinacion SERIAL PRIMARY KEY,
    cuadrilla VARCHAR(80) NOT NULL,
    asignacion TEXT NOT NULL,
    color VARCHAR(20) NOT NULL DEFAULT 'amarillo',
    creado_por VARCHAR(120),
    creado TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_tablero_coordinacion_creado ON TABLERO_COORDINACION (creado);

CREATE TABLE IF NOT EXISTS TABLERO_ANUNCIO (
    id_anuncio SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    contenido TEXT NOT NULL,
    creado_por VARCHAR(120),
    creado TIMESTAMPTZ NOT NULL DEFAULT now(),
    editado TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS ix_tablero_anuncio_creado ON TABLERO_ANUNCIO (creado DESC);
