SET SERVEROUTPUT ON;
SET VERIFY OFF;
SET LINESIZE 200;
SET PAGESIZE 100;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

COLUMN nro_tarjeta FORMAT 99999999999999999999
COLUMN tipo_transaccion FORMAT A40
COLUMN dvrun FORMAT A1

VAR b_anno_puntos NUMBER;
VAR b_tramo1_ini NUMBER;
VAR b_tramo1_fin NUMBER;
VAR b_tramo2_ini NUMBER;
VAR b_tramo2_fin NUMBER;
VAR b_tramo3_ini NUMBER;
VAR b_anno_sbif NUMBER;

BEGIN
    -- Valores del proceso
    :b_anno_puntos := EXTRACT(YEAR FROM SYSDATE) - 1;
    :b_tramo1_ini  := 500000;
    :b_tramo1_fin  := 700000;
    :b_tramo2_ini  := 700001;
    :b_tramo2_fin  := 900000;
    :b_tramo3_ini  := 900001;
    :b_anno_sbif   := EXTRACT(YEAR FROM SYSDATE);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Inicio');
    DBMS_OUTPUT.PUT_LINE('Anio puntos: ' || :b_anno_puntos);
    DBMS_OUTPUT.PUT_LINE('Anio SBIF: ' || :b_anno_sbif);
    DBMS_OUTPUT.PUT_LINE(' ');
END;
/

