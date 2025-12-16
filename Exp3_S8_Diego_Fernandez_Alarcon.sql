-- PRY2205_USER1 / contr :PRY2205_USER1
-- PRY2205_USER2 /        PRY2205_USER2

--SYSTEM_XEPDB1 (o SYSTEM)  contenedor XEPDB1

-- ===== CASO 1 - SYSTEM_XEPDB1 - Seguridad (usuarios/roles/privilegios) =====

-- 0) Chequeo 
SELECT USER AS USUARIO, SYS_CONTEXT('USERENV','CON_NAME') AS CONTAINER FROM DUAL;

-- 1) Limpieza 
BEGIN EXECUTE IMMEDIATE 'DROP ROLE PRY2205_ROL_D'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE PRY2205_ROL_P'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER PRY2205_USER2 CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER PRY2205_USER1 CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 2) Usuarios  
CREATE USER PRY2205_USER1 IDENTIFIED BY PRY2205_USER1
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2 IDENTIFIED BY PRY2205_USER2
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

-- 3) Roles del caso
CREATE ROLE PRY2205_ROL_D; -- rol del dueño (USER1)
CREATE ROLE PRY2205_ROL_P; -- rol del que consulta/crea cosas del caso 2 (USER2)

-- 4) Privilegios minimos
-- USER1: dueño, crea objetos y administra  sinonimos publicos
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO PRY2205_ROL_D;
GRANT CREATE PUBLIC SYNONYM, DROP PUBLIC SYNONYM TO PRY2205_ROL_D;

-- USER2: se conecta y crea lo del caso 2 (tabla/seq/trigger)
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER TO PRY2205_ROL_P;

-- 5) Asignar roles
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

-- 6) Verificacion rapida
SELECT username, default_tablespace, temporary_tablespace
FROM dba_users
WHERE username IN ('PRY2205_USER1','PRY2205_USER2')
ORDER BY username;

SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN ('PRY2205_USER1','PRY2205_USER2')
ORDER BY grantee;



-- CASO 1 (PRY2205_USER1) - Poblamiento y public synonyms + grants a USER2
-- 
--PRY2205_USER1



SELECT USER AS USUARIO, SYS_CONTEXT('USERENV','CON_NAME') AS CONTAINER FROM DUAL;





SELECT table_name
FROM user_tables
WHERE table_name IN ('LIBRO','EJEMPLAR','PRESTAMO','ALUMNO','EMPLEADO','CARRERA','REBAJA_MULTA')
ORDER BY table_name;

-- 3) Grants a USER2 

GRANT SELECT ON LIBRO     TO PRY2205_USER2;
GRANT SELECT ON EJEMPLAR  TO PRY2205_USER2;
GRANT SELECT ON PRESTAMO  TO PRY2205_USER2;
GRANT SELECT ON ALUMNO    TO PRY2205_USER2;
GRANT SELECT ON EMPLEADO  TO PRY2205_USER2;

-- Para el caso 3 (vista)
GRANT SELECT ON CARRERA       TO PRY2205_USER2;
GRANT SELECT ON REBAJA_MULTA  TO PRY2205_USER2;

-- 4) Sinonimos PUBLICOS (apuntan a tablas PRY2205_USER1)

CREATE OR REPLACE PUBLIC SYNONYM BIB_LIBRO     FOR PRY2205_USER1.LIBRO;
CREATE OR REPLACE PUBLIC SYNONYM BIB_EJEMPLAR  FOR PRY2205_USER1.EJEMPLAR;
CREATE OR REPLACE PUBLIC SYNONYM BIB_PRESTAMO  FOR PRY2205_USER1.PRESTAMO;
CREATE OR REPLACE PUBLIC SYNONYM BIB_ALUMNO    FOR PRY2205_USER1.ALUMNO;
CREATE OR REPLACE PUBLIC SYNONYM BIB_EMPLEADO  FOR PRY2205_USER1.EMPLEADO;

-- (para el caso 3)
CREATE OR REPLACE PUBLIC SYNONYM BIB_CARRERA       FOR PRY2205_USER1.CARRERA;
CREATE OR REPLACE PUBLIC SYNONYM BIB_REBAJA_MULTA  FOR PRY2205_USER1.REBAJA_MULTA;

-- 5) Sinonimos PRIVADOS 
CREATE OR REPLACE SYNONYM BIB_LIBRO        FOR LIBRO;
CREATE OR REPLACE SYNONYM BIB_EJEMPLAR     FOR EJEMPLAR;
CREATE OR REPLACE SYNONYM BIB_PRESTAMO     FOR PRESTAMO;
CREATE OR REPLACE SYNONYM BIB_ALUMNO       FOR ALUMNO;
CREATE OR REPLACE SYNONYM BIB_EMPLEADO     FOR EMPLEADO;
CREATE OR REPLACE SYNONYM BIB_CARRERA      FOR CARRERA;
CREATE OR REPLACE SYNONYM BIB_REBAJA_MULTA FOR REBAJA_MULTA;

