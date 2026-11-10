-- ====================================================================
-- 0006 - Permisos por área y entregas del tablero ligadas a proyectos.
--
-- 1. USUARIO.area: área a la que pertenece cada usuario.
--    - Jefes: el área de su rol (Proyecto_Lider -> Proyectos, etc.).
--    - Rol 'Usuario': el área del jefe que lo dio de alta (o la que asigne el Admin).
--      Un usuario sin área no puede leer ningún departamento hasta que se le asigne.
--    - Admin: sin área (acceso total).
-- 2. TABLERO_ENTREGA: las entregas de la semana salen de los proyectos; aquí solo se guardan
--    las capturadas a mano y los proyectos que el Admin quitó del tablero (oculta = true).
-- ====================================================================

-- ---------- 1. Área del usuario ----------
ALTER TABLE USUARIO ADD COLUMN IF NOT EXISTS area VARCHAR(20);

-- Un script antiguo (schema_updates) usaba otros valores ('Taller', 'Global'...): se normalizan
UPDATE USUARIO SET area = 'Proyectos' WHERE area IN ('Taller', 'Proyecto', 'Proyectos');
UPDATE USUARIO SET area = NULL WHERE area IS NOT NULL AND area NOT IN ('Proyectos', 'Compras', 'Almacen', 'Evaluacion');

-- Los jefes toman el área de su rol; el Admin no tiene área
UPDATE USUARIO SET area = CASE rol
        WHEN 'Proyecto_Lider' THEN 'Proyectos'
        WHEN 'Compras_Admin' THEN 'Compras'
        WHEN 'Almacen_Admin' THEN 'Almacen'
        WHEN 'Evaluacion_Admin' THEN 'Evaluacion'
        ELSE area END
WHERE rol IN ('Proyecto_Lider', 'Compras_Admin', 'Almacen_Admin', 'Evaluacion_Admin');
UPDATE USUARIO SET area = NULL WHERE rol = 'Admin';

ALTER TABLE USUARIO DROP CONSTRAINT IF EXISTS ck_usuario_area;
ALTER TABLE USUARIO ADD CONSTRAINT ck_usuario_area CHECK (area IS NULL OR area IN ('Proyectos', 'Compras', 'Almacen', 'Evaluacion'));
CREATE INDEX IF NOT EXISTS ix_usuario_area ON USUARIO (area);

-- ---------- 2. Entregas ligadas a proyectos ----------
ALTER TABLE TABLERO_ENTREGA
    ADD COLUMN IF NOT EXISTS operacion_id INT REFERENCES OPERACIONES(id_operacion) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS oculta BOOLEAN NOT NULL DEFAULT FALSE;
CREATE UNIQUE INDEX IF NOT EXISTS ux_tablero_entrega_operacion ON TABLERO_ENTREGA (operacion_id) WHERE operacion_id IS NOT NULL;
