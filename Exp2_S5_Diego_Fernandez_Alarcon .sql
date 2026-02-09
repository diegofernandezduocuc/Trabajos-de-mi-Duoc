SET SERVEROUTPUT ON;


-- PARAMETRO DE ENTRADA (BIND)

VAR p_anno NUMBER;

-- Opcion A: año actual.
EXEC :p_anno := EXTRACT(YEAR FROM SYSDATE);


-- Opcion B: año fijo solo para pruebas (para comparar  evidencia ) 
-- EXEC :p_anno := 2026;
-- ________

-- año que quedo cargado en el bind (para verificar)
PRINT p_anno;


DECLARE
  v_anno NUMBER := :p_anno;

  v_fec_ini_anio DATE;
  v_fec_fin_anio DATE;

  v_mes     NUMBER;
  v_fec_ini DATE;
  v_fec_fin DATE;

  -- Tipos requeridos 
  TYPE t_varray_tipos IS VARRAY(2) OF NUMBER;
  v_tipos t_varray_tipos := t_varray_tipos(102, 103);

  v_esperadas  NUMBER := 0;
  v_insertadas NUMBER := 0;

  v_porc   NUMBER := 0;
  v_aporte NUMBER := 0;

  -- Excepciones (predefinida, no predefinida, y definida)
  e_tabla_no_existe EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_tabla_no_existe, -942);

  e_control_commit EXCEPTION;
  e_anno_invalido  EXCEPTION;

  
  TYPE r_det_t IS RECORD (
    numrun            cliente.numrun%TYPE,
    dvrun             cliente.dvrun%TYPE,
    nro_tarjeta       tarjeta_cliente.nro_tarjeta%TYPE,
    nro_transaccion   transaccion_tarjeta_cliente.nro_transaccion%TYPE,
    fecha_transaccion transaccion_tarjeta_cliente.fecha_transaccion%TYPE,
    tipo_transaccion  tipo_transaccion_tarjeta.nombre_tptran_tarjeta%TYPE,
    monto_total       transaccion_tarjeta_cliente.monto_total_transaccion%TYPE
  );
  r_det r_det_t;

  -- _______________________________________________________
  -- CURSOR EXPLICITO CON PARAMETROS (detalle)
  -- _____________________________________________________
  
  CURSOR c_det(p_cod_tp NUMBER, p_ini DATE, p_fin DATE) IS
    SELECT
      c.numrun,
      c.dvrun,
      tc.nro_tarjeta,
      ttc.nro_transaccion,
      ttc.fecha_transaccion,
      ttt.nombre_tptran_tarjeta AS tipo_transaccion,
      ttc.monto_total_transaccion AS monto_total
    FROM transaccion_tarjeta_cliente ttc
    JOIN tarjeta_cliente tc
      ON tc.nro_tarjeta = ttc.nro_tarjeta
    JOIN cliente c
      ON c.numrun = tc.numrun
    JOIN tipo_transaccion_tarjeta ttt
      ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
    WHERE ttc.cod_tptran_tarjeta = p_cod_tp
      AND ttc.fecha_transaccion >= p_ini
      AND ttc.fecha_transaccion <  p_fin
    ORDER BY ttc.fecha_transaccion ASC, c.numrun ASC;

 
  -- CURSOR EXPLICITO SIN PARAMETROS (meses presentes en DETALLE)
  

  CURSOR c_meses IS
    SELECT DISTINCT TO_CHAR(fecha_transaccion,'MMYYYY') AS mes_anno
    FROM detalle_aporte_sbif
    ORDER BY TO_CHAR(fecha_transaccion,'MMYYYY');


  --- CURSOR EXPLICITO CON PARAMETROS (resumen por mes y tipo)
 
  CURSOR c_res(p_mes_anno VARCHAR2, p_tipo VARCHAR2) IS
    SELECT
      p_mes_anno AS mes_anno,
      p_tipo     AS tipo_transaccion,
      SUM(monto_transaccion) AS monto_total_transacciones,
      SUM(aporte_sbif)       AS aporte_total_abif
    FROM detalle_aporte_sbif
    WHERE TO_CHAR(fecha_transaccion,'MMYYYY') = p_mes_anno
      AND tipo_transaccion = p_tipo;

