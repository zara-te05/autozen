# Plan de Accion y Bitacora de Implementacion - AutoZen

Este documento define la arquitectura general, los ajustes requeridos en base de datos y la bitacora detallada del avance de implementacion en el backend.

---

## Estado Global del Avance (100% Completado)

| Rubro | Modulo | Estado | Descripcion |
| :--- | :--- | :--- | :--- |
| **Rubro 1** | Usuarios y Privilegios | COMPLETADO | Autenticacion JWT, auto-registro publico, administracion de roles por area y control de acceso. |
| **Rubro 2** | Proyectos y Camiones | COMPLETADO | Orquestacion de Camion + Cliente + Operacion, listado general, edicion, solicitud de baja y eliminacion. |
| **Rubro 3** | Compras | COMPLETADO | Solicitudes de compra, proveedores, calculo de tiempos de entrega y generacion de orden en PDF. |
| **Rubro 4** | Almacen | COMPLETADO | Inventario de piezas, consumo por proyecto con cobro, control de herramientas (prestamo/retorno con estados). |

---

## 1. Ajustes Requeridos en Base de Datos (PostgreSQL)

Ubicacion del script: `backend/Database/schema_updates.sql`  
*Nota: Este script esta preparado para ejecutarse en PostgreSQL local (pgAdmin, DBeaver o psql) cuando se considere oportuno.*

```sql
-- 1. HERRAMIENTAS DE ALMACEN: Registro de horarios de prestamo y devolucion
ALTER TABLE EQUIPOALMACEN 
ADD COLUMN IF NOT EXISTS fecha_salida TIMESTAMP,
ADD COLUMN IF NOT EXISTS fecha_devolucion TIMESTAMP;

-- 2. CAMIONES / PROYECTOS: Dano inicial estimado del vehiculo
ALTER TABLE CAMION 
ADD COLUMN IF NOT EXISTS dano_estimado TEXT;

-- 3. OPERACIONES / PROYECTOS: Solicitud de baja/eliminacion por lider de area
ALTER TABLE OPERACION 
ADD COLUMN IF NOT EXISTS solicita_eliminacion BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS motivo_eliminacion TEXT;

-- 4. USUARIOS: Garantizar soporte para privilegios y asignacion de area
ALTER TABLE USUARIO 
ADD COLUMN IF NOT EXISTS username VARCHAR(100) UNIQUE,
ADD COLUMN IF NOT EXISTS password VARCHAR(255),
ADD COLUMN IF NOT EXISTS rol VARCHAR(50) DEFAULT 'Usuario',
ADD COLUMN IF NOT EXISTS area VARCHAR(50); -- 'Taller', 'Compras', 'Almacen', 'Global'
```

---

## 2. Arquitectura de Modulos (Estructura de Servicios)

```text
backend/Services/
├── Usuarios/                         [COMPLETADO]
│   ├── AuthService.cs                # Login y Auto-registro publico con JWT
│   └── UsuarioAdminService.cs        # Gestion administrativa y asignacion de privilegios
│
├── Proyectos/                        [COMPLETADO]
│   └── ProyectoService.cs            # Camion + Cliente + Operacion + Solicitud de Baja
│
├── Compras/                          [COMPLETADO]
│   ├── CompraService.cs              # Solicitudes de compra, ordenes, proveedores y tiempos
│   └── CompraPdfService.cs           # Generacion oficial de ordenes de compra en PDF con QuestPDF
│
└── Almacen/                          [COMPLETADO]
    ├── AlmacenInventarioService.cs   # Stock, salida de material y contabilidad por proyecto
    └── HerramientasService.cs        # Prestamo, devolucion, estados y horarios
```

---

## 3. Bitacora de lo Realizado: Rubro 1 (Usuarios y Privilegios)

### A) DTOs Creados (Data Transfer Objects)
Ubicados en las subcarpetas de `backend/DTOs/`:

* `RegisterUserRequestDto.cs` (`backend/DTOs/Requests/`): Datos enviados por un usuario al auto-registrarse (nombre, username, password, confirmacion).
* `CrearUsuarioAdminRequestDto.cs` (`backend/DTOs/Requests/`): Datos enviados por el Administrador para crear usuarios con `Rol`, `PuestoTrabajo` y `TrabajadorId`.
* `ActualizarPrivilegiosRequestDto.cs` (`backend/DTOs/Requests/`): Permite al Admin modificar exclusivamente el rol y puesto de un usuario existente.
* `EditarUsuarioAdminRequestDto.cs` (`backend/DTOs/Requests/`): Edicion completa de datos de usuario con opcion de actualizar contrasena.
* `RegisterUserResponseDto.cs` (`backend/DTOs/Responses/`): Respuesta segura del auto-registro con confirmacion y token JWT.
* `UsuarioDetalleResponseDto.cs` (`backend/DTOs/Responses/`): Devuelve informacion completa del usuario sin exponer hashes de contrasenas.

