ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
SET SERVEROUTPUT ON;

VARIABLE b_anno NUMBER;

BEGIN
  :b_anno := EXTRACT(YEAR FROM SYSDATE) - 1;
END;
/


-- PARAMETRO

BEGIN
  DBMS_OUTPUT.PUT_LINE('Anio a procesar (:b_anno) = ' || :b_anno);
END;
/


-- RECREAR TABLA MEDICO_SERVICIO_COMUNIDAD

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE MEDICO_SERVICIO_COMUNIDAD PURGE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/

CREATE TABLE MEDICO_SERVICIO_COMUNIDAD
(
  id_med_scomun NUMBER(2) GENERATED ALWAYS AS IDENTITY MINVALUE 1
    MAXVALUE 9999999999999999999999999999
    INCREMENT BY 1 START WITH 1
    CONSTRAINT PK_MED_SERV_COMUNIDAD PRIMARY KEY,
  unidad               VARCHAR2(50) NOT NULL,
  run_medico           VARCHAR2(15) NOT NULL,
  nombre_medico        VARCHAR2(60) NOT NULL,
  correo_institucional VARCHAR2(40) NOT NULL,
  total_aten_medicas   NUMBER(3)    NOT NULL,
  destinacion          VARCHAR2(80) NOT NULL
);


-- CASO 1:  PAGO MOROSO

DECLARE
  TYPE t_varray_multas IS VARRAY(7) OF NUMBER;
  v_multas t_varray_multas := t_varray_multas(1200,1300,1700,1900,1100,2000,2300);

  v_anno      NUMBER(4) := :b_anno;
  v_fecha_ref DATE      := TO_DATE('31/12/' || :b_anno, 'DD/MM/YYYY');

  CURSOR c_morosos IS
    SELECT
      p.pac_run,
      p.dv_run pac_dv_run,
      p.pnombre || ' ' || p.snombre || ' ' || p.apaterno || ' ' || p.amaterno pac_nombre,
      p.apaterno,
      a.ate_id,
      pa.fecha_venc_pago,
      pa.fecha_pago,
      TRUNC(pa.fecha_pago) - TRUNC(pa.fecha_venc_pago) dias_morosidad,
      e.esp_id,
      e.nombre especialidad_atencion,
      TRUNC(MONTHS_BETWEEN(v_fecha_ref, p.fecha_nacimiento) / 12) edad
    FROM pago_atencion pa
    JOIN atencion a     ON a.ate_id = pa.ate_id
    JOIN paciente p     ON p.pac_run = a.pac_run
    JOIN especialidad e ON e.esp_id = a.esp_id
    WHERE pa.fecha_pago IS NOT NULL
      AND TRUNC(pa.fecha_pago) > TRUNC(pa.fecha_venc_pago)
      AND EXTRACT(YEAR FROM pa.fecha_pago) = v_anno
    ORDER BY pa.fecha_venc_pago, p.apaterno;

  v_reg c_morosos%ROWTYPE;

  v_multa_dia   NUMBER;
  v_pct_descto  PORC_DESCTO_3RA_EDAD.porcentaje_descto%TYPE;
  v_monto_multa NUMBER;
  v_ins         NUMBER := 0;

BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE PAGO_MOROSO';

  OPEN c_morosos;
  LOOP
    FETCH c_morosos INTO v_reg;
    EXIT WHEN c_morosos%NOTFOUND;

    IF v_reg.esp_id IN (100, 300) THEN
      v_multa_dia := v_multas(1); -- Cirugia General / Dermatologia
    ELSIF v_reg.esp_id = 200 THEN
      v_multa_dia := v_multas(2); -- Ortopedia y Traumatologia
    ELSIF v_reg.esp_id IN (400, 900) THEN
      v_multa_dia := v_multas(3); -- Inmunologia  /  Otorrinolaringologia
    ELSIF v_reg.esp_id IN (500, 600) THEN
      v_multa_dia := v_multas(4); -- Fisiatria / Medicina Interna
    ELSIF v_reg.esp_id = 700 THEN
      v_multa_dia := v_multas(5); -- Medicina  General
    ELSIF v_reg.esp_id = 1100 THEN
      v_multa_dia := v_multas(6); -- Psiquiatria Adultos
    ELSIF v_reg.esp_id IN (1400, 1800) THEN
      v_multa_dia := v_multas(7); -- Cirugia Digestiva /  Reumatologia
    ELSE
      v_multa_dia := 0;
    END IF;

    v_pct_descto := 0;

    BEGIN
      SELECT porcentaje_descto
      INTO v_pct_descto
      FROM porc_descto_3ra_edad
      WHERE v_reg.edad BETWEEN anno_ini AND anno_ter;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_pct_descto := 0;
    END;

    v_monto_multa := ROUND(v_reg.dias_morosidad * v_multa_dia * (1 - (v_pct_descto / 100)));

    INSERT INTO pago_moroso
    (
      pac_run,
      pac_dv_run,
      pac_nombre,
      ate_id,
      fecha_venc_pago,
      fecha_pago,
      dias_morosidad,
      especialidad_atencion,
      monto_multa
    )
    VALUES
    (
      v_reg.pac_run,
      v_reg.pac_dv_run,
      v_reg.pac_nombre,
      v_reg.ate_id,
      v_reg.fecha_venc_pago,
      v_reg.fecha_pago,
      v_reg.dias_morosidad,
      v_reg.especialidad_atencion,
      v_monto_multa
    );

    v_ins := v_ins + 1;
  END LOOP;
  CLOSE c_morosos;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('----------------------------------------');
  DBMS_OUTPUT.PUT_LINE('CASO 1 EJECUTADO');
  DBMS_OUTPUT.PUT_LINE('Filas insertadas en PAGO_MOROSO: ' || v_ins);
  DBMS_OUTPUT.PUT_LINE('----------------------------------------');

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR CASO 1: ' || SQLERRM);
    RAISE;
END;
/


--- CASO 2:  MEDICO_SERVICIO_COMUNIDAD

DECLARE
  TYPE t_varray_dest IS VARRAY(4) OF VARCHAR2(80);
  v_dest t_varray_dest := t_varray_dest(
    'Servicio de Atencion Primaria de Urgencia (SAPU)',
    'Hospitales del area de la Salud Publica',
    'Centros de Salud Familiar (CESFAM)',
    'Consultorios Generales'
  );

  v_anno NUMBER(4) := :b_anno;
  v_max_atenciones NUMBER := 0;
  v_ins NUMBER := 0;
  v_destino VARCHAR2(80);

  v_run_medico VARCHAR2(15);
  v_nombre_medico VARCHAR2(60);
  v_correo VARCHAR2(40);

  v_txt_run VARCHAR2(20);
  v_u2 VARCHAR2(2);
  v_ap2 VARCHAR2(2);
  v_tel3 VARCHAR2(3);
  v_fec4 VARCHAR2(4);

  CURSOR c_medicos IS
    WITH tot AS
    (
      SELECT med_run, COUNT(*) cnt
      FROM atencion
      WHERE EXTRACT(YEAR FROM fecha_atencion) = v_anno
      GROUP BY med_run
    )
    SELECT
      u.uni_id,
      u.nombre unidad,
      m.med_run,
      m.dv_run,
      m.pnombre,
      m.snombre,
      m.apaterno,
      m.amaterno,
      m.telefono,
      m.fecha_contrato,
      NVL(t.cnt,0) total_aten
    FROM medico m
    JOIN unidad u
      ON u.uni_id = m.uni_id
    LEFT JOIN tot t
      ON t.med_run = m.med_run
    WHERE NVL(t.cnt,0) < v_max_atenciones
    ORDER BY u.nombre, m.apaterno;

  v_reg c_medicos%ROWTYPE;

