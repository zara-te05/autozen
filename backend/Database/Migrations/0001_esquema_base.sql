-- ====================================================================
-- AUTOZEN - Esquema base (migración 0001)
-- Lo aplica DbUp automáticamente al arrancar la API en una base vacía.
-- Las columnas camelCase van entre comillas porque así las consulta el código;
-- sin comillas PostgreSQL las guardaría en minúsculas y las consultas fallarían.
-- ====================================================================

CREATE TABLE IF NOT EXISTS TRABAJADOR(
    id_trabajador SERIAL PRIMARY KEY,

    "nombreTrabajador" VARCHAR NOT NULL,
    "apellidoTrabajador" VARCHAR NOT NULL,
    "salarioTrabajador" DECIMAL CHECK ("salarioTrabajador" >= 1)
);

CREATE TABLE IF NOT EXISTS USUARIO(
    id_usuario SERIAL PRIMARY KEY,
    trabajador_id INT REFERENCES TRABAJADOR(id_trabajador),

    nombre VARCHAR(100) NOT NULL,
    username VARCHAR NOT NULL UNIQUE,
    rol VARCHAR(100) NOT NULL DEFAULT 'Usuario',
    password VARCHAR NOT NULL,
    "puestoTrabajo" VARCHAR(100),
    "metodoContacto" VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS CLIENTE(
    id_cliente SERIAL PRIMARY KEY,

    nombre VARCHAR NOT NULL,
    apellido VARCHAR NOT NULL,
    "numTelefono" VARCHAR NOT NULL,
    "metodoContactoAlternativo" VARCHAR,
    "lugarProcedencia" VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS CAMION(
    id_camion SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES CLIENTE(id_cliente),

    placas VARCHAR NOT NULL,
    marca VARCHAR,
    modelo VARCHAR,
    "fechaEntrada" TIMESTAMP NOT NULL,
    "tiempoEsperado" TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS PROVEEDOR(
    id_proveedor SERIAL PRIMARY KEY,

    "nombreProveedor" VARCHAR NOT NULL,
    contacto VARCHAR,
    "tiempoEntregaPromedioDias" INT CHECK ("tiempoEntregaPromedioDias" >= 0),
    "precioPromedio" DECIMAL CHECK ("precioPromedio" >= 0)
);

CREATE TABLE IF NOT EXISTS ALMACEN(
    id_almacen SERIAL PRIMARY KEY,

    "nombrePieza" VARCHAR NOT NULL,
    "cantidadStock" INT CHECK ("cantidadStock" >= 0),
    "costoPiezas" DECIMAL CHECK ("costoPiezas" >= 0)
);

-- Empleado (USUARIO) que da de alta la operación queda registrado aqui
CREATE TABLE IF NOT EXISTS OPERACIONES(
    id_operacion SERIAL PRIMARY KEY,
    camion_id INT NOT NULL REFERENCES CAMION(id_camion),
    usuario_id INT REFERENCES USUARIO(id_usuario),

    "fechaInicio" TIMESTAMP NOT NULL,
    "fechaEstimadaFinalizacion" TIMESTAMP NOT NULL,
    "estadoOperacion" VARCHAR CHECK (
        "estadoOperacion" IN ('Pendiente', 'Iniciado', 'En Proceso', 'Finalizado', 'Eliminado')
        OR "estadoOperacion" LIKE 'Solicitud_Baja:%'
    )
);

CREATE TABLE IF NOT EXISTS COTIZACION(
    id_cotizacion SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion),
    trabajador_id INT REFERENCES TRABAJADOR(id_trabajador),

    "manoObraEstimada" DECIMAL CHECK ("manoObraEstimada" >= 1),
    "costoEstimadoPiezas" DECIMAL CHECK ("costoEstimadoPiezas" >= 0),
    total DECIMAL CHECK (total >= ("manoObraEstimada" + "costoEstimadoPiezas")),
    "estadoCotizacion" VARCHAR
);

CREATE TABLE IF NOT EXISTS DETALLE_COTIZACION(
    id_detalle_cotizacion SERIAL PRIMARY KEY,
    cotizacion_id INT NOT NULL REFERENCES COTIZACION(id_cotizacion),
    trabajador_id INT REFERENCES TRABAJADOR(id_trabajador),

    "descripcionTrabajo_Pieza" VARCHAR,
    "costoPiezasTomadasAlmacen" DECIMAL CHECK ("costoPiezasTomadasAlmacen" >= 0),
    "trabajadoresAsignados" INT CHECK ("trabajadoresAsignados" >= 1)
);

CREATE TABLE IF NOT EXISTS SOLICITUD_ALMACEN(
    id_solicitud_almacen SERIAL PRIMARY KEY,
    almacen_id INT NOT NULL REFERENCES ALMACEN(id_almacen),
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion),

    "cantidadSolicitada" INT CHECK ("cantidadSolicitada" >= 1),
    "fechaSolicitud" TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS EQUIPO_ALMACEN(
    id_equipo SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion),
    trabajador_id INT REFERENCES TRABAJADOR(id_trabajador),

    "nombreHerramienta" VARCHAR NOT NULL,
    "estadoSalida" VARCHAR,
    "estadoDevuelto" VARCHAR
);

CREATE TABLE IF NOT EXISTS SOLICITUD_COMPRA(
    id_solicitud_compra SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion),
    usuario_id INT REFERENCES USUARIO(id_usuario),
    proveedor_id INT REFERENCES PROVEEDOR(id_proveedor),

    "nombrePiezasCotizadas" VARCHAR,
    "cantidadPiezasCotizadas" INT CHECK ("cantidadPiezasCotizadas" >= 1),
    "fechaSolicitud" TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS COMPRA(
    id_compra SERIAL PRIMARY KEY,
    solicitud_compra_id INT NOT NULL REFERENCES SOLICITUD_COMPRA(id_solicitud_compra),
    operacion_id INT NOT NULL REFERENCES OPERACIONES(id_operacion),

    "nombrePiezas" VARCHAR,
    "cantidadPiezas" INT CHECK ("cantidadPiezas" >= 1),
    "costoPiezas" DECIMAL CHECK ("costoPiezas" >= 0)
);

-- Reclamo/reembolso cuando el material que llego esta defectuoso
CREATE TABLE IF NOT EXISTS DEVOLUCION_PROVEEDOR(
    id_devolucion SERIAL PRIMARY KEY,
    compra_id INT NOT NULL REFERENCES COMPRA(id_compra),
    proveedor_id INT NOT NULL REFERENCES PROVEEDOR(id_proveedor),

    motivo VARCHAR NOT NULL,
    "fechaDevolucion" TIMESTAMP NOT NULL,
    "estadoDevolucion" VARCHAR CHECK ("estadoDevolucion" IN ('Solicitado', 'Reembolsado', 'Rechazado')),
    "montoReembolso" DECIMAL CHECK ("montoReembolso" >= 0)
);

CREATE TABLE IF NOT EXISTS MOVIMIENTO_ALMACEN(
    id_movimiento SERIAL PRIMARY KEY,
    almacen_id INT NOT NULL REFERENCES ALMACEN(id_almacen),
    compra_id INT REFERENCES COMPRA(id_compra),
    solicitud_almacen_id INT REFERENCES SOLICITUD_ALMACEN(id_solicitud_almacen),

    "tipoMovimiento" VARCHAR NOT NULL CHECK ("tipoMovimiento" IN ('Entrada', 'Salida')),
    cantidad INT NOT NULL CHECK (cantidad >= 1),
    "fechaMovimiento" TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS FACTURA(
    id_factura SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL UNIQUE REFERENCES OPERACIONES(id_operacion),

    "fechaEmision" TIMESTAMP NOT NULL,
    "montoTotal" DECIMAL CHECK ("montoTotal" >= 0),
    "estadoPago" VARCHAR CHECK ("estadoPago" IN ('Pendiente', 'Pagado', 'Cancelado'))
);

CREATE TABLE IF NOT EXISTS VALE_SALIDA(
    id_vale SERIAL PRIMARY KEY,
    operacion_id INT NOT NULL UNIQUE REFERENCES OPERACIONES(id_operacion),
    usuario_id INT REFERENCES USUARIO(id_usuario),

    "entregadoA" VARCHAR NOT NULL,
    "fechaEntrega" TIMESTAMP NOT NULL
);