BEGIN
  -- Validacion del año (simple)
  IF v_anno < 2000 OR v_anno > 2100 THEN
    RAISE e_anno_invalido;
  END IF;

  v_fec_ini_anio := TO_DATE('01-01-' || v_anno, 'DD-MM-YYYY');
  v_fec_fin_anio := ADD_MONTHS(v_fec_ini_anio, 12);

  DBMS_OUTPUT.PUT_LINE('Año proceso: ' || v_anno);

  -- Proceso  repetible
  EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_aporte_sbif';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_aporte_sbif';

  -- Conteo esperado anual  
  SELECT COUNT(*)
    INTO v_esperadas
  FROM transaccion_tarjeta_cliente
  WHERE cod_tptran_tarjeta IN (102,103)
    AND fecha_transaccion >= v_fec_ini_anio
    AND fecha_transaccion <  v_fec_fin_anio;

  DBMS_OUTPUT.PUT_LINE('Transacciones esperadas (año, 102/103): ' || v_esperadas);


  -- CARGA DETALLE (12 meses)


  FOR v_mes IN 1..12 LOOP
    v_fec_ini := ADD_MONTHS(v_fec_ini_anio, v_mes-1);
    v_fec_fin := ADD_MONTHS(v_fec_ini, 1);

    FOR i IN 1 .. v_tipos.COUNT LOOP
      OPEN c_det(v_tipos(i), v_fec_ini, v_fec_fin);
      LOOP
        FETCH c_det INTO r_det;
        EXIT WHEN c_det%NOTFOUND;

        -- Busco el porcentaje segun tramo (si no existe tramo, queda 0)
        BEGIN
          SELECT porc_aporte_sbif
            INTO v_porc
          FROM tramo_aporte_sbif
          WHERE r_det.monto_total BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_porc := 0;
        END;

        -- Operador matematico (aporte = monto * porcentaje)
        v_aporte := ROUND(NVL(r_det.monto_total,0) * (v_porc/100));

        -- Insert detalle 
        INSERT INTO detalle_aporte_sbif
          (numrun, dvrun, nro_tarjeta, nro_transaccion, fecha_transaccion,
           tipo_transaccion, monto_transaccion, aporte_sbif)
        VALUES
          (r_det.numrun, r_det.dvrun, r_det.nro_tarjeta, r_det.nro_transaccion, r_det.fecha_transaccion,
           r_det.tipo_transaccion, r_det.monto_total, v_aporte);

        v_insertadas := v_insertadas + 1;
      END LOOP;
      CLOSE c_det;
    END LOOP;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Insertadas en DETALLE_APORTE_SBIF: ' || v_insertadas);

  -- Control de commit
  IF v_insertadas <> v_esperadas THEN
    RAISE e_control_commit;
  END IF;


  -- CARGA  RESUMEN (fila a fila con  cursores explicitos)

  FOR m IN c_meses LOOP
    FOR i IN 1 .. v_tipos.COUNT LOOP
      DECLARE
        v_nombre_tipo VARCHAR2(50);
        r_sum c_res%ROWTYPE;
      BEGIN
        -- Obtengo el nombre del tipo segun codigo (102 o 103)
        SELECT nombre_tptran_tarjeta
          INTO v_nombre_tipo
        FROM tipo_transaccion_tarjeta
        WHERE cod_tptran_tarjeta = v_tipos(i);

        OPEN c_res(m.mes_anno, v_nombre_tipo);
        FETCH c_res INTO r_sum;
        CLOSE c_res;

        -- Solo inserto si hay datos (SUM puede venir NULL)
        IF NVL(r_sum.monto_total_transacciones,0) > 0 OR NVL(r_sum.aporte_total_abif,0) > 0 THEN
          INSERT INTO resumen_aporte_sbif
            (mes_anno, tipo_transaccion, monto_total_transacciones, aporte_total_abif)
          VALUES
            (r_sum.mes_anno,
             r_sum.tipo_transaccion,
             NVL(r_sum.monto_total_transacciones,0),
             NVL(r_sum.aporte_total_abif,0));
        END IF;
      END;
    END LOOP;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('OK: COMMIT realizado.');

EXCEPTION
  WHEN e_anno_invalido THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: año invalido. ROLLBACK.');

  WHEN e_tabla_no_existe THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR -942: tabla/objeto no existe. ROLLBACK.');

  WHEN e_control_commit THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: control commit fallo. Esperadas='||v_esperadas||' Insertadas='||v_insertadas||'. ROLLBACK.');

  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR GENERAL: ' || SQLCODE || ' - ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('ROLLBACK realizado.');
END;
/
-- ////////////////////////////////////////////////
--- CHEQUEOS + EVIDENCIAS 
-- ////////////////////////////////////////////////


-- Conteos
SELECT COUNT(*) AS cnt_detalle FROM detalle_aporte_sbif;
SELECT COUNT(*) AS cnt_resumen FROM resumen_aporte_sbif;

-- Rango  fechas
SELECT MIN(fecha_transaccion) AS min_fech,
       MAX(fecha_transaccion) AS max_fech
FROM detalle_aporte_sbif;

-- Conteo por mes 
SELECT TO_CHAR(fecha_transaccion,'MMYYYY') AS mes_anno,
       COUNT(*) AS total
FROM detalle_aporte_sbif
GROUP BY TO_CHAR(fecha_transaccion,'MMYYYY')
ORDER BY TO_CHAR(fecha_transaccion,'MMYYYY');

-- 1 (DETALLE)
SELECT
  numrun,
  dvrun,
  TO_CHAR(nro_tarjeta, 'FM999999999999999999999999999999') AS nro_tarjeta,
  nro_transaccion,
  fecha_transaccion,
  tipo_transaccion,
  monto_transaccion,
  aporte_sbif
FROM detalle_aporte_sbif
ORDER BY fecha_transaccion ASC, numrun ASC;

---  2 (RESUMEN)
SELECT
  mes_anno,
  tipo_transaccion,
  monto_total_transacciones,
  aporte_total_abif
FROM resumen_aporte_sbif
ORDER BY mes_anno ASC, tipo_transaccion ASC;