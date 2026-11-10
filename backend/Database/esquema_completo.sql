-- =====================================================================
-- AUTOZEN - Esquema completo de la base de datos (estado final)
-- Equivale a aplicar las migraciones 0001 a 0004.
-- Ejecutar en una base vacía, p. ej.:  CREATE DATABASE autozen_db;
-- Nota: si la API usa DbUp sobre esta base, registra las migraciones
-- como aplicadas (ver final del archivo) para que no se vuelvan a correr.
-- =====================================================================

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

--
-- Name: almacen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.almacen (
    id_almacen integer NOT NULL,
    "nombrePieza" character varying NOT NULL,
    "cantidadStock" numeric(12,3),
    "costoPiezas" numeric,
    categoria_id integer,
    tipo_articulo character varying(20) DEFAULT 'Material'::character varying NOT NULL,
    unidad_medida character varying(20) DEFAULT 'pieza'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT "almacen_cantidadStock_check" CHECK (("cantidadStock" >= (0)::numeric)),
    CONSTRAINT "almacen_costoPiezas_check" CHECK (("costoPiezas" >= (0)::numeric)),
    CONSTRAINT ck_almacen_tipo CHECK (((tipo_articulo)::text = ANY ((ARRAY['Material'::character varying, 'Herramienta'::character varying])::text[]))),
    CONSTRAINT ck_almacen_unidad CHECK (((unidad_medida)::text = ANY ((ARRAY['pieza'::character varying, 'kilogramo'::character varying, 'litro'::character varying, 'metro'::character varying, 'juego'::character varying, 'caja'::character varying])::text[])))
);

--
-- Name: almacen_id_almacen_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.almacen_id_almacen_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: almacen_id_almacen_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.almacen_id_almacen_seq OWNED BY public.almacen.id_almacen;

--
-- Name: camion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camion (
    id_camion integer NOT NULL,
    cliente_id integer,
    placas character varying NOT NULL,
    marca character varying,
    modelo character varying,
    "fechaEntrada" timestamp without time zone NOT NULL,
    "tiempoEsperado" timestamp without time zone NOT NULL,
    nombre character varying(120)
);

--
-- Name: camion_id_camion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camion_id_camion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: camion_id_camion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camion_id_camion_seq OWNED BY public.camion.id_camion;

--
-- Name: categoria_almacen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria_almacen (
    id_categoria integer NOT NULL,
    nombre character varying(60) NOT NULL
);

--
-- Name: categoria_almacen_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categoria_almacen_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: categoria_almacen_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categoria_almacen_id_categoria_seq OWNED BY public.categoria_almacen.id_categoria;

--
-- Name: cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    nombre character varying NOT NULL,
    apellido character varying NOT NULL,
    "numTelefono" character varying NOT NULL,
    "metodoContactoAlternativo" character varying,
    "lugarProcedencia" character varying NOT NULL
);

--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_id_cliente_seq OWNED BY public.cliente.id_cliente;

--
-- Name: compra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.compra (
    id_compra integer NOT NULL,
    solicitud_compra_id integer NOT NULL,
    operacion_id integer NOT NULL,
    "nombrePiezas" character varying,
    "cantidadPiezas" integer,
    "costoPiezas" numeric,
    folio character varying(20),
    fecha date,
    fecha_entrega date,
    condiciones character varying(40),
    via_embarque character varying(120),
    consignatario character varying(200),
    tasa_iva numeric(5,4) DEFAULT 0.16 NOT NULL,
    observaciones text,
    CONSTRAINT "compra_cantidadPiezas_check" CHECK (("cantidadPiezas" >= 1)),
    CONSTRAINT "compra_costoPiezas_check" CHECK (("costoPiezas" >= (0)::numeric))
);

--
-- Name: compra_id_compra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.compra_id_compra_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: compra_id_compra_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.compra_id_compra_seq OWNED BY public.compra.id_compra;

--
-- Name: compra_partida; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.compra_partida (
    id_partida integer NOT NULL,
    compra_id integer NOT NULL,
    orden integer NOT NULL,
    articulo character varying(40),
    nombre character varying(200) NOT NULL,
    unidad character varying(30) NOT NULL,
    unidades numeric(12,3) NOT NULL,
    precio numeric(12,2) NOT NULL,
    descuento numeric(12,2) DEFAULT 0 NOT NULL,
    CONSTRAINT compra_partida_descuento_check CHECK ((descuento >= (0)::numeric)),
    CONSTRAINT compra_partida_precio_check CHECK ((precio >= (0)::numeric)),
    CONSTRAINT compra_partida_unidades_check CHECK ((unidades > (0)::numeric))
);

