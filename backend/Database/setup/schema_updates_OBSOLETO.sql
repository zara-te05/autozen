-- ====================================================================
-- AUTOZEN - SCRIPTS DE ACTUALIZACIÓN DE BASE DE DATOS (POSTGRESQL)
-- Ejecutar en PostgreSQL local para habilitar los requerimientos de los 4 rubros
-- ====================================================================

-- 1. HERRAMIENTAS DE ALMACÉN: Registro de horarios de préstamo y devolución
ALTER TABLE EQUIPOALMACEN 
ADD COLUMN IF NOT EXISTS fecha_salida TIMESTAMP,
ADD COLUMN IF NOT EXISTS fecha_devolucion TIMESTAMP;

-- 2. CAMIONES / PROYECTOS: Daño inicial estimado
ALTER TABLE CAMION 
ADD COLUMN IF NOT EXISTS dano_estimado TEXT;

-- 3. OPERACIONES / PROYECTOS: Solicitud de baja/eliminación por líder de área
ALTER TABLE OPERACION 
ADD COLUMN IF NOT EXISTS solicita_eliminacion BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS motivo_eliminacion TEXT;

-- 4. USUARIOS: Garantizar soporte para privilegios y asignación de área
ALTER TABLE USUARIO 
ADD COLUMN IF NOT EXISTS username VARCHAR(100) UNIQUE,
ADD COLUMN IF NOT EXISTS password VARCHAR(255),
ADD COLUMN IF NOT EXISTS rol VARCHAR(50) DEFAULT 'Usuario',
ADD COLUMN IF NOT EXISTS area VARCHAR(50); -- Ejemplos: 'Taller', 'Compras', 'Almacen', 'Global'
