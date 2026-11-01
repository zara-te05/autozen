-- ====================================================================
-- AUTOZEN - Permisos sobre datos importados
--
-- Ejecutar DESPUÉS de importar el respaldo de la base anterior en autozen_db:
--   psql -U autozen_owner -h localhost -d autozen_db -f 02_permisos_datos_importados.sql
--
-- Los "default privileges" solo aplican a objetos nuevos; este script cubre los que ya existían.
-- ====================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO autozen_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO autozen_app;