--
-- Name: compra_partida_id_partida_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.compra_partida_id_partida_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: compra_partida_id_partida_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.compra_partida_id_partida_seq OWNED BY public.compra_partida.id_partida;

--
-- Name: cotizacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cotizacion (
    id_cotizacion integer NOT NULL,
    operacion_id integer NOT NULL,
    trabajador_id integer,
    "manoObraEstimada" numeric,
    "costoEstimadoPiezas" numeric,
    total numeric,
    "estadoCotizacion" character varying,
    CONSTRAINT cotizacion_check CHECK ((total >= ("manoObraEstimada" + "costoEstimadoPiezas"))),
    CONSTRAINT "cotizacion_costoEstimadoPiezas_check" CHECK (("costoEstimadoPiezas" >= (0)::numeric)),
    CONSTRAINT "cotizacion_manoObraEstimada_check" CHECK (("manoObraEstimada" >= (1)::numeric))
);

--
-- Name: cotizacion_id_cotizacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cotizacion_id_cotizacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: cotizacion_id_cotizacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cotizacion_id_cotizacion_seq OWNED BY public.cotizacion.id_cotizacion;

--
-- Name: departamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departamento (
    id_departamento integer NOT NULL,
    nombre character varying(80) NOT NULL,
    encargado character varying(120),
    icono character varying(40) DEFAULT 'business'::character varying NOT NULL,
    personal integer DEFAULT 0 NOT NULL,
    CONSTRAINT departamento_personal_check CHECK ((personal >= 0))
);

--
-- Name: departamento_id_departamento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departamento_id_departamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: departamento_id_departamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departamento_id_departamento_seq OWNED BY public.departamento.id_departamento;

--
-- Name: detalle_cotizacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detalle_cotizacion (
    id_detalle_cotizacion integer NOT NULL,
    cotizacion_id integer NOT NULL,
    trabajador_id integer,
    "descripcionTrabajo_Pieza" character varying,
    "costoPiezasTomadasAlmacen" numeric,
    "trabajadoresAsignados" integer,
    CONSTRAINT "detalle_cotizacion_costoPiezasTomadasAlmacen_check" CHECK (("costoPiezasTomadasAlmacen" >= (0)::numeric)),
    CONSTRAINT "detalle_cotizacion_trabajadoresAsignados_check" CHECK (("trabajadoresAsignados" >= 1))
);

--
-- Name: detalle_cotizacion_id_detalle_cotizacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detalle_cotizacion_id_detalle_cotizacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: detalle_cotizacion_id_detalle_cotizacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.detalle_cotizacion_id_detalle_cotizacion_seq OWNED BY public.detalle_cotizacion.id_detalle_cotizacion;

--
-- Name: devolucion_proveedor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devolucion_proveedor (
    id_devolucion integer NOT NULL,
    compra_id integer NOT NULL,
    proveedor_id integer NOT NULL,
    motivo character varying NOT NULL,
    "fechaDevolucion" timestamp without time zone NOT NULL,
    "estadoDevolucion" character varying,
    "montoReembolso" numeric,
    CONSTRAINT "devolucion_proveedor_estadoDevolucion_check" CHECK ((("estadoDevolucion")::text = ANY ((ARRAY['Solicitado'::character varying, 'Reembolsado'::character varying, 'Rechazado'::character varying])::text[]))),
    CONSTRAINT "devolucion_proveedor_montoReembolso_check" CHECK (("montoReembolso" >= (0)::numeric))
);

--
-- Name: devolucion_proveedor_id_devolucion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.devolucion_proveedor_id_devolucion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: devolucion_proveedor_id_devolucion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.devolucion_proveedor_id_devolucion_seq OWNED BY public.devolucion_proveedor.id_devolucion;

--
-- Name: equipo_almacen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipo_almacen (
    id_equipo integer NOT NULL,
    operacion_id integer NOT NULL,
    trabajador_id integer,
    "nombreHerramienta" character varying NOT NULL,
    "estadoSalida" character varying,
    "estadoDevuelto" character varying,
    almacen_id integer,
    cantidad numeric(12,3) DEFAULT 1 NOT NULL,
    entregado_a character varying(120),
    fecha_salida timestamp without time zone DEFAULT now(),
    fecha_devolucion timestamp without time zone,
    estado_devolucion character varying(40),
    CONSTRAINT ck_equipo_almacen_cantidad CHECK ((cantidad > (0)::numeric))
);

--
-- Name: equipo_almacen_id_equipo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.equipo_almacen_id_equipo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: equipo_almacen_id_equipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.equipo_almacen_id_equipo_seq OWNED BY public.equipo_almacen.id_equipo;