DECLARE
    c_cod_compra  CONSTANT NUMBER := 101;
    c_cod_avance  CONSTANT NUMBER := 102;
    c_cod_savance CONSTANT NUMBER := 103;

    v_anno_proceso NUMBER := :b_anno_puntos;
    v_tramo1_ini   NUMBER := :b_tramo1_ini;
    v_tramo1_fin   NUMBER := :b_tramo1_fin;
    v_tramo2_ini   NUMBER := :b_tramo2_ini;
    v_tramo2_fin   NUMBER := :b_tramo2_fin;
    v_tramo3_ini   NUMBER := :b_tramo3_ini;

    TYPE t_varray_puntos IS VARRAY(4) OF NUMBER;
    v_valores_puntos t_varray_puntos := t_varray_puntos(250, 300, 550, 700);

    TYPE r_detalle_puntos IS RECORD (
        numrun              CLIENTE.numrun%TYPE,
        dvrun               CLIENTE.dvrun%TYPE,
        nro_tarjeta         TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_transaccion     TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_transaccion   TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        tipo_transaccion    TIPO_TRANSACCION_TARJETA.nombre_tptran_tarjeta%TYPE,
        monto_transaccion   TRANSACCION_TARJETA_CLIENTE.monto_transaccion%TYPE,
        cod_tptran_tarjeta  TRANSACCION_TARJETA_CLIENTE.cod_tptran_tarjeta%TYPE,
        cod_tipo_cliente    CLIENTE.cod_tipo_cliente%TYPE,
        total_anual_cliente NUMBER
    );

    TYPE rc_detalle_puntos IS REF CURSOR;
    v_cursor_detalle rc_detalle_puntos;
    v_detalle r_detalle_puntos;

    ---  Cursor para consolidar  por mes
    CURSOR c_resumen_puntos(p_mes NUMBER, p_anno NUMBER) IS
        SELECT  c.numrun,
                c.dvrun,
                tc.nro_tarjeta,
                ttc.nro_transaccion,
                ttc.fecha_transaccion,
                ttt.nombre_tptran_tarjeta AS tipo_transaccion,
                ttc.monto_transaccion,
                ttc.cod_tptran_tarjeta,
                c.cod_tipo_cliente,
                (
                    SELECT NVL(SUM(ttc2.monto_transaccion), 0)
                    FROM TARJETA_CLIENTE tc2
                    JOIN TRANSACCION_TARJETA_CLIENTE ttc2
                      ON ttc2.nro_tarjeta = tc2.nro_tarjeta
                    WHERE tc2.numrun = c.numrun
                      AND EXTRACT(YEAR FROM ttc2.fecha_transaccion) = p_anno
                ) AS total_anual_cliente
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc
          ON tc.numrun = c.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc
          ON ttc.nro_tarjeta = tc.nro_tarjeta
        JOIN TIPO_TRANSACCION_TARJETA ttt
          ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = p_anno
          AND EXTRACT(MONTH FROM ttc.fecha_transaccion) = p_mes
        ORDER BY ttc.fecha_transaccion, c.numrun, ttc.nro_transaccion;

    v_puntos_detalle NUMBER;
    v_mes_anno       VARCHAR2(6);

    v_monto_total_compras   NUMBER := 0;
    v_total_puntos_compras  NUMBER := 0;
    v_monto_total_avances   NUMBER := 0;
    v_total_puntos_avances  NUMBER := 0;
    v_monto_total_savances  NUMBER := 0;
    v_total_puntos_savances NUMBER := 0;

    v_cont_detalle NUMBER := 0;
    v_cont_resumen NUMBER := 0;

    FUNCTION f_calcula_puntos(
        p_monto_transaccion NUMBER,
        p_cod_tipo_cliente  NUMBER,
        p_total_anual       NUMBER
    ) RETURN NUMBER
    IS
        v_puntos_normales NUMBER := 0;
        v_puntos_extra    NUMBER := 0;
    BEGIN
        ---- Puntaje base por cada 100000
        v_puntos_normales := TRUNC(p_monto_transaccion / 100000) * v_valores_puntos(1);

        -- Puntaje adicional segun tramo anual del cliente
        IF p_cod_tipo_cliente IN (30, 40) THEN
            IF p_total_anual BETWEEN v_tramo1_ini AND v_tramo1_fin THEN
                v_puntos_extra := TRUNC(p_monto_transaccion / 100000) * v_valores_puntos(2);
            ELSIF p_total_anual BETWEEN v_tramo2_ini AND v_tramo2_fin THEN
                v_puntos_extra := TRUNC(p_monto_transaccion / 100000) * v_valores_puntos(3);
            ELSIF p_total_anual >= v_tramo3_ini THEN
                v_puntos_extra := TRUNC(p_monto_transaccion / 100000) * v_valores_puntos(4);
            END IF;
        END IF;

        RETURN v_puntos_normales + v_puntos_extra;
    END f_calcula_puntos;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Calculo de puntos');

    -- Limpieza 
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_PUNTOS_TARJETA_CATB';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_PUNTOS_TARJETA_CATB';

    SAVEPOINT sp_puntos;

    -- Cursor variable para recorrer ell detalle anual
    OPEN v_cursor_detalle FOR
        SELECT  c.numrun,
                c.dvrun,
                tc.nro_tarjeta,
                ttc.nro_transaccion,
                ttc.fecha_transaccion,
                ttt.nombre_tptran_tarjeta AS tipo_transaccion,
                ttc.monto_transaccion,
                ttc.cod_tptran_tarjeta,
                c.cod_tipo_cliente,
                (
                    SELECT NVL(SUM(ttc2.monto_transaccion), 0)
                    FROM TARJETA_CLIENTE tc2
                    JOIN TRANSACCION_TARJETA_CLIENTE ttc2
                      ON ttc2.nro_tarjeta = tc2.nro_tarjeta
                    WHERE tc2.numrun = c.numrun
                      AND EXTRACT(YEAR FROM ttc2.fecha_transaccion) = v_anno_proceso
                ) AS total_anual_cliente
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc
          ON tc.numrun = c.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc
          ON ttc.nro_tarjeta = tc.nro_tarjeta
        JOIN TIPO_TRANSACCION_TARJETA ttt
          ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = v_anno_proceso
        ORDER BY ttc.fecha_transaccion, c.numrun, ttc.nro_transaccion;

    LOOP
        FETCH v_cursor_detalle INTO v_detalle;
        EXIT WHEN v_cursor_detalle%NOTFOUND;

        v_puntos_detalle := f_calcula_puntos(
            v_detalle.monto_transaccion,
            v_detalle.cod_tipo_cliente,
            v_detalle.total_anual_cliente
        );

        INSERT INTO DETALLE_PUNTOS_TARJETA_CATB
        (
            numrun,
            dvrun,
            nro_tarjeta,
            nro_transaccion,
            fecha_transaccion,
            tipo_transaccion,
            monto_transaccion,
            puntos_allthebest
        )
        VALUES
        (
            v_detalle.numrun,
            UPPER(v_detalle.dvrun),
            v_detalle.nro_tarjeta,
            v_detalle.nro_transaccion,
            v_detalle.fecha_transaccion,
            v_detalle.tipo_transaccion,
            v_detalle.monto_transaccion,
            v_puntos_detalle
        );

        v_cont_detalle := v_cont_detalle + 1;
    END LOOP;

    CLOSE v_cursor_detalle;

    ---  Resumen  mensual  
    FOR v_mes IN 1 .. 12 LOOP
        v_monto_total_compras   := 0;
        v_total_puntos_compras  := 0;
        v_monto_total_avances   := 0;
        v_total_puntos_avances  := 0;
        v_monto_total_savances  := 0;
        v_total_puntos_savances := 0;

        FOR r IN c_resumen_puntos(v_mes, v_anno_proceso) LOOP
            v_puntos_detalle := f_calcula_puntos(
                r.monto_transaccion,
                r.cod_tipo_cliente,
                r.total_anual_cliente
            );

            CASE r.cod_tptran_tarjeta
                WHEN c_cod_compra THEN
                    v_monto_total_compras  := v_monto_total_compras + r.monto_transaccion;
                    v_total_puntos_compras := v_total_puntos_compras + v_puntos_detalle;
                WHEN c_cod_avance THEN
                    v_monto_total_avances  := v_monto_total_avances + r.monto_transaccion;
                    v_total_puntos_avances := v_total_puntos_avances + v_puntos_detalle;
                WHEN c_cod_savance THEN
                    v_monto_total_savances  := v_monto_total_savances + r.monto_transaccion;
                    v_total_puntos_savances := v_total_puntos_savances + v_puntos_detalle;
            END CASE;
        END LOOP;

        IF NVL(v_monto_total_compras, 0) > 0
           OR NVL(v_monto_total_avances, 0) > 0
           OR NVL(v_monto_total_savances, 0) > 0 THEN

            v_mes_anno := LPAD(v_mes, 2, '0') || TO_CHAR(v_anno_proceso);

            INSERT INTO RESUMEN_PUNTOS_TARJETA_CATB
            (
                mes_anno,
                monto_total_compras,
                total_puntos_compras,
                monto_total_avances,
                total_puntos_avances,
                monto_total_savances,
                total_puntos_savances
            )
            VALUES
            (
                v_mes_anno,
                v_monto_total_compras,
                v_total_puntos_compras,
                v_monto_total_avances,
                v_total_puntos_avances,
                v_monto_total_savances,
                v_total_puntos_savances
            );

            v_cont_resumen := v_cont_resumen + 1;
        END IF;
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Puntos listos');
    DBMS_OUTPUT.PUT_LINE('Registros detalle: ' || v_cont_detalle);
    DBMS_OUTPUT.PUT_LINE('Registros resumen: ' || v_cont_resumen);
    DBMS_OUTPUT.PUT_LINE(' ');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_puntos;
        DBMS_OUTPUT.PUT_LINE('Error en puntos: ' || SQLERRM);
        RAISE;