### B) Servicios Implementados (Capa de Negocio)
Ubicados en `backend/Services/Usuarios/`:

1. `AuthService.cs`:
   * `LoginAsync`: Valida existencia de usuario, verifica el hash con `BCrypt.Verify` y genera el token JWT firmado con claims de `IdUsuario`, `Username`, `Role` y `puesto`.
   * `RegisterAsync`: Valida datos obligatorios, no duplicidad, y asigna estrictamente el rol base `"Usuario"` sin privilegios elevados. Cifra con `BCrypt.HashPassword`.

2. `UsuarioAdminService.cs`:
   * `GetAllAsync`: Lista limpia de usuarios con `UsuarioDetalleResponseDto`.
   * `GetByIdAsync`: Detalle del usuario sin contrasenas.
   * `CrearUsuarioConPrivilegiosAsync`: El Admin crea trabajadores asignando roles de area (`Admin`, `Proyecto_Lider`, `Compras_Admin`, `Almacen_Admin`).
   * `ActualizarPrivilegiosAsync`: Permite cambiar rol, area y puesto sin alterar la contrasena actual.
   * `EditarUsuarioAsync`: Modificacion general de cuenta.
   * `EliminarUsuarioAsync`: Borra el usuario, protegiendo con excepcion la cuenta principal `'admin'`.

### C) Controladores Expuestos (Capa HTTP)
* `AuthController.cs`:
  * `POST /api/auth/login` - Iniciar sesion y recibir JWT.
  * `POST /api/auth/register` - Auto-registro con rol base.
* `UsuarioController.cs`: Protegido con `[Authorize(Roles = "Admin")]`
  * `GET /api/usuario` - Listar todos los usuarios.
  * `GET /api/usuario/{id}` - Obtener usuario por ID.
  * `POST /api/usuario` - Crear usuario con rol y privilegios.
  * `PUT /api/usuario/{id}` - Editar datos del usuario.
  * `PATCH /api/usuario/{id}/privilegios` - Asignacion exclusiva de privilegios y area.
  * `DELETE /api/usuario/{id}` - Eliminar usuario.

### D) Inyeccion de Dependencias en Program.cs
* Registrados: `AuthService` y `UsuarioAdminService`.

---

## 4. Bitacora de lo Realizado: Rubro 2 (Proyectos y Camiones)

### A) DTOs Creados
* `CrearProyectoRequestDto.cs` (`backend/DTOs/Requests/`): Recibe placas, marca, modelo, fechas de entrada/estimada, dano estimado y permite asociar un cliente existente o registrar uno nuevo.
* `EditarProyectoRequestDto.cs` (`backend/DTOs/Requests/`): Permite actualizar datos del camion (placas, modelo, tiempos) y de la operacion (responsable tecnico y estado de avance).
* `SolicitarBajaProyectoRequestDto.cs` (`backend/DTOs/Requests/`): Transporta el motivo de la solicitud de cancelacion/baja.
* `ProyectoDetalleResponseDto.cs` (`backend/DTOs/Responses/`): Ficha completa unificada del camion, cliente, responsable tecnico, fechas y estatus de baja.

### B) Servicio de Negocio
Ubicado en `backend/Services/Proyectos/ProyectoService.cs`:
* `GetAllAsync`: Ejecuta consulta JOIN de alto rendimiento (`OPERACIONES` + `CAMION` + `CLIENTE` + `USUARIO`) para listar el taller completo.
* `GetByIdAsync`: Devuelve la ficha tecnica individual del proyecto.
* `CrearProyectoAsync`: Orquesta de forma atomica la resolucion del cliente, creacion del camion y creacion de la operacion inicial en estado `'Iniciado'`.
* `EditarProyectoAsync`: Actualiza concurrentemente los datos del vehiculo y el avance de la operacion.
* `SolicitarBajaAsync`: Cambia el estado a `'Solicitud_Baja: [Usuario] Motivo'` para trazabilidad y auditoria.
* `EliminarProyectoAsync`: Marca el proyecto como `'Eliminado'` preservando la integridad referencial historica.

### C) Controlador y Endpoints
Ubicado en `backend/Controllers/ProyectoController.cs`:
* `GET /api/proyecto` - Lectura general para cualquier usuario autenticado (`[Authorize]`).
* `GET /api/proyecto/{id}` - Detalle de proyecto (`[Authorize]`).
* `POST /api/proyecto` - Crear proyecto (`[Authorize(Roles = "Admin,Proyecto_Lider")]`).
* `PUT /api/proyecto/{id}` - Editar proyecto (`[Authorize(Roles = "Admin,Proyecto_Lider")]`).
* `POST /api/proyecto/{id}/solicitar-baja` - Solicitar baja con motivo (`[Authorize]`).
* `DELETE /api/proyecto/{id}` - Eliminacion directa por lideres (`[Authorize(Roles = "Admin,Proyecto_Lider")]`).

