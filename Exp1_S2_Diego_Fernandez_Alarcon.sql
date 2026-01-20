
SET SERVEROUTPUT ON;
SET VERIFY OFF;

-----------------------------------------------------------
-- 1) BIND
------------------------------------------------------------
VAR b_fecha_proc VARCHAR2(7);
EXEC :b_fecha_proc := TO_CHAR(SYSDATE, 'MM/YYYY');
PRINT b_fecha_proc;

------------------------------------------------------------
-- 2) BLOQUE PL/SQL (trunca, procesa uno a uno, inserta, commit/rollback)
------------------------------------------------------------
DECLARE
  ----------------------------------------------------------
  -- Variables %TYPE 
  ----------------------------------------------------------
  v_id_emp            empleado.id_emp%TYPE;
  v_numrun_emp        empleado.numrun_emp%TYPE;
  v_dvrun_emp         empleado.dvrun_emp%TYPE;

  v_pnombre_emp       empleado.pnombre_emp%TYPE;
  v_snombre_emp       empleado.snombre_emp%TYPE;
  v_appaterno_emp     empleado.appaterno_emp%TYPE;
  v_apmaterno_emp     empleado.apmaterno_emp%TYPE;

  v_fecha_nac         empleado.fecha_nac%TYPE;
  v_fecha_contrato    empleado.fecha_contrato%TYPE;
  v_sueldo_base       empleado.sueldo_base%TYPE;

  v_id_estado_civil   empleado.id_estado_civil%TYPE;
  v_nombre_estado     estado_civil.nombre_estado_civil%TYPE;

  
  -- Variables del resultado
  ----------------------------------------------------------
  v_nombre_empleado   usuario_clave.nombre_empleado%TYPE;
  v_nombre_usuario    usuario_clave.nombre_usuario%TYPE;
  v_clave_usuario     usuario_clave.clave_usuario%TYPE;

  ----------------------------------------------------------
  -- Control de proceso
  ----------------------------------------------------------
  v_total_esperado    NUMBER := 0;
  v_insertados        NUMBER := 0;

  ----------------------------------------------------------
  -- Variables de calculo (PL/SQL)
  ----------------------------------------------------------
  v_fecha_proc        DATE;
  v_mmYYYY_num        VARCHAR2(6);

  v_anios_trabajo     NUMBER;

  v_ec_letra          VARCHAR2(1);
  v_pnombre_3         VARCHAR2(3);
  v_largo_pnombre     NUMBER;
  v_ult_dig_sueldo    VARCHAR2(1);

  v_run_8             VARCHAR2(8);
  v_tercer_dig_run    VARCHAR2(1);
  v_anio_nac_mas2     VARCHAR2(4);

  v_ult3_sueldo_m1    VARCHAR2(3);
  v_apellido_lower    VARCHAR2(60);
  v_letras_apellido   VARCHAR2(2);

