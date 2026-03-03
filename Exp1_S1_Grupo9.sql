SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';





--- CASO 1
-- Programa de   Pesos   TODOSUMA


-- Entradas del proceso
VARIABLE p_run_cliente         VARCHAR2(15);
VARIABLE p_tramo_1             NUMBER;
VARIABLE p_tramo_2             NUMBER;
VARIABLE p_pesos_normal        NUMBER;
VARIABLE p_pesos_extra_1       NUMBER;
VARIABLE p_pesos_extra_2       NUMBER;
VARIABLE p_pesos_extra_3       NUMBER;

-- Valores base
EXEC :p_run_cliente   := '21242003-4';
EXEC :p_tramo_1       := 1000000;
EXEC :p_tramo_2       := 3000000;
EXEC :p_pesos_normal  := 1200;
EXEC :p_pesos_extra_1 := 100;
EXEC :p_pesos_extra_2 := 300;
EXEC :p_pesos_extra_3 := 550;

DECLARE
    v_nro_cliente             CLIENTE.nro_cliente%TYPE;
    v_numrun                  CLIENTE.numrun%TYPE;
    v_dvrun                   CLIENTE.dvrun%TYPE;
    v_nombre_cliente          VARCHAR2(100);
    v_tipo_cliente            TIPO_CLIENTE.nombre_tipo_cliente%TYPE;

    v_monto_total_creditos    NUMBER := 0;
    v_tramos_100mil           NUMBER := 0;
    v_pesos_por_tramo         NUMBER := 0;
    v_monto_pesos_todosuma    NUMBER := 0;

    v_anio_anterior           NUMBER := EXTRACT(YEAR FROM SYSDATE) - 1;
BEGIN
    -- Buscar cliente por  RUN
    SELECT  c.nro_cliente,
            c.numrun,
            c.dvrun,
            TRIM(
                c.pnombre || ' ' ||
                NVL(c.snombre || ' ', '') ||
                c.appaterno || ' ' ||
                NVL(c.apmaterno, '')
            ),
            tc.nombre_tipo_cliente
    INTO    v_nro_cliente,
            v_numrun,
            v_dvrun,
            v_nombre_cliente,
            v_tipo_cliente
    FROM CLIENTE c
    JOIN TIPO_CLIENTE tc
        ON tc.cod_tipo_cliente = c.cod_tipo_cliente
    WHERE TO_CHAR(c.numrun) || '-' || UPPER(c.dvrun) = UPPER(:p_run_cliente);

    -- Sumarr creditos del año anterior
    SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_creditos
    FROM CREDITO_CLIENTE cc
    WHERE cc.nro_cliente = v_nro_cliente
      AND EXTRACT(YEAR FROM cc.fecha_otorga_cred) = v_anio_anterior;

    -- Contar tramos completos de 100.000
    v_tramos_100mil := TRUNC(v_monto_total_creditos / 100000);

    -- Valor base por tramo
    v_pesos_por_tramo := :p_pesos_normal;

    -- Extra para independientes segun tramo
    IF UPPER(v_tipo_cliente) = UPPER('Trabajadores independientes') THEN
        IF v_monto_total_creditos < :p_tramo_1 THEN
            v_pesos_por_tramo := v_pesos_por_tramo + :p_pesos_extra_1;
        ELSIF v_monto_total_creditos <= :p_tramo_2 THEN
            v_pesos_por_tramo := v_pesos_por_tramo + :p_pesos_extra_2;
        ELSE
            v_pesos_por_tramo := v_pesos_por_tramo + :p_pesos_extra_3;
        END IF;
    END IF;

    -- Calculo final
    v_monto_pesos_todosuma := v_tramos_100mil * v_pesos_por_tramo;

    -- Si ya existe un resultado anterior, se reemplaza
    DELETE FROM CLIENTE_TODOSUMA
    WHERE nro_cliente = v_nro_cliente;

    INSERT INTO CLIENTE_TODOSUMA
    (
        nro_cliente,
        run_cliente,
        nombre_cliente,
        tipo_cliente,
        monto_solic_creditos,
        monto_pesos_todosuma
    )
    VALUES
    (
        v_nro_cliente,
        TO_CHAR(v_numrun) || '-' || v_dvrun,
        v_nombre_cliente,
        v_tipo_cliente,
        v_monto_total_creditos,
        v_monto_pesos_todosuma
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('CASO 1 EJECUTADO');
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || v_nro_cliente || ' - ' || v_nombre_cliente);
    DBMS_OUTPUT.PUT_LINE('Tipo: ' || v_tipo_cliente);
    DBMS_OUTPUT.PUT_LINE('Monto creditos anio anterior: ' || v_monto_total_creditos);
    DBMS_OUTPUT.PUT_LINE('Monto Pesos TODOSUMA: ' || v_monto_pesos_todosuma);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontro cliente para el RUN ' || :p_run_cliente);
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('El RUN devolvio mas de un cliente');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en Caso 1: ' || SQLERRM);
END;
/

-- Revision de Caso 1 evudencia
SELECT *
FROM CLIENTE_TODOSUMA
ORDER BY nro_cliente;



---- CASO 2
-- Postergacion de  cuotas


-- Entradas del proceso
VARIABLE p_nro_cliente         NUMBER;
VARIABLE p_nro_solic_credito   NUMBER;
VARIABLE p_cant_cuotas_post    NUMBER;

-- Valores de prueba
EXEC :p_nro_cliente       := 5;
EXEC :p_nro_solic_credito := 2001;
EXEC :p_cant_cuotas_post  := 2;