-- 6) consulta sinonimos (publicos y privados)
SELECT owner, synonym_name, table_owner, table_name
FROM all_synonyms
WHERE synonym_name IN ('BIB_LIBRO','BIB_EJEMPLAR','BIB_PRESTAMO','BIB_ALUMNO','BIB_EMPLEADO','BIB_CARRERA','BIB_REBAJA_MULTA')
ORDER BY owner, synonym_name;


-- PRY2205_USER2

-- ===== CASO 2 - PRY2205_USER2 - CONTROL_STOCK_LIBROS =====

SELECT USER AS USUARIO, SYS_CONTEXT('USERENV','CON_NAME') AS CONTAINER FROM DUAL;

-- 1) Antes de seguir, confirmo que USER2 ve los sinonimos publicos (si falla, no sigo)
SELECT COUNT(*) AS CNT_LIBRO     FROM BIB_LIBRO;
SELECT COUNT(*) AS CNT_EJEMPLAR  FROM BIB_EJEMPLAR;
SELECT COUNT(*) AS CNT_PRESTAMO  FROM BIB_PRESTAMO;

-- 2) Limpieza 
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TRG_CONTROL_STOCK_LIBROS_BI'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CONTROL_STOCK_LIBROS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_CONTROL_STOCK'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 3) Secuencia + tabla + trigger (el trigger le pone ID si vienee NULL)
CREATE SEQUENCE SEQ_CONTROL_STOCK
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE TABLE CONTROL_STOCK_LIBROS (
  ID_CONTROL            NUMBER        PRIMARY KEY,
  LIBRO_ID              NUMBER        NOT NULL,
  NOMBRE_LIBRO          VARCHAR2(200)  NOT NULL,
  TOTAL_EJEMPLARES      NUMBER        NOT NULL,
  EN_PRESTAMO           NUMBER        NOT NULL,
  DISPONIBLES           NUMBER        NOT NULL,
  PORCENTAJE_PRESTAMO   VARCHAR2(20)   NOT NULL,
  STOCK_CRITICO         CHAR(1)        NOT NULL
);

CREATE OR REPLACE TRIGGER TRG_CONTROL_STOCK_LIBROS_BI
BEFORE INSERT ON CONTROL_STOCK_LIBROS
FOR EACH ROW
BEGIN
  IF :NEW.ID_CONTROL IS NULL THEN
    :NEW.ID_CONTROL := SEQ_CONTROL_STOCK.NEXTVAL;
  END IF;
END;
/

-- 4) Poblar CONTROL_STOCK_LIBROS (todo queda dentro de USER2)
INSERT INTO CONTROL_STOCK_LIBROS (
  ID_CONTROL, LIBRO_ID, NOMBRE_LIBRO,
  TOTAL_EJEMPLARES, EN_PRESTAMO, DISPONIBLES,
  PORCENTAJE_PRESTAMO, STOCK_CRITICO
)
SELECT
  NULL                                                   AS ID_CONTROL,
  t.libro_id                                              AS LIBRO_ID,
  INITCAP(t.nombre_libro)                                 AS NOMBRE_LIBRO,
  t.total_ejemplares                                      AS TOTAL_EJEMPLARES,
  t.en_prestamo                                           AS EN_PRESTAMO,
  (t.total_ejemplares - t.en_prestamo)                    AS DISPONIBLES,

  -- porcentaje: "50" o "33,33"
  CASE
    WHEN t.total_ejemplares = 0 THEN '0'
    WHEN MOD(ROUND((t.en_prestamo / t.total_ejemplares) * 100, 2), 1) = 0 THEN
      TO_CHAR(
        ROUND((t.en_prestamo / t.total_ejemplares) * 100, 0),
        'FM9990',
        'NLS_NUMERIC_CHARACTERS='',.'''
      )
    ELSE
      TO_CHAR(
        ROUND((t.en_prestamo / t.total_ejemplares) * 100, 2),
        'FM9990D00',
        'NLS_NUMERIC_CHARACTERS='',.'''
      )
  END                                                    AS PORCENTAJE_PRESTAMO,

  --  Stock  critico: mas de 2 disponibles => S, si no => N
  CASE
    WHEN (t.total_ejemplares - t.en_prestamo) > 2 THEN 'S'
    ELSE 'N'
  END                                                    AS STOCK_CRITICO
FROM (
  SELECT
    l.libroid                           AS libro_id,
    TRIM(l.nombre_libro)                AS nombre_libro,
    COUNT(e.ejemplarid)                 AS total_ejemplares,

    -- subconsulta + fecha (hace 24 meses) + nulos
    NVL((
      SELECT COUNT(DISTINCT p.ejemplarid)
      FROM BIB_PRESTAMO p
      WHERE p.libroid = l.libroid
        AND p.empleadoid IN (190, 180, 150)
        AND TRUNC(p.fecha_inicio,'MM') = TRUNC(ADD_MONTHS(SYSDATE,-24),'MM')
    ), 0)                               AS en_prestamo

  FROM BIB_LIBRO l
  LEFT JOIN BIB_EJEMPLAR e
         ON e.libroid = l.libroid
  GROUP BY
    l.libroid,
    TRIM(l.nombre_libro)
) t
WHERE t.en_prestamo > 0;