BEGIN
  BEGIN
    SELECT MAX(cnt)
    INTO v_max_atenciones
    FROM
    (
      SELECT med_run, COUNT(*) cnt
      FROM atencion
      WHERE EXTRACT(YEAR FROM fecha_atencion) = v_anno
      GROUP BY med_run
    );
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_max_atenciones := 0;
  END;

  v_max_atenciones := NVL(v_max_atenciones, 0);

  OPEN c_medicos;
  LOOP
    FETCH c_medicos INTO v_reg;
    EXIT WHEN c_medicos%NOTFOUND;

    -- Destinacion segun unidad
    IF v_reg.uni_id IN (400, 100) THEN
      v_destino := v_dest(1);
    ELSIF v_reg.uni_id = 200 THEN
      IF v_reg.total_aten BETWEEN 0 AND 3 THEN
        v_destino := v_dest(1);
      ELSE
        v_destino := v_dest(2);
      END IF;
    ELSIF v_reg.uni_id IN (900, 500) THEN
      v_destino := v_dest(2);
    ELSIF v_reg.uni_id IN (700, 800) THEN
      IF v_reg.total_aten BETWEEN 0 AND 3 THEN
        v_destino := v_dest(1);
      ELSE
        v_destino := v_dest(2);
      END IF;
    ELSIF v_reg.uni_id = 300 THEN
      v_destino := v_dest(2);
    ELSIF v_reg.uni_id = 600 THEN
      v_destino := v_dest(3);
    ELSIF v_reg.uni_id = 1000 THEN
      IF v_reg.total_aten BETWEEN 0 AND 3 THEN
        v_destino := v_dest(1);
      ELSE
        v_destino := v_dest(2);
      END IF;
    ELSE
      v_destino := v_dest(4);
    END IF;

    -- Formato RUN medico en variable PL/SQL
    v_txt_run := TO_CHAR(v_reg.med_run);

    IF LENGTH(v_txt_run) = 7 THEN
      v_run_medico :=
          SUBSTR(v_txt_run,1,1) || '.'
       || SUBSTR(v_txt_run,2,3) || '.'
       || SUBSTR(v_txt_run,5,3) || '-'
       || v_reg.dv_run;
    ELSE
      v_run_medico :=
          SUBSTR(v_txt_run,1,2) || '.'
       || SUBSTR(v_txt_run,3,3) || '.'
       || SUBSTR(v_txt_run,6,3) || '-'
       || v_reg.dv_run;
    END IF;

    --- Nombre  medico
    v_nombre_medico := INITCAP(
         v_reg.pnombre || ' '
      || v_reg.snombre || ' '
      || v_reg.apaterno || ' '
      || v_reg.amaterno
    );

    -- Correo  en  variable PL/SQL
    v_u2 := UPPER(SUBSTR(REPLACE(TRIM(v_reg.unidad), ' ', ''), 1, 2));
    v_ap2 := LOWER(SUBSTR(TRIM(v_reg.apaterno), LENGTH(TRIM(v_reg.apaterno)) - 2, 2));
    v_tel3 := SUBSTR(TO_CHAR(v_reg.telefono), -3);
    v_fec4 := TO_CHAR(v_reg.fecha_contrato, 'DDMM');

    v_correo := v_u2 || v_ap2 || v_tel3 || v_fec4 || '@medicocktk.cl';

    INSERT INTO medico_servicio_comunidad
    (
      unidad,
      run_medico,
      nombre_medico,
      correo_institucional,
      total_aten_medicas,
      destinacion
    )
    VALUES
    (
      v_reg.unidad,
      v_run_medico,
      v_nombre_medico,
      v_correo,
      v_reg.total_aten,
      v_destino
    );

    v_ins := v_ins + 1;
  END LOOP;
  CLOSE c_medicos;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('----------------------------------------');
  DBMS_OUTPUT.PUT_LINE('CASO 2 EJECUTADO');
  DBMS_OUTPUT.PUT_LINE('Maximo anual de atenciones: ' || v_max_atenciones);
  DBMS_OUTPUT.PUT_LINE('Filas insertadas en MEDICO_SERVICIO_COMUNIDAD: ' || v_ins);
  DBMS_OUTPUT.PUT_LINE('----------------------------------------');

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR CASO 2: ' || SQLERRM);
    RAISE;
END;
/

//  FIGURA 1: PAGO MOROSO 
SELECT
  pac_run,
  pac_dv_run,
  pac_nombre,
  ate_id,
  fecha_venc_pago,
  fecha_pago,
  dias_morosidad,
  especialidad_atencion,
  monto_multa
FROM pago_moroso
ORDER BY fecha_venc_pago, pac_nombre;

// ====== FIGURA 2: MEDICO SERVICIO   COMUNIDAD 
SELECT
  unidad,
  run_medico,
  nombre_medico,
  correo_institucional,
  total_aten_medicas,
  destinacion
FROM medico_servicio_comunidad
ORDER BY unidad, nombre_medico;