DECLARE
    v_nombre_credito           CREDITO.nombre_credito%TYPE;
    v_ultima_cuota             CUOTA_CREDITO_CLIENTE.nro_cuota%TYPE;
    v_fecha_ult_venc           CUOTA_CREDITO_CLIENTE.fecha_venc_cuota%TYPE;
    v_valor_ult_cuota          CUOTA_CREDITO_CLIENTE.valor_cuota%TYPE;

    v_nueva_cuota              NUMBER;
    v_nueva_fecha_venc         DATE;
    v_nuevo_valor_cuota        NUMBER;

    v_tasa_interes             NUMBER := 0;
    v_cant_creditos_anio_ant   NUMBER := 0;
    v_anio_anterior            NUMBER := EXTRACT(YEAR FROM SYSDATE) - 1;
BEGIN
    -- Obtener tipo de credito
    SELECT c.nombre_credito
    INTO v_nombre_credito
    FROM CREDITO_CLIENTE cc
    JOIN CREDITO c
        ON c.cod_credito = cc.cod_credito
    WHERE cc.nro_solic_credito = :p_nro_solic_credito
      AND cc.nro_cliente = :p_nro_cliente;

    -- Buscar ultima cuota actual
    SELECT MAX(nro_cuota)
    INTO v_ultima_cuota
    FROM CUOTA_CREDITO_CLIENTE
    WHERE nro_solic_credito = :p_nro_solic_credito;

    SELECT fecha_venc_cuota, valor_cuota
    INTO v_fecha_ult_venc, v_valor_ult_cuota
    FROM CUOTA_CREDITO_CLIENTE
    WHERE nro_solic_credito = :p_nro_solic_credito
      AND nro_cuota = v_ultima_cuota;

    -- Definir tasa segun el nombre del credito
   
    IF UPPER(v_nombre_credito) LIKE '%HIPOT%' THEN
        IF :p_cant_cuotas_post = 1 THEN
            v_tasa_interes := 0;
        ELSIF :p_cant_cuotas_post = 2 THEN
            v_tasa_interes := 0.005;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Hipotecario permite 1 o 2 cuotas');
        END IF;

    ELSIF UPPER(v_nombre_credito) LIKE '%CONSUM%' THEN
        IF :p_cant_cuotas_post = 1 THEN
            v_tasa_interes := 0.01;
        ELSE
            RAISE_APPLICATION_ERROR(-20002, 'Consumo permite solo 1 cuota');
        END IF;

    ELSIF UPPER(v_nombre_credito) LIKE '%AUTOM%' THEN
        IF :p_cant_cuotas_post = 1 THEN
            v_tasa_interes := 0.02;
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Automotriz permite solo 1 cuota');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Tipo de credito no valido para este proceso');
    END IF;

    -- Revisar si tuvo mas  de un credito el año anterior
    SELECT COUNT(*)
    INTO v_cant_creditos_anio_ant
    FROM CREDITO_CLIENTE
    WHERE nro_cliente = :p_nro_cliente
      AND EXTRACT(YEAR FROM fecha_otorga_cred) = v_anio_anterior;

    -- Si tuvo mas de un credito, la ultima cuota original queda pagada
    IF v_cant_creditos_anio_ant > 1 THEN
        UPDATE CUOTA_CREDITO_CLIENTE
        SET fecha_pago_cuota = fecha_venc_cuota,
            monto_pagado     = valor_cuota,
            saldo_por_pagar  = 0
        WHERE nro_solic_credito = :p_nro_solic_credito
          AND nro_cuota = v_ultima_cuota;
    END IF;

    ---- Crear nuevas cuotas
    FOR i IN 1 .. :p_cant_cuotas_post LOOP
        v_nueva_cuota       := v_ultima_cuota + i;
        v_nueva_fecha_venc  := ADD_MONTHS(v_fecha_ult_venc, i);
        v_nuevo_valor_cuota := ROUND(v_valor_ult_cuota * (1 + v_tasa_interes));

        INSERT INTO CUOTA_CREDITO_CLIENTE
        (
            nro_solic_credito,
            nro_cuota,
            fecha_venc_cuota,
            valor_cuota,
            fecha_pago_cuota,
            monto_pagado,
            saldo_por_pagar,
            cod_forma_pago
        )
        VALUES
        (
            :p_nro_solic_credito,
            v_nueva_cuota,
            v_nueva_fecha_venc,
            v_nuevo_valor_cuota,
            NULL,
            NULL,
            NULL,
            NULL
        );
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('CASO 2 EJECUTADO');
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || :p_nro_cliente);
    DBMS_OUTPUT.PUT_LINE('Solicitud: ' || :p_nro_solic_credito);
    DBMS_OUTPUT.PUT_LINE('Tipo credito: ' || v_nombre_credito);
    DBMS_OUTPUT.PUT_LINE('Cuotas postergadas: ' || :p_cant_cuotas_post);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No existe ese credito para ese cliente');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Las nuevas cuotas ya existen. Recargar la base para repetir esta prueba');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en Caso 2: ' || SQLERRM);
END;
/

-- Revision del Caso 2 evidencia:
SELECT nro_solic_credito,
       nro_cuota,
       fecha_venc_cuota,
       valor_cuota,
       fecha_pago_cuota,
       monto_pagado,
       saldo_por_pagar,
       cod_forma_pago
FROM CUOTA_CREDITO_CLIENTE
WHERE nro_solic_credito = :p_nro_solic_credito
ORDER BY nro_solic_credito, nro_cuota;