--
-- Name: factura; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factura (
    id_factura integer NOT NULL,
    operacion_id integer NOT NULL,
    "fechaEmision" timestamp without time zone NOT NULL,
    "montoTotal" numeric,
    "estadoPago" character varying,
    CONSTRAINT "factura_estadoPago_check" CHECK ((("estadoPago")::text = ANY ((ARRAY['Pendiente'::character varying, 'Pagado'::character varying, 'Cancelado'::character varying])::text[]))),
    CONSTRAINT "factura_montoTotal_check" CHECK (("montoTotal" >= (0)::numeric))
);

--
-- Name: factura_id_factura_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.factura_id_factura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: factura_id_factura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.factura_id_factura_seq OWNED BY public.factura.id_factura;

--
-- Name: movimiento_almacen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimiento_almacen (
    id_movimiento integer NOT NULL,
    almacen_id integer NOT NULL,
    compra_id integer,
    solicitud_almacen_id integer,
    "tipoMovimiento" character varying NOT NULL,
    cantidad numeric(12,3) NOT NULL,
    "fechaMovimiento" timestamp without time zone NOT NULL,
    CONSTRAINT ck_movimiento_almacen_cantidad CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT "movimiento_almacen_tipoMovimiento_check" CHECK ((("tipoMovimiento")::text = ANY ((ARRAY['Entrada'::character varying, 'Salida'::character varying])::text[])))
);

--
-- Name: movimiento_almacen_id_movimiento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimiento_almacen_id_movimiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: movimiento_almacen_id_movimiento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movimiento_almacen_id_movimiento_seq OWNED BY public.movimiento_almacen.id_movimiento;

--
-- Name: notificacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notificacion (
    id_notificacion bigint NOT NULL,
    rol_destino character varying(30) NOT NULL,
    tipo character varying(40) NOT NULL,
    titulo character varying(150) NOT NULL,
    mensaje text NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL
);

--
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notificacion_id_notificacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notificacion_id_notificacion_seq OWNED BY public.notificacion.id_notificacion;

--
-- Name: operaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operaciones (
    id_operacion integer NOT NULL,
    camion_id integer NOT NULL,
    usuario_id integer,
    "fechaInicio" timestamp without time zone NOT NULL,
    "fechaEstimadaFinalizacion" timestamp without time zone NOT NULL,
    "estadoOperacion" character varying,
    tipo_proyecto character varying(20) DEFAULT 'Cliente'::character varying NOT NULL,
    aseguradora character varying(120),
    numero_siniestro character varying(60),
    fecha_entrega_comprometida date,
    etapa_actual integer DEFAULT 0 NOT NULL,
    archivado boolean DEFAULT false NOT NULL,
    responsable character varying(120),
    fecha_evaluacion timestamp without time zone,
    descripcion_danos text,
    CONSTRAINT ck_operaciones_etapa CHECK ((etapa_actual >= 0)),
    CONSTRAINT ck_operaciones_tipo CHECK (((tipo_proyecto)::text = ANY ((ARRAY['Cliente'::character varying, 'Aseguradora'::character varying])::text[]))),
    CONSTRAINT "operaciones_estadoOperacion_check" CHECK (((("estadoOperacion")::text = ANY ((ARRAY['Pendiente'::character varying, 'Iniciado'::character varying, 'En Proceso'::character varying, 'Finalizado'::character varying, 'Eliminado'::character varying])::text[])) OR (("estadoOperacion")::text ~~ 'Solicitud_Baja:%'::text)))
);

--
-- Name: operaciones_id_operacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operaciones_id_operacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: operaciones_id_operacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operaciones_id_operacion_seq OWNED BY public.operaciones.id_operacion;

--
-- Name: proveedor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proveedor (
    id_proveedor integer NOT NULL,
    "nombreProveedor" character varying NOT NULL,
    contacto character varying,
    "tiempoEntregaPromedioDias" integer,
    "precioPromedio" numeric,
    direccion character varying(250),
    CONSTRAINT "proveedor_precioPromedio_check" CHECK (("precioPromedio" >= (0)::numeric)),
    CONSTRAINT "proveedor_tiempoEntregaPromedioDias_check" CHECK (("tiempoEntregaPromedioDias" >= 0))
);

--
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proveedor_id_proveedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proveedor_id_proveedor_seq OWNED BY public.proveedor.id_proveedor;

--
-- Name: proyecto_documento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proyecto_documento (
    id_documento integer NOT NULL,
    operacion_id integer NOT NULL,
    nombre_original character varying(200) NOT NULL,
    nombre_archivo character varying(200) NOT NULL,
    tamano bigint NOT NULL,
    fecha_subida timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT proyecto_documento_tamano_check CHECK ((tamano >= 0))
);

--
-- Name: proyecto_documento_id_documento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proyecto_documento_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: proyecto_documento_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proyecto_documento_id_documento_seq OWNED BY public.proyecto_documento.id_documento;

