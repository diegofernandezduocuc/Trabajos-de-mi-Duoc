-- un pequeño ajuste para el  formato numerico (separador de miles = punto)
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';

/* ==========================================
   CASO 1 - REPORTERIA DE ASESORIAS
   Profesionales con asesorias en Banca y Retail 
   ========================================== */

SELECT
    resumen.id_profesional                              AS "ID",
    resumen.profesional                                 AS "PROFESIONAL",
    resumen.nro_ases_banca                              AS "NRO ASESORIA BANCA",
    TO_CHAR(resumen.monto_total_banca,
            'FM$999G999G999G999')                       AS "MONTO TOTAL BANCA",
    resumen.nro_ases_retail                             AS "NRO ASESORIA RETAIL",
    TO_CHAR(resumen.monto_total_retail,
            'FM$999G999G999G999')                       AS "MONTO TOTAL RETAIL",
    resumen.total_asesorias                             AS "TOTAL ASESORIAS",
    TO_CHAR(resumen.total_honorarios,
            'FM$999G999G999G999')                       AS "TOTAL HONORARIOS"
FROM (
    -- Subconsulta que combina banca y retail mediante UNION ALL
    SELECT
        datos.id_profesional,
        INITCAP(datos.appaterno || ' ' ||
                datos.apmaterno || ' ' ||
                datos.nombre)            AS profesional,
        SUM(datos.nro_ases_banca)        AS nro_ases_banca,
        SUM(datos.monto_banca)           AS monto_total_banca,
        SUM(datos.nro_ases_retail)       AS nro_ases_retail,
        SUM(datos.monto_retail)          AS monto_total_retail,
        SUM(datos.nro_ases_banca +
            datos.nro_ases_retail)       AS total_asesorias,
        SUM(datos.monto_banca +
            datos.monto_retail)          AS total_honorarios
    FROM (
        -- Parte 1:  asesorias en Banca 
        SELECT
            p.id_profesional,
            p.appaterno,
            p.apmaterno,
            p.nombre,
            1                    AS nro_ases_banca,
            0                    AS nro_ases_retail,
            NVL(a.honorario, 0)  AS monto_banca,
            0                    AS monto_retail
        FROM profesional p
             JOIN asesoria a ON a.id_profesional = p.id_profesional
             JOIN empresa  e ON e.cod_empresa    = a.cod_empresa
             JOIN sector   s ON s.cod_sector     = e.cod_sector
        WHERE s.cod_sector = 3

        UNION ALL

        -- Parte 2: asesorias en Retail 
        SELECT
            p.id_profesional,
            p.appaterno,
            p.apmaterno,
            p.nombre,
            0                    AS nro_ases_banca,
            1                    AS nro_ases_retail,
            0                    AS monto_banca,
            NVL(a.honorario, 0)  AS monto_retail
        FROM profesional p
             JOIN asesoria a ON a.id_profesional = p.id_profesional
             JOIN empresa  e ON e.cod_empresa    = a.cod_empresa
             JOIN sector   s ON s.cod_sector     = e.cod_sector
        WHERE s.cod_sector = 4
    ) datos
    GROUP BY
        datos.id_profesional,
        datos.appaterno,
        datos.apmaterno,
        datos.nombre
    HAVING
        SUM(datos.nro_ases_banca)  > 0
    AND SUM(datos.nro_ases_retail) > 0
) resumen
ORDER BY
    "ID";


/* ==========================================
   CASO 2 - RESUMEN DE HONORARIOS
   Tabla de salida:  REPORTE_MES
   ========================================== */

-- Borrar la tabla REPORTE_MES si es que existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE REPORTE_MES CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        -- ORA-00942: table or view does not exist
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- Crear estructura de la tabla REPORTE_MES (sin los datos)
CREATE TABLE REPORTE_MES AS
SELECT
    p.id_profesional                                   AS id_prof,
    INITCAP(p.appaterno || ' ' ||
            p.apmaterno || ' ' ||
            p.nombre)                                  AS nombre_completo,
    pr.nombre_profesion                                AS nombre_profesion,
    c.nom_comuna                                       AS nom_comuna,
    COUNT(*)                                           AS nro_asesorias,
    ROUND(NVL(SUM(a.honorario), 0))                    AS monto_total_honorarios,
    ROUND(NVL(AVG(a.honorario), 0))                    AS promedio_honorario,
    ROUND(NVL(MIN(a.honorario), 0))                    AS honorario_mnmo,
    ROUND(NVL(MAX(a.honorario), 0))                    AS honorario_maximo
FROM profesional p
     JOIN asesoria   a  ON a.id_profesional = p.id_profesional
     JOIN profesion  pr ON pr.cod_profesion = p.cod_profesion
     JOIN comuna     c  ON c.cod_comuna      = p.cod_comuna
WHERE EXTRACT(YEAR  FROM a.fin_asesoria) =
      EXTRACT(YEAR  FROM ADD_MONTHS(TRUNC(SYSDATE), -12))
  AND EXTRACT(MONTH FROM a.fin_asesoria) = 4   -- Abril del anio pasado
  AND 1 = 2                                    -- crea estructura sin filas
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna;

