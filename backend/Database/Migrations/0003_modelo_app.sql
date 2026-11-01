-- ====================================================================
-- 0003 - Columnas y tablas que usa la app (proyectos por tipo, etapas,
-- evaluación, fotos, categorías, unidades de medida, préstamos de herramienta
-- ligados al almacén y departamentos).
-- ====================================================================

-- ---------- Camiones: nombre libre; los de aseguradora no llevan cliente ----------
ALTER TABLE CAMION ADD COLUMN IF NOT EXISTS nombre VARCHAR(120);
ALTER TABLE CAMION ALTER COLUMN cliente_id DROP NOT NULL;

-- ---------- Proyectos (OPERACIONES) ----------
ALTER TABLE OPERACIONES
    ADD COLUMN IF NOT EXISTS tipo_proyecto VARCHAR(20) NOT NULL DEFAULT 'Cliente',
    ADD COLUMN IF NOT EXISTS aseguradora VARCHAR(120),
    ADD COLUMN IF NOT EXISTS numero_siniestro VARCHAR(60),
    ADD COLUMN IF NOT EXISTS fecha_entrega_comprometida DATE,
    ADD COLUMN IF NOT EXISTS etapa_actual INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS archivado BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS responsable VARCHAR(120),
    ADD COLUMN IF NOT EXISTS fecha_evaluacion TIMESTAMP,
    ADD COLUMN IF NOT EXISTS descripcion_danos TEXT;

ALTER TABLE OPERACIONES ADD CONSTRAINT ck_operaciones_tipo CHECK (tipo_proyecto IN ('Cliente', 'Aseguradora'));
ALTER TABLE OPERACIONES ADD CONSTRAINT ck_operaciones_etapa CHECK (etapa_actual >= 0);
-- Un proyecto de aseguradora siempre tiene aseguradora y fecha de entrega comprometida
ALTER TABLE OPERACIONES ADD CONSTRAINT ck_operaciones_aseguradora
    CHECK (tipo_proyecto <> 'Aseguradora' OR (aseguradora IS NOT NULL AND fecha_entrega_comprometida IS NOT NULL)) NOT VALID;

CREATE TABLE IF NOT EXISTS PROYECTO_ETAPA (
    id_etapa SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion) ON DELETE CASCADE,
    orden INT NOT NULL CHECK (orden >= 0),
    nombre VARCHAR(60) NOT NULL,
    dias_estimados INT NOT NULL CHECK (dias_estimados BETWEEN 1 AND 365),
    UNIQUE (operacion_id, orden)
);

CREATE TABLE IF NOT EXISTS PROYECTO_REFACCION (
    id_refaccion SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion) ON DELETE CASCADE,
    nombre VARCHAR(120) NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad >= 1)
);

CREATE TABLE IF NOT EXISTS PROYECTO_FOTO (
    id_foto SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion) ON DELETE CASCADE,
    nombre_archivo VARCHAR(200) NOT NULL UNIQUE,
    tipo_contenido VARCHAR(60) NOT NULL,
    fecha_subida TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- Almacén: categorías, tipo de artículo, unidad de medida, cantidades decimales ----------