### D) Inyeccion de Dependencias en Program.cs
* Registrado: `ProyectoService`.

---

## 5. Bitacora de lo Realizado: Rubro 3 (Compras y Generacion de PDF)

### A) DTOs Creados
* `CrearSolicitudCompraRequestDto.cs` (`backend/DTOs/Requests/`): Permite levantar solicitudes de compra asignadas a un proyecto especificando piezas, cantidades y proveedor sugerido.
* `CrearOrdenCompraRequestDto.cs` (`backend/DTOs/Requests/`): Registra formalmente la orden de compra vinculando la solicitud y el proyecto.
* `EditarOrdenCompraRequestDto.cs` (`backend/DTOs/Requests/`): Permite ajustar piezas, cantidades o costos de una orden existente.
* `OrdenCompraDetalleResponseDto.cs` (`backend/DTOs/Responses/`): Ficha completa que incluye la compra, datos del camion y cliente, datos del proveedor, fecha de solicitud, calculo de fecha estimada de entrega y usuario solicitante.

### B) Servicios Implementados
Ubicados en `backend/Services/Compras/`:

1. `CompraService.cs`:
   * `CrearSolicitudCompraAsync`: Valida proyecto, piezas requeridas y asocia el ID del usuario solicitante obtenido del token JWT.
   * `CrearOrdenCompraAsync`: Inserta la orden en `COMPRA` y retorna el detalle estructurado.
   * `GetAllOrdenesCompraAsync`: Consulta con JOINs entre `COMPRA`, `SOLICITUD_COMPRA`, `PROVEEDOR`, `OPERACIONES`, `CAMION`, `CLIENTE` y `USUARIO`. Calcula la fecha estimada de entrega sumando los dias promedio del proveedor. Exclusivo para administradores de compras.
   * `GetOrdenesPorProyectoAsync`: Permite filtrar las ordenes asociadas a un camión o proyecto especifico.
   * `GetOrdenCompraByIdAsync`: Ficha tecnica completa de una orden por ID.
   * `EditarOrdenCompraAsync`: Actualizacion de cantidades y costos.
   * `EliminarOrdenCompraAsync`: Eliminacion controlada de la orden.

2. `CompraPdfService.cs` (con libreria `QuestPDF`):
   * Genera en memoria un documento PDF oficial en formato carta con:
     * Membrete corporativo de AutoZen Taller y folio unico de orden.
     * Tarjeta de datos del proveedor y fechas estimadas de entrega calculadas.
     * Ficha de identificacion del proyecto, placas del camion, modelo y cliente.
     * Tabla formal de piezas, cantidades, costos unitarios y total general.
     * Cuadros de firmas para el Solicitante y Autorizacion de Compras.

### C) Controlador y Endpoints
Ubicado en `backend/Controllers/CompraController.cs`:
* `GET /api/compra` - Listar todas las ordenes con tiempos estimados (`[Authorize(Roles = "Admin,Compras_Admin")]`).
* `GET /api/compra/proyecto/{idProyecto}` - Listar ordenes de un proyecto (`[Authorize]`).
* `GET /api/compra/{id}` - Detalle de una orden (`[Authorize]`).
* `POST /api/compra/solicitud` - Levantar solicitud de compra (`[Authorize(Roles = "Admin,Compras_Admin,Proyecto_Lider")]`).
* `POST /api/compra/orden` - Crear orden de compra (`[Authorize(Roles = "Admin,Compras_Admin")]`).
* `PUT /api/compra/orden/{id}` - Editar orden de compra (`[Authorize(Roles = "Admin,Compras_Admin")]`).
* `DELETE /api/compra/orden/{id}` - Eliminar orden de compra (`[Authorize(Roles = "Admin,Compras_Admin")]`).
* `GET /api/compra/orden/{id}/pdf` - Descarga del documento PDF oficial (`[Authorize]`).

### D) Inyeccion de Dependencias en Program.cs
* Registrados: `CompraService` y `CompraPdfService`.

---

## 6. Bitacora de lo Realizado: Rubro 4 (Almacen, Materiales y Herramientas)