END;
/

DECLARE
    c_cod_avance  CONSTANT NUMBER := 102;
    c_cod_savance CONSTANT NUMBER := 103;

    v_anno_proceso NUMBER := :b_anno_sbif;
    v_mes_anno     VARCHAR2(6);

    v_nombre_avance  TIPO_TRANSACCION_TARJETA.nombre_tptran_tarjeta%TYPE;
    v_nombre_savance TIPO_TRANSACCION_TARJETA.nombre_tptran_tarjeta%TYPE;

    -- Cursor para el detalle anual de avances y  super avances
    CURSOR c_detalle_sbif IS
        SELECT  c.numrun,
                c.dvrun,
                tc.nro_tarjeta,
                ttc.nro_transaccion,
                ttc.fecha_transaccion,
                ttt.nombre_tptran_tarjeta AS tipo_transaccion,
                ttc.monto_total_transaccion AS monto_total_transaccion,
                ttc.cod_tptran_tarjeta
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc
          ON tc.numrun = c.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc
          ON ttc.nro_tarjeta = tc.nro_tarjeta
        JOIN TIPO_TRANSACCION_TARJETA ttt
          ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = v_anno_proceso
          AND ttc.cod_tptran_tarjeta IN (c_cod_avance, c_cod_savance)
        ORDER BY ttc.fecha_transaccion, c.numrun, ttc.nro_transaccion;

    -- Cursor parametrizado para consolidar por mes
    CURSOR c_resumen_sbif(p_mes NUMBER, p_anno NUMBER) IS
        SELECT  c.numrun,
                c.dvrun,
                tc.nro_tarjeta,
                ttc.nro_transaccion,
                ttc.fecha_transaccion,
                ttt.nombre_tptran_tarjeta AS tipo_transaccion,
                ttc.monto_total_transaccion AS monto_total_transaccion,
                ttc.cod_tptran_tarjeta
        FROM CLIENTE c
        JOIN TARJETA_CLIENTE tc
          ON tc.numrun = c.numrun
        JOIN TRANSACCION_TARJETA_CLIENTE ttc
          ON ttc.nro_tarjeta = tc.nro_tarjeta
        JOIN TIPO_TRANSACCION_TARJETA ttt
          ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = p_anno
          AND EXTRACT(MONTH FROM ttc.fecha_transaccion) = p_mes
          AND ttc.cod_tptran_tarjeta IN (c_cod_avance, c_cod_savance)
        ORDER BY ttc.fecha_transaccion, c.numrun, ttc.nro_transaccion;

    v_aporte_detalle NUMBER;

    v_monto_total_avance   NUMBER := 0;
    v_aporte_total_avance  NUMBER := 0;
    v_monto_total_savance  NUMBER := 0;
    v_aporte_total_savance NUMBER := 0;

    v_cont_detalle NUMBER := 0;
    v_cont_resumen NUMBER := 0;

    FUNCTION f_obtiene_porcentaje_sbif(p_monto_total NUMBER) RETURN NUMBER
    IS
        v_porcentaje NUMBER := 0;
    BEGIN
        --  Busca el porcentaje correspondiente al tramo
        SELECT tas.porc_aporte_sbif
        INTO v_porcentaje
        FROM TRAMO_APORTE_SBIF tas
        WHERE p_monto_total BETWEEN tas.tramo_inf_av_sav AND tas.tramo_sup_av_sav;

        RETURN v_porcentaje;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END f_obtiene_porcentaje_sbif;

    FUNCTION f_calcula_aporte_sbif(p_monto_total NUMBER) RETURN NUMBER
    IS
        v_porcentaje NUMBER := 0;
    BEGIN
        -- Calcula el aporte a  partir del porcentaje del tramo
        v_porcentaje := f_obtiene_porcentaje_sbif(p_monto_total);
        RETURN ROUND(p_monto_total * v_porcentaje / 100);
    END f_calcula_aporte_sbif;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Calculo de aporte SBIF');

    SELECT nombre_tptran_tarjeta
    INTO v_nombre_avance
    FROM TIPO_TRANSACCION_TARJETA
    WHERE cod_tptran_tarjeta = c_cod_avance;

    SELECT nombre_tptran_tarjeta
    INTO v_nombre_savance
    FROM TIPO_TRANSACCION_TARJETA
    WHERE cod_tptran_tarjeta = c_cod_savance;

    -- Limpieza previa
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';

    SAVEPOINT sp_sbif;

    -- Carga del  detalle
    FOR r IN c_detalle_sbif LOOP
        v_aporte_detalle := f_calcula_aporte_sbif(r.monto_total_transaccion);

        INSERT INTO DETALLE_APORTE_SBIF
        (
            numrun,
            dvrun,
            nro_tarjeta,
            nro_transaccion,
            fecha_transaccion,
            tipo_transaccion,
            monto_transaccion,
            aporte_sbif
        )
        VALUES
        (
            r.numrun,
            UPPER(r.dvrun),
            r.nro_tarjeta,
            r.nro_transaccion,
            r.fecha_transaccion,
            r.tipo_transaccion,
            r.monto_total_transaccion,
            v_aporte_detalle
        );

        v_cont_detalle := v_cont_detalle + 1;
    END LOOP;

    -- Resumen mensual , separado por tipo
    FOR v_mes IN 1 .. 12 LOOP
        v_monto_total_avance   := 0;
        v_aporte_total_avance  := 0;
        v_monto_total_savance  := 0;
        v_aporte_total_savance := 0;

        FOR r IN c_resumen_sbif(v_mes, v_anno_proceso) LOOP
            v_aporte_detalle := f_calcula_aporte_sbif(r.monto_total_transaccion);

            CASE r.cod_tptran_tarjeta
                WHEN c_cod_avance THEN
                    v_monto_total_avance  := v_monto_total_avance + r.monto_total_transaccion;
                    v_aporte_total_avance := v_aporte_total_avance + v_aporte_detalle;
                WHEN c_cod_savance THEN
                    v_monto_total_savance  := v_monto_total_savance + r.monto_total_transaccion;
                    v_aporte_total_savance := v_aporte_total_savance + v_aporte_detalle;
            END CASE;
        END LOOP;

        v_mes_anno := LPAD(v_mes, 2, '0') || TO_CHAR(v_anno_proceso);

        IF NVL(v_monto_total_avance, 0) > 0 THEN
            INSERT INTO RESUMEN_APORTE_SBIF
            (
                mes_anno,
                tipo_transaccion,
                monto_total_transacciones,
                aporte_total_abif
            )
            VALUES
            (
                v_mes_anno,
                v_nombre_avance,
                v_monto_total_avance,
                v_aporte_total_avance
            );

            v_cont_resumen := v_cont_resumen + 1;
        END IF;

        IF NVL(v_monto_total_savance, 0) > 0 THEN
            INSERT INTO RESUMEN_APORTE_SBIF
            (
                mes_anno,
                tipo_transaccion,
                monto_total_transacciones,
                aporte_total_abif
            )
            VALUES
            (
                v_mes_anno,
                v_nombre_savance,
                v_monto_total_savance,
                v_aporte_total_savance
            );

            v_cont_resumen := v_cont_resumen + 1;
        END IF;
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Aporte SBIF listo');
    DBMS_OUTPUT.PUT_LINE('Registros detalle: ' || v_cont_detalle);
    DBMS_OUTPUT.PUT_LINE('Registros resumen: ' || v_cont_resumen);
    DBMS_OUTPUT.PUT_LINE(' ');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_sbif;
        DBMS_OUTPUT.PUT_LINE('Error en aporte SBIF: ' || SQLERRM);
        RAISE;
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Figura 1');
END;
/