CREATE TABLE IF NOT EXISTS CATEGORIA_ALMACEN (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_categoria_almacen_nombre ON CATEGORIA_ALMACEN (lower(nombre));

INSERT INTO CATEGORIA_ALMACEN (nombre)
VALUES ('Carrocería'), ('Eléctrico'), ('Fluidos'), ('Frenos'), ('Herramientas'), ('Motor'), ('Suspensión'), ('Transmisión')
ON CONFLICT DO NOTHING;

ALTER TABLE ALMACEN
    ADD COLUMN IF NOT EXISTS categoria_id INT REFERENCES CATEGORIA_ALMACEN(id_categoria),
    ADD COLUMN IF NOT EXISTS tipo_articulo VARCHAR(20) NOT NULL DEFAULT 'Material',
    ADD COLUMN IF NOT EXISTS unidad_medida VARCHAR(20) NOT NULL DEFAULT 'pieza',
    -- Eliminar un artículo lo oculta del catálogo, pero conserva el historial de vales
    ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE ALMACEN ADD CONSTRAINT ck_almacen_tipo CHECK (tipo_articulo IN ('Material', 'Herramienta'));
ALTER TABLE ALMACEN ADD CONSTRAINT ck_almacen_unidad
    CHECK (unidad_medida IN ('pieza', 'kilogramo', 'litro', 'metro', 'juego', 'caja'));
ALTER TABLE ALMACEN ALTER COLUMN "cantidadStock" TYPE NUMERIC(12,3);

-- Las cantidades de salida y kardex pasan a decimales (2.5 kg, 0.75 L).
-- Se quitan los CHECK "cantidad >= 1" (no admitirían 0.5) y se reemplazan por "> 0".
DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT conname, conrelid::regclass AS tabla
        FROM pg_constraint
        WHERE contype = 'c'
          AND conrelid IN ('solicitud_almacen'::regclass, 'movimiento_almacen'::regclass)
          AND (pg_get_constraintdef(oid) LIKE '%cantidadSolicitada%' OR pg_get_constraintdef(oid) ~ '\mcantidad\M')
    LOOP
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.tabla, r.conname);
    END LOOP;
END $$;

ALTER TABLE SOLICITUD_ALMACEN ALTER COLUMN "cantidadSolicitada" TYPE NUMERIC(12,3);
ALTER TABLE SOLICITUD_ALMACEN
    ADD COLUMN IF NOT EXISTS costo_unitario NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS entregado_a VARCHAR(120);
ALTER TABLE SOLICITUD_ALMACEN ADD CONSTRAINT ck_solicitud_almacen_cantidad CHECK ("cantidadSolicitada" > 0);
ALTER TABLE SOLICITUD_ALMACEN ADD CONSTRAINT ck_solicitud_almacen_costo CHECK (costo_unitario >= 0);

ALTER TABLE MOVIMIENTO_ALMACEN ALTER COLUMN cantidad TYPE NUMERIC(12,3);
ALTER TABLE MOVIMIENTO_ALMACEN ADD CONSTRAINT ck_movimiento_almacen_cantidad CHECK (cantidad > 0);

-- ---------- Préstamos de herramienta ligados al artículo del almacén ----------
ALTER TABLE EQUIPO_ALMACEN
    ADD COLUMN IF NOT EXISTS almacen_id INT REFERENCES ALMACEN(id_almacen),
    ADD COLUMN IF NOT EXISTS cantidad NUMERIC(12,3) NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS entregado_a VARCHAR(120),
    ADD COLUMN IF NOT EXISTS fecha_salida TIMESTAMP,
    ADD COLUMN IF NOT EXISTS fecha_devolucion TIMESTAMP,
    ADD COLUMN IF NOT EXISTS estado_devolucion VARCHAR(40);
UPDATE EQUIPO_ALMACEN SET fecha_salida = now() WHERE fecha_salida IS NULL;
-- Registros anteriores ya devueltos (estado distinto de 'En Uso'/'Pendiente') quedan cerrados
UPDATE EQUIPO_ALMACEN SET fecha_devolucion = fecha_salida, estado_devolucion = "estadoDevuelto"
WHERE fecha_devolucion IS NULL AND "estadoDevuelto" IS NOT NULL AND "estadoDevuelto" NOT IN ('En Uso', 'Pendiente');
ALTER TABLE EQUIPO_ALMACEN ALTER COLUMN fecha_salida SET DEFAULT now();
ALTER TABLE EQUIPO_ALMACEN ADD CONSTRAINT ck_equipo_almacen_cantidad CHECK (cantidad > 0);

-- ---------- Departamentos ----------
CREATE TABLE IF NOT EXISTS DEPARTAMENTO (
    id_departamento SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    encargado VARCHAR(120),
    icono VARCHAR(40) NOT NULL DEFAULT 'business',
    personal INT NOT NULL DEFAULT 0 CHECK (personal >= 0)
);