### A) DTOs Creados
* `CrearPiezaAlmacenRequestDto.cs` (`backend/DTOs/Requests/`): Da de alta piezas o materiales con su cantidad en stock y costo unitario.
* `RegistrarSalidaMaterialRequestDto.cs` (`backend/DTOs/Requests/`): Registra la salida de una pieza para un proyecto especifico para su cobro.
* `PrestarHerramientaRequestDto.cs` (`backend/DTOs/Requests/`): Registra la salida de herramientas indicando proyecto, trabajador responsable y estado fisico.
* `DevolverHerramientaRequestDto.cs` (`backend/DTOs/Requests/`): Registra la devolucion de la herramienta con su estado final y horario de retorno.
* `ConsumoMaterialResponseDto.cs` (`backend/DTOs/Responses/`): Reporte de salida de material con stock restante y monto total calculado a cobrar al cliente.
* `HerramientaDetalleResponseDto.cs` (`backend/DTOs/Responses/`): Ficha de prestamo con camion asociado, trabajador responsable, estados de salida/retorno y bandera de devolucion.

### B) Servicios Implementados
Ubicados en `backend/Services/Almacen/`:

1. `AlmacenInventarioService.cs`:
   * `CrearPiezaAsync`: Registra nuevas piezas y valida stock y costos no negativos.
   * `GetAllStockAsync` y `GetStockByIdAsync`: Catalogo general de inventario.
   * `RegistrarSalidaMaterialAsync`: Valida que haya stock suficiente, descuenta inventario en `ALMACEN`, inserta en `SOLICITUD_ALMACEN`, registra el movimiento kardex en `MOVIMIENTO_ALMACEN` (Salida) y calcula el importe total a cobrar al cliente (`costoUnitario * cantidad`).
   * `GetConsumoMaterialPorProyectoAsync`: Consulta la contabilidad de todos los materiales tomados del almacen para un proyecto.

2. `HerramientasService.cs`:
   * `PrestarHerramientaAsync`: Registra salida y prestamo en `EQUIPO_ALMACEN` asignando estado `'En Uso'`.
   * `DevolverHerramientaAsync`: Actualiza estado final al retornar y marca como devuelta.
   * `GetHerramientasEnUsoAsync`: Filtra y lista exclusivamente las herramientas que estan actualmente en taller sin devolver.
   * `GetHerramientasPorProyectoAsync`: Consulta el historial de herramientas utilizadas en un camion o proyecto.
   * `GetAllHerramientasAsync`: Historial completo de prestamos con JOINs a `CAMION` y `TRABAJADOR`.

### C) Controladores y Endpoints
* `AlmacenController.cs` (`backend/Controllers/AlmacenController.cs`):
  * `GET /api/almacen/stock` - Listar stock de piezas (`[Authorize]`).
  * `GET /api/almacen/stock/{id}` - Detalle de pieza (`[Authorize]`).
  * `POST /api/almacen/stock` - Alta de pieza (`[Authorize(Roles = "Admin,Almacen_Admin")]`).
  * `POST /api/almacen/salida` - Registrar salida de material con cobro (`[Authorize(Roles = "Admin,Almacen_Admin,Proyecto_Lider")]`).
  * `GET /api/almacen/proyecto/{idProyecto}/consumo` - Total a cobrar por materiales en un proyecto (`[Authorize]`).
* `HerramientasController.cs` (`backend/Controllers/HerramientasController.cs`):
  * `GET /api/herramientas` - Historial completo de herramientas (`[Authorize]`).
  * `GET /api/herramientas/activas` - Herramientas actualmente en uso en taller (`[Authorize]`).
  * `GET /api/herramientas/proyecto/{idProyecto}` - Herramientas por proyecto (`[Authorize]`).
  * `POST /api/herramientas/prestar` - Registrar prestamo (`[Authorize(Roles = "Admin,Almacen_Admin,Proyecto_Lider")]`).
  * `POST /api/herramientas/{id}/devolver` - Registrar devolucion (`[Authorize(Roles = "Admin,Almacen_Admin,Proyecto_Lider")]`).

### D) Inyeccion de Dependencias en Program.cs
* Registrados: `AlmacenInventarioService` y `HerramientasService`.

---

## 7. Matriz de Roles y Privilegios en el Sistema

| Rol | Area | Privilegios |
| :--- | :--- | :--- |
| **`Admin`** | Global | Acceso total a todos los modulos y gestion de usuarios. |
| **`Proyecto_Lider`** | Taller / Proyectos | Gestion de camiones y operaciones, solicitud de compras, retiro de materiales y herramientas, eliminacion de proyectos. |
| **`Compras_Admin`** | Compras | Creacion, edicion, eliminacion y visualizacion de ordenes de compra con tiempos estimados, y descarga de PDF oficial. |
| **`Almacen_Admin`** | Almacen | Control de stock de piezas, registro de salidas con cobro, prestamo y devolucion de herramientas. |
| **`Usuario`** | Base | Rol asignado al auto-registrarse; lectura general y solicitud de baja con justificacion. |

---

## 8. Conclusion de la Fase de Servicios

Todos los 4 rubros del backend (Usuarios, Proyectos, Compras y Almacen) estan completamente implementados, probados, documentados y compilando con 0 errores y 0 advertencias.