--  Cargar datos en REPORTE_MES mediante INSERT (DML)
INSERT INTO REPORTE_MES
SELECT
    p.id_profesional                                   AS id_prof,
    INITCAP(p.appaterno || ' ' ||
            p.apmaterno || ' ' ||
            p.nombre)                                  AS nombre_completo,
    pr.nombre_profesion                                AS nombre_profesion,
    c.nom_comuna                                       AS nom_comuna,
    COUNT(*)                                           AS nro_asesorias,
    ROUND(NVL(SUM(a.honorario), 0))                    AS monto_total_honorarios,
    ROUND(NVL(AVG(a.honorario), 0))                    AS promedio_honorario,
    ROUND(NVL(MIN(a.honorario), 0))                    AS honorario_mnmo,
    ROUND(NVL(MAX(a.honorario), 0))                    AS honorario_maximo
FROM profesional p
     JOIN asesoria   a  ON a.id_profesional = p.id_profesional
     JOIN profesion  pr ON pr.cod_profesion = p.cod_profesion
     JOIN comuna     c  ON c.cod_comuna      = p.cod_comuna
WHERE EXTRACT(YEAR  FROM a.fin_asesoria) =
      EXTRACT(YEAR  FROM ADD_MONTHS(TRUNC(SYSDATE), -12))
  AND EXTRACT(MONTH FROM a.fin_asesoria) = 4   -- Abril del anio pasado
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna;


DELETE FROM REPORTE_MES
WHERE nro_asesorias = 0;

-- Consulta final del resumen de honorarios
SELECT
    id_prof                                         AS "ID PROF",
    nombre_completo                                 AS "NOMBRE COMPLETO",
    nombre_profesion                                AS "NOMBRE PROFESION",
    nom_comuna                                      AS "NOM COMUNA",
    nro_asesorias                                   AS "NRO ASESORIAS",
    TO_CHAR(monto_total_honorarios,
            'FM$999G999G999G999')                   AS "MONTO TOTAL HONORARIOS",
    TO_CHAR(promedio_honorario,
            'FM$999G999G999G999')                   AS "PROMEDIO HONORARIO",
    TO_CHAR(honorario_mnmo,
            'FM$999G999G999G999')                   AS "HONORARIO MNMO",
    TO_CHAR(honorario_maximo,
            'FM$999G999G999G999')                   AS "HONORARIO MAXIMO"
FROM REPORTE_MES
ORDER BY id_prof;


/* ==========================================
     CASO  3 -  MODIFICACION DE  HONORARIOS
   Actualizacion de sueldo segun honorarios
   de ejemplo marzo del año pasado
   ========================================== */

-- este es el reporte de ANTES de actualizar sueldo
SELECT
    TO_NUMBER(TO_CHAR(ROUND(NVL(SUM(a.honorario), 0))))
                                        AS "HONORARIO",
    p.id_profesional                     AS "ID PROFESIONAL",
    p.numrun_prof                        AS "NUMRUN PROF",
    p.sueldo                             AS "SUELDO"
FROM profesional p
JOIN asesoria a
  ON a.id_profesional = p.id_profesional
WHERE EXTRACT(YEAR  FROM a.fin_asesoria) =
      EXTRACT(YEAR  FROM ADD_MONTHS(TRUNC(SYSDATE), -12))
  AND EXTRACT(MONTH FROM a.fin_asesoria) = 3   -- Marzo del anio pasado
GROUP BY
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY
    p.id_profesional;

-- Proceso de actualizacion de sueldo 
-- La regla es 
--   HONORARIO <  1.000.000  -> sueldo +10%
--   HONORARIO >= 1.000.000  -> sueldo  +15%
UPDATE profesional p
SET sueldo =
(
    SELECT CASE
               WHEN TO_NUMBER(
                        TO_CHAR(ROUND(NVL(SUM(a.honorario), 0)))
                    ) < 1000000
                    THEN ROUND(p.sueldo * 1.10)
               ELSE     ROUND(p.sueldo * 1.15)
           END
    FROM asesoria a
    WHERE a.id_profesional = p.id_profesional
      AND EXTRACT(YEAR  FROM a.fin_asesoria) =
          EXTRACT(YEAR  FROM ADD_MONTHS(TRUNC(SYSDATE), -12))
      AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
    GROUP BY a.id_profesional
)
WHERE EXISTS (
    SELECT 1
    FROM asesoria a
    WHERE a.id_profesional = p.id_profesional
      AND EXTRACT(YEAR  FROM a.fin_asesoria) =
          EXTRACT(YEAR  FROM ADD_MONTHS(TRUNC(SYSDATE), -12))
      AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
);

-- Reporte  de  DESPUES de actualizar el sueldo
SELECT
    TO_NUMBER(TO_CHAR(ROUND(NVL(SUM(a.honorario), 0))))
                                        AS "HONORARIO",
    p.id_profesional                     AS "ID PROFESIONAL",
    p.numrun_prof                        AS "NUMRUN PROF",
    p.sueldo                             AS "SUELDO"
FROM profesional p
JOIN asesoria a
  ON a.id_profesional = p.id_profesional
WHERE EXTRACT(YEAR  FROM a.fin_asesoria) =
      EXTRACT(YEAR  FROM ADD_MONTHS(TRUNC(SYSDATE), -12))
  AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
GROUP BY
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY
    p.id_profesional;

-- Mientras hago las pruebas debo poner rolllback para que no se guarde permanente:
ROLLBACK;
-- Para dejar los cambios permanentes debo poner COMMIT en lugar de ROLLBACK.
-- COMMIT;