--
-- Name: proyecto_etapa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proyecto_etapa (
    id_etapa integer NOT NULL,
    operacion_id integer NOT NULL,
    orden integer NOT NULL,
    nombre character varying(60) NOT NULL,
    dias_estimados integer NOT NULL,
    CONSTRAINT proyecto_etapa_dias_estimados_check CHECK (((dias_estimados >= 1) AND (dias_estimados <= 365))),
    CONSTRAINT proyecto_etapa_orden_check CHECK ((orden >= 0))
);

--
-- Name: proyecto_etapa_id_etapa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proyecto_etapa_id_etapa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: proyecto_etapa_id_etapa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proyecto_etapa_id_etapa_seq OWNED BY public.proyecto_etapa.id_etapa;

--
-- Name: proyecto_foto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proyecto_foto (
    id_foto integer NOT NULL,
    operacion_id integer NOT NULL,
    nombre_archivo character varying(200) NOT NULL,
    tipo_contenido character varying(60) NOT NULL,
    fecha_subida timestamp without time zone DEFAULT now() NOT NULL
);

--
-- Name: proyecto_foto_id_foto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proyecto_foto_id_foto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: proyecto_foto_id_foto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proyecto_foto_id_foto_seq OWNED BY public.proyecto_foto.id_foto;

--
-- Name: proyecto_refaccion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proyecto_refaccion (
    id_refaccion integer NOT NULL,
    operacion_id integer NOT NULL,
    nombre character varying(120) NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT proyecto_refaccion_cantidad_check CHECK ((cantidad >= 1))
);

--
-- Name: proyecto_refaccion_id_refaccion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proyecto_refaccion_id_refaccion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: proyecto_refaccion_id_refaccion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proyecto_refaccion_id_refaccion_seq OWNED BY public.proyecto_refaccion.id_refaccion;

--
-- Name: resguardo_almacen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resguardo_almacen (
    id_resguardo integer NOT NULL,
    empresa character varying(120) NOT NULL,
    tipo_unidad character varying(60),
    numero_unidad character varying(40) DEFAULT 'S/N'::character varying NOT NULL,
    objetos text NOT NULL,
    fecha_ingreso timestamp without time zone NOT NULL,
    operador character varying(120) NOT NULL,
    firma text,
    fecha_salida timestamp without time zone,
    entregado_a character varying(120),
    notas_salida text,
    usuario_id integer
);

--
-- Name: resguardo_almacen_id_resguardo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resguardo_almacen_id_resguardo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: resguardo_almacen_id_resguardo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resguardo_almacen_id_resguardo_seq OWNED BY public.resguardo_almacen.id_resguardo;

--
-- Name: solicitud_almacen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solicitud_almacen (
    id_solicitud_almacen integer NOT NULL,
    almacen_id integer NOT NULL,
    operacion_id integer NOT NULL,
    "cantidadSolicitada" numeric(12,3),
    "fechaSolicitud" timestamp without time zone NOT NULL,
    costo_unitario numeric(12,2) DEFAULT 0 NOT NULL,
    entregado_a character varying(120),
    CONSTRAINT ck_solicitud_almacen_cantidad CHECK (("cantidadSolicitada" > (0)::numeric)),
    CONSTRAINT ck_solicitud_almacen_costo CHECK ((costo_unitario >= (0)::numeric))
);

--
-- Name: solicitud_almacen_id_solicitud_almacen_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solicitud_almacen_id_solicitud_almacen_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: solicitud_almacen_id_solicitud_almacen_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solicitud_almacen_id_solicitud_almacen_seq OWNED BY public.solicitud_almacen.id_solicitud_almacen;

--
-- Name: solicitud_compra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solicitud_compra (
    id_solicitud_compra integer NOT NULL,
    operacion_id integer NOT NULL,
    usuario_id integer,
    proveedor_id integer,
    "nombrePiezasCotizadas" character varying,
    "cantidadPiezasCotizadas" numeric(12,3),
    "fechaSolicitud" timestamp without time zone NOT NULL,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    unidad character varying(30) DEFAULT 'Pieza'::character varying NOT NULL,
    notas text,
    motivo_rechazo text,
    solicitado_por character varying(120),
    CONSTRAINT ck_solicitud_compra_cantidad CHECK (("cantidadPiezasCotizadas" > (0)::numeric)),
    CONSTRAINT ck_solicitud_compra_estado CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Aprobada'::character varying, 'Rechazada'::character varying])::text[])))
);

--
-- Name: solicitud_compra_id_solicitud_compra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solicitud_compra_id_solicitud_compra_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: solicitud_compra_id_solicitud_compra_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solicitud_compra_id_solicitud_compra_seq OWNED BY public.solicitud_compra.id_solicitud_compra;