SELECT numrun,
       UPPER(dvrun) AS dvrun,
       nro_tarjeta,
       nro_transaccion,
       fecha_transaccion,
       CASE
           WHEN tipo_transaccion LIKE 'S%per Avance en Efectivo' THEN 'Super Avance en Efectivo'
           ELSE tipo_transaccion
       END AS tipo_transaccion,
       monto_transaccion,
       puntos_allthebest
FROM DETALLE_PUNTOS_TARJETA_CATB
ORDER BY fecha_transaccion, numrun, nro_transaccion;

BEGIN
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('Figura 2');
END;
/

SELECT mes_anno,
       monto_total_compras,
       total_puntos_compras,
       monto_total_avances,
       total_puntos_avances,
       monto_total_savances,
       total_puntos_savances
FROM RESUMEN_PUNTOS_TARJETA_CATB
ORDER BY mes_anno;

BEGIN
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('Figura 3');
END;
/
-- Evidencia 
SELECT numrun,
       UPPER(dvrun) AS dvrun,
       nro_tarjeta,
       nro_transaccion,
       fecha_transaccion,
       CASE
           WHEN tipo_transaccion LIKE 'S%per Avance en Efectivo' THEN 'Super Avance en Efectivo'
           ELSE tipo_transaccion
       END AS tipo_transaccion,
       monto_transaccion AS monto_total_transaccion,
       aporte_sbif
FROM DETALLE_APORTE_SBIF
ORDER BY fecha_transaccion, numrun, nro_transaccion;

BEGIN
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('Figura 4');
END;
/
 --- Evidencia
SELECT mes_anno,
       CASE
           WHEN tipo_transaccion LIKE 'S%per Avance en Efectivo' THEN 'Super Avance en Efectivo'
           ELSE tipo_transaccion
       END AS tipo_transaccion,
       monto_total_transacciones,
       aporte_total_abif
FROM RESUMEN_APORTE_SBIF
ORDER BY mes_anno, tipo_transaccion;