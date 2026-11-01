-- ====================================================================
-- 0004 - Flujo de compras (solicitud → orden con partidas), PDFs de aseguradora,
-- resguardo de placas en almacén y avisos por rol.
-- ====================================================================

-- ---------- Proveedor: dirección para la orden de compra ----------
ALTER TABLE PROVEEDOR ADD COLUMN IF NOT EXISTS direccion VARCHAR(250);

-- ---------- Solicitudes de compra ----------
ALTER TABLE SOLICITUD_COMPRA
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    ADD COLUMN IF NOT EXISTS unidad VARCHAR(30) NOT NULL DEFAULT 'Pieza',
    ADD COLUMN IF NOT EXISTS notas TEXT,
    ADD COLUMN IF NOT EXISTS motivo_rechazo TEXT,
    ADD COLUMN IF NOT EXISTS solicitado_por VARCHAR(120);
ALTER TABLE SOLICITUD_COMPRA ADD CONSTRAINT ck_solicitud_compra_estado CHECK (estado IN ('Pendiente', 'Aprobada', 'Rechazada'));

-- Cantidades decimales (10.5 kg): se quita el CHECK ">= 1" y se pone "> 0"
DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT conname FROM pg_constraint
        WHERE contype = 'c' AND conrelid = 'solicitud_compra'::regclass
          AND pg_get_constraintdef(oid) LIKE '%cantidadPiezasCotizadas%'
    LOOP
        EXECUTE format('ALTER TABLE solicitud_compra DROP CONSTRAINT %I', r.conname);
    END LOOP;
END $$;
ALTER TABLE SOLICITUD_COMPRA ALTER COLUMN "cantidadPiezasCotizadas" TYPE NUMERIC(12,3);
ALTER TABLE SOLICITUD_COMPRA ADD CONSTRAINT ck_solicitud_compra_cantidad CHECK ("cantidadPiezasCotizadas" > 0);

-- Las solicitudes que ya tenían orden quedan aprobadas
UPDATE SOLICITUD_COMPRA sc SET estado = 'Aprobada'
WHERE EXISTS (SELECT 1 FROM COMPRA c WHERE c.solicitud_compra_id = sc.id_solicitud_compra);

-- ---------- Orden de compra (encabezado) ----------
ALTER TABLE COMPRA
    ADD COLUMN IF NOT EXISTS folio VARCHAR(20),
    ADD COLUMN IF NOT EXISTS fecha DATE,
    ADD COLUMN IF NOT EXISTS fecha_entrega DATE,
    ADD COLUMN IF NOT EXISTS condiciones VARCHAR(40),
    ADD COLUMN IF NOT EXISTS via_embarque VARCHAR(120),
    ADD COLUMN IF NOT EXISTS consignatario VARCHAR(200),
    ADD COLUMN IF NOT EXISTS tasa_iva NUMERIC(5,4) NOT NULL DEFAULT 0.16,
    ADD COLUMN IF NOT EXISTS observaciones TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS ux_compra_folio ON COMPRA (folio) WHERE folio IS NOT NULL;

-- ---------- Partidas de la orden (Artículo, Nombre, U.med., Unidades, Precio, Descto.) ----------
CREATE TABLE IF NOT EXISTS COMPRA_PARTIDA (
    id_partida SERIAL PRIMARY KEY,
    compra_id INT NOT NULL REFERENCES COMPRA(id_compra) ON DELETE CASCADE,
    orden INT NOT NULL,
    articulo VARCHAR(40),
    nombre VARCHAR(200) NOT NULL,
    unidad VARCHAR(30) NOT NULL,
    unidades NUMERIC(12,3) NOT NULL CHECK (unidades > 0),
    precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    descuento NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (descuento >= 0)
);

-- ---------- PDFs de la aseguradora ----------
CREATE TABLE IF NOT EXISTS PROYECTO_DOCUMENTO (
    id_documento SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion) ON DELETE CASCADE,
    nombre_original VARCHAR(200) NOT NULL,
    nombre_archivo VARCHAR(200) NOT NULL UNIQUE,
    tamano BIGINT NOT NULL CHECK (tamano >= 0),
    fecha_subida TIMESTAMP NOT NULL DEFAULT now()
);

-- ---------- Entrega de placas a almacén ----------
CREATE TABLE IF NOT EXISTS RESGUARDO_ALMACEN (
    id_resguardo SERIAL PRIMARY KEY,
    empresa VARCHAR(120) NOT NULL,
    tipo_unidad VARCHAR(60),
    numero_unidad VARCHAR(40) NOT NULL DEFAULT 'S/N',
    objetos TEXT NOT NULL,
    fecha_ingreso TIMESTAMP NOT NULL,
    operador VARCHAR(120) NOT NULL,
    firma TEXT, -- PNG en base64
    fecha_salida TIMESTAMP,
    entregado_a VARCHAR(120),
    notas_salida TEXT,
    usuario_id INT REFERENCES USUARIO(id_usuario)
);

-- ---------- Avisos por rol (eventos que genera el backend) ----------
CREATE TABLE IF NOT EXISTS NOTIFICACION (
    id_notificacion BIGSERIAL PRIMARY KEY,
    rol_destino VARCHAR(30) NOT NULL,
    tipo VARCHAR(40) NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_notificacion_rol ON NOTIFICACION (rol_destino, id_notificacion DESC);