--
-- Name: trabajador; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trabajador (
    id_trabajador integer NOT NULL,
    "nombreTrabajador" character varying NOT NULL,
    "apellidoTrabajador" character varying NOT NULL,
    "salarioTrabajador" numeric,
    CONSTRAINT "trabajador_salarioTrabajador_check" CHECK (("salarioTrabajador" >= (1)::numeric))
);

--
-- Name: trabajador_id_trabajador_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trabajador_id_trabajador_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: trabajador_id_trabajador_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trabajador_id_trabajador_seq OWNED BY public.trabajador.id_trabajador;

--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    trabajador_id integer,
    nombre character varying(100) NOT NULL,
    username character varying NOT NULL,
    rol character varying(100) DEFAULT 'Usuario'::character varying NOT NULL,
    password character varying NOT NULL,
    "puestoTrabajo" character varying(100),
    "metodoContacto" character varying(100)
);

--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;

--
-- Name: vale_salida; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vale_salida (
    id_vale integer NOT NULL,
    operacion_id integer NOT NULL,
    usuario_id integer,
    "entregadoA" character varying NOT NULL,
    "fechaEntrega" timestamp without time zone NOT NULL
);

--
-- Name: vale_salida_id_vale_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vale_salida_id_vale_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: vale_salida_id_vale_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vale_salida_id_vale_seq OWNED BY public.vale_salida.id_vale;

--
-- Name: almacen id_almacen; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacen ALTER COLUMN id_almacen SET DEFAULT nextval('public.almacen_id_almacen_seq'::regclass);

--
-- Name: camion id_camion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camion ALTER COLUMN id_camion SET DEFAULT nextval('public.camion_id_camion_seq'::regclass);

--
-- Name: categoria_almacen id_categoria; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_almacen ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_almacen_id_categoria_seq'::regclass);

--
-- Name: cliente id_cliente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('public.cliente_id_cliente_seq'::regclass);

--
-- Name: compra id_compra; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra ALTER COLUMN id_compra SET DEFAULT nextval('public.compra_id_compra_seq'::regclass);

--
-- Name: compra_partida id_partida; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra_partida ALTER COLUMN id_partida SET DEFAULT nextval('public.compra_partida_id_partida_seq'::regclass);

--
-- Name: cotizacion id_cotizacion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion ALTER COLUMN id_cotizacion SET DEFAULT nextval('public.cotizacion_id_cotizacion_seq'::regclass);

--
-- Name: departamento id_departamento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departamento ALTER COLUMN id_departamento SET DEFAULT nextval('public.departamento_id_departamento_seq'::regclass);

--
-- Name: detalle_cotizacion id_detalle_cotizacion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_cotizacion ALTER COLUMN id_detalle_cotizacion SET DEFAULT nextval('public.detalle_cotizacion_id_detalle_cotizacion_seq'::regclass);

--
-- Name: devolucion_proveedor id_devolucion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucion_proveedor ALTER COLUMN id_devolucion SET DEFAULT nextval('public.devolucion_proveedor_id_devolucion_seq'::regclass);

--
-- Name: equipo_almacen id_equipo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo_almacen ALTER COLUMN id_equipo SET DEFAULT nextval('public.equipo_almacen_id_equipo_seq'::regclass);

--
-- Name: factura id_factura; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factura ALTER COLUMN id_factura SET DEFAULT nextval('public.factura_id_factura_seq'::regclass);

--
-- Name: movimiento_almacen id_movimiento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimiento_almacen ALTER COLUMN id_movimiento SET DEFAULT nextval('public.movimiento_almacen_id_movimiento_seq'::regclass);

--
-- Name: notificacion id_notificacion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacion ALTER COLUMN id_notificacion SET DEFAULT nextval('public.notificacion_id_notificacion_seq'::regclass);

--
-- Name: operaciones id_operacion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones ALTER COLUMN id_operacion SET DEFAULT nextval('public.operaciones_id_operacion_seq'::regclass);

--
-- Name: proveedor id_proveedor; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedor ALTER COLUMN id_proveedor SET DEFAULT nextval('public.proveedor_id_proveedor_seq'::regclass);

--
-- Name: proyecto_documento id_documento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_documento ALTER COLUMN id_documento SET DEFAULT nextval('public.proyecto_documento_id_documento_seq'::regclass);

--
-- Name: proyecto_etapa id_etapa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_etapa ALTER COLUMN id_etapa SET DEFAULT nextval('public.proyecto_etapa_id_etapa_seq'::regclass);

--
-- Name: proyecto_foto id_foto; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_foto ALTER COLUMN id_foto SET DEFAULT nextval('public.proyecto_foto_id_foto_seq'::regclass);

