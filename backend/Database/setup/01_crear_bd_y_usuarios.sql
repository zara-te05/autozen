-- ====================================================================
-- AUTOZEN - Base de datos propia y usuarios con permisos mínimos
--
-- Ejecutar UNA vez, conectado como superusuario (postgres):
--   psql -U postgres -h localhost -v owner_password='...' -v app_password='...' -f 01_crear_bd_y_usuarios.sql
--
-- Roles:
--   autozen_owner : dueño del esquema. Solo lo usan las migraciones (DDL).
--   autozen_app   : el que usa la API. Solo SELECT/INSERT/UPDATE/DELETE.
-- Ninguno es superusuario ni puede crear bases de datos o roles.
-- ====================================================================

CREATE ROLE autozen_owner LOGIN PASSWORD :'owner_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;

CREATE ROLE autozen_app LOGIN PASSWORD :'app_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOINHERIT;

CREATE DATABASE autozen_db OWNER autozen_owner ENCODING 'UTF8' TEMPLATE template0;

REVOKE ALL ON DATABASE autozen_db FROM PUBLIC;
GRANT CONNECT ON DATABASE autozen_db TO autozen_app;

\connect autozen_db

-- Solo autozen_owner puede crear objetos en el esquema public
ALTER SCHEMA public OWNER TO autozen_owner;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO autozen_app;

-- Todo lo que cree autozen_owner (migraciones) queda accesible a la API automáticamente
ALTER DEFAULT PRIVILEGES FOR ROLE autozen_owner IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO autozen_app;
ALTER DEFAULT PRIVILEGES FOR ROLE autozen_owner IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO autozen_app;