COMMIT;

-- 5) Consulta caso 2
SELECT
  ID_CONTROL, LIBRO_ID, NOMBRE_LIBRO,
  TOTAL_EJEMPLARES, EN_PRESTAMO, DISPONIBLES,
  PORCENTAJE_PRESTAMO, STOCK_CRITICO
FROM CONTROL_STOCK_LIBROS
ORDER BY LIBRO_ID;



-- =======================
-- PRY2205_USER1

-- ===== CASO 3 - PRY2205_USER1 -  VW_DETALLE_MULTAS +  indices =====

SELECT USER AS USUARIO, SYS_CONTEXT('USERENV','CON_NAME') AS CONTAINER FROM DUAL;

--  Vista 
CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT
  p.prestamoid                                                     AS ID_PRESTAMO,

 
  INITCAP(TRIM(a.nombre || ' ' || a.apaterno || ' ' || a.amaterno)) AS NOMBRE_ALUMNO,

  INITCAP(TRIM(c.descripcion))                                      AS NOMBRE_CARRERA,
  l.libroid                                                        AS ID_LIBRO,

  '$' || TO_CHAR(NVL(l.precio,0),
                 'FM999G999G999',
                 'NLS_NUMERIC_CHARACTERS='',.'''
                )                                                   AS VALOR_LIBRO,

  TO_CHAR(p.fecha_termino, 'DD/MM/YYYY')                            AS FECHA_TERMINO,
  TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY')                            AS FECHA_ENTREGA,

  (TRUNC(p.fecha_entrega) - TRUNC(p.fecha_termino))                 AS DIAS_ATRASO,

  '$' || TO_CHAR(
          ROUND(NVL(l.precio,0) * 0.03 * (TRUNC(p.fecha_entrega) - TRUNC(p.fecha_termino)), 0),
          'FM999G999G999',
          'NLS_NUMERIC_CHARACTERS='',.'''
        )                                                           AS VALOR_MULTA,

  CASE
    WHEN NVL(rm.porc_rebaja_multa, 0) = 0 THEN '0'
    ELSE TO_CHAR(NVL(rm.porc_rebaja_multa, 0) / 100,
                 'FM0D00',
                 'NLS_NUMERIC_CHARACTERS='',.'''
         )
  END                                                               AS PORCENTAJE_REBAJA_MULTA,

  '$' || TO_CHAR(
          ROUND(
            ROUND(NVL(l.precio,0) * 0.03 * (TRUNC(p.fecha_entrega) - TRUNC(p.fecha_termino)), 0)
            * (1 - (NVL(rm.porc_rebaja_multa, 0) / 100)),
            0
          ),
          'FM999G999G999',
          'NLS_NUMERIC_CHARACTERS='',.'''
        )                                                           AS VALOR_REBAJADO
FROM (
 
  SELECT *
  FROM PRESTAMO
  WHERE fecha_entrega IS NOT NULL
    AND fecha_entrega > fecha_termino
    
    AND fecha_termino >= TRUNC(ADD_MONTHS(SYSDATE, -24), 'YYYY')
    AND fecha_termino <  ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE, -24), 'YYYY'), 12)
) p
JOIN ALUMNO        a  ON a.alumnoid  = p.alumnoid
JOIN CARRERA       c  ON c.carreraid = a.carreraid
JOIN EJEMPLAR      e  ON e.ejemplarid = p.ejemplarid
                      AND e.libroid   = p.libroid
JOIN LIBRO         l  ON l.libroid    = e.libroid
LEFT JOIN REBAJA_MULTA rm ON rm.carreraid = a.carreraid;


BEGIN EXECUTE IMMEDIATE 'DROP INDEX IDX_PRESTAMO_FTERM_MM'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX IDX_PRESTAMO_JOIN'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX IDX_ALUMNO_CARRERA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Indice por mes 
CREATE INDEX IDX_PRESTAMO_FTERM_MM ON PRESTAMO (TRUNC(fecha_termino,'MM'));

-- Indices para los joins
CREATE INDEX IDX_PRESTAMO_JOIN   ON PRESTAMO (libroid, ejemplarid, alumnoid);
CREATE INDEX IDX_ALUMNO_CARRERA  ON ALUMNO   (carreraid);

-- 3) Consulta  del caso 3)
SELECT
  ID_PRESTAMO,
  NOMBRE_ALUMNO,
  NOMBRE_CARRERA,
  ID_LIBRO,
  VALOR_LIBRO,
  FECHA_TERMINO,
  FECHA_ENTREGA,
  DIAS_ATRASO,
  VALOR_MULTA,
  PORCENTAJE_REBAJA_MULTA,
  VALOR_REBAJADO
FROM VW_DETALLE_MULTAS
ORDER BY TO_DATE(FECHA_ENTREGA,'DD/MM/YYYY') DESC;

-- 4) indices creadoss
SELECT index_name, table_name
FROM user_indexes
WHERE index_name IN ('IDX_PRESTAMO_FTERM_MM','IDX_PRESTAMO_JOIN','IDX_ALUMNO_CARRERA')
ORDER BY index_name;