--
-- Name: proyecto_refaccion id_refaccion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_refaccion ALTER COLUMN id_refaccion SET DEFAULT nextval('public.proyecto_refaccion_id_refaccion_seq'::regclass);

--
-- Name: resguardo_almacen id_resguardo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resguardo_almacen ALTER COLUMN id_resguardo SET DEFAULT nextval('public.resguardo_almacen_id_resguardo_seq'::regclass);

--
-- Name: solicitud_almacen id_solicitud_almacen; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_almacen ALTER COLUMN id_solicitud_almacen SET DEFAULT nextval('public.solicitud_almacen_id_solicitud_almacen_seq'::regclass);

--
-- Name: solicitud_compra id_solicitud_compra; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_compra ALTER COLUMN id_solicitud_compra SET DEFAULT nextval('public.solicitud_compra_id_solicitud_compra_seq'::regclass);

--
-- Name: trabajador id_trabajador; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajador ALTER COLUMN id_trabajador SET DEFAULT nextval('public.trabajador_id_trabajador_seq'::regclass);

--
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);

--
-- Name: vale_salida id_vale; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vale_salida ALTER COLUMN id_vale SET DEFAULT nextval('public.vale_salida_id_vale_seq'::regclass);

--
-- Name: almacen almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacen
    ADD CONSTRAINT almacen_pkey PRIMARY KEY (id_almacen);

--
-- Name: camion camion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camion
    ADD CONSTRAINT camion_pkey PRIMARY KEY (id_camion);

--
-- Name: categoria_almacen categoria_almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_almacen
    ADD CONSTRAINT categoria_almacen_pkey PRIMARY KEY (id_categoria);

--
-- Name: almacen ck_almacen_stock_no_negativo; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.almacen
    ADD CONSTRAINT ck_almacen_stock_no_negativo CHECK (("cantidadStock" >= (0)::numeric)) NOT VALID;

--
-- Name: operaciones ck_operaciones_aseguradora; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.operaciones
    ADD CONSTRAINT ck_operaciones_aseguradora CHECK ((((tipo_proyecto)::text <> 'Aseguradora'::text) OR ((aseguradora IS NOT NULL) AND (fecha_entrega_comprometida IS NOT NULL)))) NOT VALID;

--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);

--
-- Name: compra_partida compra_partida_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra_partida
    ADD CONSTRAINT compra_partida_pkey PRIMARY KEY (id_partida);

--
-- Name: compra compra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_pkey PRIMARY KEY (id_compra);

--
-- Name: cotizacion cotizacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_pkey PRIMARY KEY (id_cotizacion);

--
-- Name: departamento departamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departamento
    ADD CONSTRAINT departamento_pkey PRIMARY KEY (id_departamento);

--
-- Name: detalle_cotizacion detalle_cotizacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_cotizacion
    ADD CONSTRAINT detalle_cotizacion_pkey PRIMARY KEY (id_detalle_cotizacion);

--
-- Name: devolucion_proveedor devolucion_proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucion_proveedor
    ADD CONSTRAINT devolucion_proveedor_pkey PRIMARY KEY (id_devolucion);

--
-- Name: equipo_almacen equipo_almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo_almacen
    ADD CONSTRAINT equipo_almacen_pkey PRIMARY KEY (id_equipo);

--
-- Name: factura factura_operacion_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_operacion_id_key UNIQUE (operacion_id);

--
-- Name: factura factura_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id_factura);

--
-- Name: movimiento_almacen movimiento_almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimiento_almacen
    ADD CONSTRAINT movimiento_almacen_pkey PRIMARY KEY (id_movimiento);

--
-- Name: notificacion notificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacion
    ADD CONSTRAINT notificacion_pkey PRIMARY KEY (id_notificacion);

--
-- Name: operaciones operaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_pkey PRIMARY KEY (id_operacion);

--
-- Name: proveedor proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id_proveedor);

--
-- Name: proyecto_documento proyecto_documento_nombre_archivo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_documento
    ADD CONSTRAINT proyecto_documento_nombre_archivo_key UNIQUE (nombre_archivo);

--
-- Name: proyecto_documento proyecto_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_documento
    ADD CONSTRAINT proyecto_documento_pkey PRIMARY KEY (id_documento);

--
-- Name: proyecto_etapa proyecto_etapa_operacion_id_orden_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_etapa
    ADD CONSTRAINT proyecto_etapa_operacion_id_orden_key UNIQUE (operacion_id, orden);

--
-- Name: proyecto_etapa proyecto_etapa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_etapa
    ADD CONSTRAINT proyecto_etapa_pkey PRIMARY KEY (id_etapa);

