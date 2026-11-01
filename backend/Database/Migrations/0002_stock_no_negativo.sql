-- El stock nunca puede quedar negativo, aunque alguien escriba directo en la base.
-- NOT VALID: aplica a filas nuevas o modificadas sin fallar si ya existen datos negativos.
-- Cuando corrijas esos datos, ejecuta: ALTER TABLE ALMACEN VALIDATE CONSTRAINT ck_almacen_stock_no_negativo;
ALTER TABLE ALMACEN
    ADD CONSTRAINT ck_almacen_stock_no_negativo CHECK ("cantidadStock" >= 0) NOT VALID;