BEGIN
  ----------------------------------------------------------
  -- PL/SQL : fecha de proceso desde el bind
  -- ultimo dia del mes para que sea reproducible
  ----------------------------------------------------------
  v_fecha_proc := LAST_DAY(TO_DATE('01/' || :b_fecha_proc, 'DD/MM/YYYY'));
  v_mmYYYY_num := REPLACE(:b_fecha_proc, '/', ''); 

  ----------------------------------------------------------
  -- SQL : TRUNCATE con SQL dinamico 
  ----------------------------------------------------------
  EXECUTE IMMEDIATE 'TRUNCATE TABLE usuario_clave';
  DBMS_OUTPUT.PUT_LINE('Table USUARIO_CLAVE truncado.');

  ----------------------------------------------------------
  -- SQL : total esperado 
  ----------------------------------------------------------
  SELECT COUNT(*)
    INTO v_total_esperado
    FROM empleado
   WHERE id_emp BETWEEN 100 AND 320;

  ----------------------------------------------------------
  -- PL/SQL : ciclo uno a uno (eficiente) con JOIN
  ----------------------------------------------------------
  FOR r IN (
    SELECT
      e.id_emp,
      e.numrun_emp,
      e.dvrun_emp,
      e.pnombre_emp,
      e.snombre_emp,
      e.appaterno_emp,
      e.apmaterno_emp,
      e.fecha_nac,
      e.fecha_contrato,
      e.sueldo_base,
      e.id_estado_civil,
      ec.nombre_estado_civil
    FROM empleado e
    JOIN estado_civil ec
      ON ec.id_estado_civil = e.id_estado_civil
    WHERE e.id_emp BETWEEN 100 AND 320
    ORDER BY e.id_emp
  ) LOOP

    -- Cargar variables del registro 
    v_id_emp          := r.id_emp;
    v_numrun_emp      := r.numrun_emp;
    v_dvrun_emp       := r.dvrun_emp;

    v_pnombre_emp     := r.pnombre_emp;
    v_snombre_emp     := r.snombre_emp;
    v_appaterno_emp   := r.appaterno_emp;
    v_apmaterno_emp   := r.apmaterno_emp;

    v_fecha_nac       := r.fecha_nac;
    v_fecha_contrato  := r.fecha_contrato;
    v_sueldo_base     := r.sueldo_base;

    v_id_estado_civil := r.id_estado_civil;
    v_nombre_estado   := r.nombre_estado_civil;

    --------------------------------------------------------
    -- Calculos en PL/SQL (reglas de negocio)
    --------------------------------------------------------
    v_anios_trabajo := TRUNC(MONTHS_BETWEEN(v_fecha_proc, v_fecha_contrato) / 12);

    -- Nombre completo 
    v_nombre_empleado :=
      INITCAP(
        TRIM(
          REGEXP_REPLACE(
            TRIM(v_pnombre_emp) || ' ' ||
            CASE WHEN TRIM(v_snombre_emp) IS NOT NULL THEN TRIM(v_snombre_emp) || ' ' ELSE '' END ||
            TRIM(v_appaterno_emp) || ' ' ||
            TRIM(v_apmaterno_emp),
            ' +',
            ' '
          )
        )
      );

    -- Partes para NOMBRE_USUARIO
    v_ec_letra      := SUBSTR(LOWER(TRIM(v_nombre_estado)), 1, 1);           -- s/c/d/v...
    v_pnombre_3     := SUBSTR(UPPER(TRIM(v_pnombre_emp)), 1, 3);             -- 3 letras (en mayus)
    v_largo_pnombre := LENGTH(TRIM(v_pnombre_emp));
    v_ult_dig_sueldo := TO_CHAR(MOD(TRUNC(v_sueldo_base), 10));              -- ultimo digito

    -- NOMBRE_USUARIO (formato tipo figura)
    v_nombre_usuario :=
      v_ec_letra ||
      v_pnombre_3 ||
      TO_CHAR(v_largo_pnombre) ||
      '*' ||
      v_ult_dig_sueldo ||
      UPPER(TRIM(v_dvrun_emp)) ||
      TO_CHAR(v_anios_trabajo) ||
      CASE WHEN v_anios_trabajo < 10 THEN 'X' ELSE '' END;

    -- Partes para CLAVE_USUARIO
    v_run_8 := LPAD(TO_CHAR(v_numrun_emp), 8, '0');
    v_tercer_dig_run := SUBSTR(v_run_8, 3, 1);

    v_anio_nac_mas2 := TO_CHAR(TO_NUMBER(TO_CHAR(v_fecha_nac, 'YYYY')) + 2);

    -- ultimos 3 de (sueldo_base - 1)
    v_ult3_sueldo_m1 := LPAD(TO_CHAR(MOD(TRUNC(v_sueldo_base) - 1, 1000)), 3, '0');

    -- letras de apellido segun estado civil
    v_apellido_lower := LOWER(TRIM(v_appaterno_emp));

    -- 10 CASADo, 60 ACUERDO UNION CIVIL > 2 primera
    -- 20 DIVORCIADO, 30 SOLTERO        => primera y ultima
    -- 40 VIUDO                         => antepenultima y penultima
    -- 50 SEPARADO                       => 2 ultimas
    v_letras_apellido :=
      CASE
        WHEN v_id_estado_civil IN (10, 60) THEN
          SUBSTR(v_apellido_lower, 1, 2)
        WHEN v_id_estado_civil IN (20, 30) THEN
          SUBSTR(v_apellido_lower, 1, 1) || SUBSTR(v_apellido_lower, -1, 1)
        WHEN v_id_estado_civil = 40 THEN
          SUBSTR(v_apellido_lower, -3, 1) || SUBSTR(v_apellido_lower, -2, 1)
        WHEN v_id_estado_civil = 50 THEN
          SUBSTR(v_apellido_lower, -2, 2)
        ELSE
          SUBSTR(v_apellido_lower, 1, 2)
      END;

      -- CLAVE_USUARIO
    v_clave_usuario :=
      v_tercer_dig_run ||
      v_anio_nac_mas2 ||
      v_ult3_sueldo_m1 ||
      v_letras_apellido ||
      TO_CHAR(v_id_emp) ||
      v_mmYYYY_num;

    --------------------------------------------------------
    --  INSERT del resultado
    --------------------------------------------------------
    INSERT INTO usuario_clave (
      id_emp,
      numrun_emp,
      dvrun_emp,
      nombre_empleado,
      nombre_usuario,
      clave_usuario
    ) VALUES (
      v_id_emp,
      v_numrun_emp,
      v_dvrun_emp,
      v_nombre_empleado,
      v_nombre_usuario,
      v_clave_usuario
    );

    v_insertados := v_insertados + 1;
  END LOOP;

  ----------------------------------------------------------
  -- Commit solo si el proceso termino completo
  ----------------------------------------------------------
  IF v_insertados = v_total_esperado THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso OK. Iteraciones: ' || v_insertados || ' de ' || v_total_esperado);
  ELSE
    ROLLBACK;
    RAISE_APPLICATION_ERROR(
      -20001,
      'Proceso incompleto. Iteraciones: ' || v_insertados || ' de ' || v_total_esperado
    );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    RAISE;
END;
/

-----------------------------------------------------------
--  Evidencias 
------------------------------------------------------------

PRINT b_fecha_proc;

SELECT COUNT(*) AS total_generados
FROM usuario_clave;


SELECT
  id_emp,
  numrun_emp,
  dvrun_emp,
  nombre_empleado,
  nombre_usuario,
  clave_usuario
FROM usuario_clave
ORDER BY id_emp;

-- Evidencia ejemplo de  3 usuarios
SELECT
  id_emp,
  nombre_usuario,
  clave_usuario
FROM usuario_clave
WHERE id_emp IN (100, 210, 320)
ORDER BY id_emp;