--
-- Name: proyecto_foto proyecto_foto_nombre_archivo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_foto
    ADD CONSTRAINT proyecto_foto_nombre_archivo_key UNIQUE (nombre_archivo);

--
-- Name: proyecto_foto proyecto_foto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_foto
    ADD CONSTRAINT proyecto_foto_pkey PRIMARY KEY (id_foto);

--
-- Name: proyecto_refaccion proyecto_refaccion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_refaccion
    ADD CONSTRAINT proyecto_refaccion_pkey PRIMARY KEY (id_refaccion);

--
-- Name: resguardo_almacen resguardo_almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resguardo_almacen
    ADD CONSTRAINT resguardo_almacen_pkey PRIMARY KEY (id_resguardo);

--
-- Name: solicitud_almacen solicitud_almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_almacen
    ADD CONSTRAINT solicitud_almacen_pkey PRIMARY KEY (id_solicitud_almacen);

--
-- Name: solicitud_compra solicitud_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_compra
    ADD CONSTRAINT solicitud_compra_pkey PRIMARY KEY (id_solicitud_compra);

--
-- Name: trabajador trabajador_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajador
    ADD CONSTRAINT trabajador_pkey PRIMARY KEY (id_trabajador);

--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);

--
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);

--
-- Name: vale_salida vale_salida_operacion_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vale_salida
    ADD CONSTRAINT vale_salida_operacion_id_key UNIQUE (operacion_id);

--
-- Name: vale_salida vale_salida_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vale_salida
    ADD CONSTRAINT vale_salida_pkey PRIMARY KEY (id_vale);

--
-- Name: ix_notificacion_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notificacion_rol ON public.notificacion USING btree (rol_destino, id_notificacion DESC);

--
-- Name: ux_categoria_almacen_nombre; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_categoria_almacen_nombre ON public.categoria_almacen USING btree (lower((nombre)::text));

--
-- Name: ux_compra_folio; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_compra_folio ON public.compra USING btree (folio) WHERE (folio IS NOT NULL);

--
-- Name: almacen almacen_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacen
    ADD CONSTRAINT almacen_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categoria_almacen(id_categoria);

--
-- Name: camion camion_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camion
    ADD CONSTRAINT camion_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.cliente(id_cliente);

--
-- Name: compra compra_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: compra_partida compra_partida_compra_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra_partida
    ADD CONSTRAINT compra_partida_compra_id_fkey FOREIGN KEY (compra_id) REFERENCES public.compra(id_compra) ON DELETE CASCADE;

--
-- Name: compra compra_solicitud_compra_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_solicitud_compra_id_fkey FOREIGN KEY (solicitud_compra_id) REFERENCES public.solicitud_compra(id_solicitud_compra);

--
-- Name: cotizacion cotizacion_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: cotizacion cotizacion_trabajador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_trabajador_id_fkey FOREIGN KEY (trabajador_id) REFERENCES public.trabajador(id_trabajador);

--
-- Name: detalle_cotizacion detalle_cotizacion_cotizacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_cotizacion
    ADD CONSTRAINT detalle_cotizacion_cotizacion_id_fkey FOREIGN KEY (cotizacion_id) REFERENCES public.cotizacion(id_cotizacion);

--
-- Name: detalle_cotizacion detalle_cotizacion_trabajador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_cotizacion
    ADD CONSTRAINT detalle_cotizacion_trabajador_id_fkey FOREIGN KEY (trabajador_id) REFERENCES public.trabajador(id_trabajador);

--
-- Name: devolucion_proveedor devolucion_proveedor_compra_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucion_proveedor
    ADD CONSTRAINT devolucion_proveedor_compra_id_fkey FOREIGN KEY (compra_id) REFERENCES public.compra(id_compra);

--
-- Name: devolucion_proveedor devolucion_proveedor_proveedor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucion_proveedor
    ADD CONSTRAINT devolucion_proveedor_proveedor_id_fkey FOREIGN KEY (proveedor_id) REFERENCES public.proveedor(id_proveedor);

--
-- Name: equipo_almacen equipo_almacen_almacen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo_almacen
    ADD CONSTRAINT equipo_almacen_almacen_id_fkey FOREIGN KEY (almacen_id) REFERENCES public.almacen(id_almacen);

--
-- Name: equipo_almacen equipo_almacen_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo_almacen
    ADD CONSTRAINT equipo_almacen_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: equipo_almacen equipo_almacen_trabajador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo_almacen
    ADD CONSTRAINT equipo_almacen_trabajador_id_fkey FOREIGN KEY (trabajador_id) REFERENCES public.trabajador(id_trabajador);

--
-- Name: factura factura_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: movimiento_almacen movimiento_almacen_almacen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimiento_almacen
    ADD CONSTRAINT movimiento_almacen_almacen_id_fkey FOREIGN KEY (almacen_id) REFERENCES public.almacen(id_almacen);

--
-- Name: movimiento_almacen movimiento_almacen_compra_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimiento_almacen
    ADD CONSTRAINT movimiento_almacen_compra_id_fkey FOREIGN KEY (compra_id) REFERENCES public.compra(id_compra);

--
-- Name: movimiento_almacen movimiento_almacen_solicitud_almacen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimiento_almacen
    ADD CONSTRAINT movimiento_almacen_solicitud_almacen_id_fkey FOREIGN KEY (solicitud_almacen_id) REFERENCES public.solicitud_almacen(id_solicitud_almacen);

--
-- Name: operaciones operaciones_camion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_camion_id_fkey FOREIGN KEY (camion_id) REFERENCES public.camion(id_camion);

--
-- Name: operaciones operaciones_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id_usuario);

--
-- Name: proyecto_documento proyecto_documento_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_documento
    ADD CONSTRAINT proyecto_documento_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion) ON DELETE CASCADE;

--
-- Name: proyecto_etapa proyecto_etapa_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_etapa
    ADD CONSTRAINT proyecto_etapa_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion) ON DELETE CASCADE;

--
-- Name: proyecto_foto proyecto_foto_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_foto
    ADD CONSTRAINT proyecto_foto_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion) ON DELETE CASCADE;

--
-- Name: proyecto_refaccion proyecto_refaccion_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto_refaccion
    ADD CONSTRAINT proyecto_refaccion_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion) ON DELETE CASCADE;

--
-- Name: resguardo_almacen resguardo_almacen_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resguardo_almacen
    ADD CONSTRAINT resguardo_almacen_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id_usuario);

--
-- Name: solicitud_almacen solicitud_almacen_almacen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_almacen
    ADD CONSTRAINT solicitud_almacen_almacen_id_fkey FOREIGN KEY (almacen_id) REFERENCES public.almacen(id_almacen);

--
-- Name: solicitud_almacen solicitud_almacen_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_almacen
    ADD CONSTRAINT solicitud_almacen_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: solicitud_compra solicitud_compra_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_compra
    ADD CONSTRAINT solicitud_compra_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: solicitud_compra solicitud_compra_proveedor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_compra
    ADD CONSTRAINT solicitud_compra_proveedor_id_fkey FOREIGN KEY (proveedor_id) REFERENCES public.proveedor(id_proveedor);

--
-- Name: solicitud_compra solicitud_compra_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_compra
    ADD CONSTRAINT solicitud_compra_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id_usuario);

--
-- Name: usuario usuario_trabajador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_trabajador_id_fkey FOREIGN KEY (trabajador_id) REFERENCES public.trabajador(id_trabajador);

--
-- Name: vale_salida vale_salida_operacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vale_salida
    ADD CONSTRAINT vale_salida_operacion_id_fkey FOREIGN KEY (operacion_id) REFERENCES public.operaciones(id_operacion);

--
-- Name: vale_salida vale_salida_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vale_salida
    ADD CONSTRAINT vale_salida_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id_usuario);

--
-- PostgreSQL database dump complete
--


-- Datos iniciales: categorías de almacén
INSERT INTO public.categoria_almacen VALUES (1, 'Carrocería');
INSERT INTO public.categoria_almacen VALUES (2, 'Eléctrico');
INSERT INTO public.categoria_almacen VALUES (3, 'Fluidos');
INSERT INTO public.categoria_almacen VALUES (4, 'Frenos');
INSERT INTO public.categoria_almacen VALUES (5, 'Herramientas');
INSERT INTO public.categoria_almacen VALUES (6, 'Motor');
INSERT INTO public.categoria_almacen VALUES (7, 'Suspensión');
INSERT INTO public.categoria_almacen VALUES (8, 'Transmisión');
SELECT pg_catalog.setval('public.categoria_almacen_id_categoria_seq', 8, true);

-- Registro de migraciones para DbUp (evita que la API las vuelva a ejecutar)
CREATE TABLE IF NOT EXISTS public.schemaversions (
    schemaversionsid SERIAL PRIMARY KEY,
    scriptname VARCHAR(255) NOT NULL,
    applied TIMESTAMP NOT NULL
);
INSERT INTO public.schemaversions (scriptname, applied) VALUES
    ('Autozen.Api.Database.Migrations.0001_esquema_base.sql', now()),
    ('Autozen.Api.Database.Migrations.0002_stock_no_negativo.sql', now()),
    ('Autozen.Api.Database.Migrations.0003_modelo_app.sql', now()),
    ('Autozen.Api.Database.Migrations.0004_compras_documentos_resguardos_avisos.sql', now());
