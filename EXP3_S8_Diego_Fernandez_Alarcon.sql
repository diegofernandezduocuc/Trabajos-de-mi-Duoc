SET SERVEROUTPUT ON;
SET VERIFY OFF;

------------------------------------------------------------
-- LIMPIEZA DE OBJETOS
------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_total_consumos';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_cobranza_hotel';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_obtiene_agencia';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_obtiene_consumos';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_obtiene_alojamiento';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION fn_descuento_consumos';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE sp_proceso_cobranza_diaria';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

------------------------------------------------------------
---- TRIGGER
--   MANTIENE TOTAL_CONSUMOS SEGUN INSERT/UPDATE/DELETE EN CONSUMO
------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_total_consumos
AFTER INSERT OR DELETE OR UPDATE OF monto ON consumo
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE total_consumos
           SET monto_consumos = NVL(monto_consumos, 0) + NVL(:NEW.monto, 0)
         WHERE id_huesped = :NEW.id_huesped;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO total_consumos (id_huesped, monto_consumos)
            VALUES (:NEW.id_huesped, NVL(:NEW.monto, 0));
        END IF;

    ELSIF DELETING THEN
        UPDATE total_consumos
           SET monto_consumos = NVL(monto_consumos, 0) - NVL(:OLD.monto, 0)
         WHERE id_huesped = :OLD.id_huesped;

    ELSIF UPDATING THEN
        UPDATE total_consumos
           SET monto_consumos = NVL(monto_consumos, 0) - NVL(:OLD.monto, 0) + NVL(:NEW.monto, 0)
         WHERE id_huesped = :NEW.id_huesped;
    END IF;
END;
/
SHOW ERRORS;

--------------------------------------------------------
----//// PACKAGEe
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_cobranza_hotel IS
    g_monto_tours NUMBER := 0;

    FUNCTION fn_monto_tours(
        p_id_huesped IN huesped.id_huesped%TYPE
    ) RETURN NUMBER;
END pkg_cobranza_hotel;
/
SHOW ERRORS;

CREATE OR REPLACE PACKAGE BODY pkg_cobranza_hotel IS

    FUNCTION fn_monto_tours(
        p_id_huesped IN huesped.id_huesped%TYPE
    ) RETURN NUMBER
    IS
        v_monto_tours NUMBER := 0;
        v_msg_error   VARCHAR2(4000);
    BEGIN
        SELECT NVL(SUM(t.valor_tour * NVL(ht.num_personas, 0)), 0)
          INTO v_monto_tours
          FROM huesped_tour ht
          JOIN tour t
            ON t.id_tour = ht.id_tour
         WHERE ht.id_huesped = p_id_huesped;

        g_monto_tours := NVL(v_monto_tours, 0);
        RETURN NVL(v_monto_tours, 0);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            g_monto_tours := 0;
            RETURN 0;

        WHEN OTHERS THEN
            v_msg_error := 'HUESPED ' || p_id_huesped || ' - ' || SQLERRM;

            INSERT INTO reg_errores (
                id_error,
                nomsubprograma,
                msg_error
            ) VALUES (
                sq_error.NEXTVAL,
                'pkg_cobranza_hotel.fn_monto_tours',
                v_msg_error
            );

            g_monto_tours := 0;
            RETURN 0;
    END fn_monto_tours;

END pkg_cobranza_hotel;
/
SHOW ERRORS;

--------
--- FUNCION 1
-- OBTIENE NOMBRE DE AGENCIA
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_obtiene_agencia(
    p_id_huesped IN huesped.id_huesped%TYPE
)
RETURN VARCHAR2
IS
    v_agencia   VARCHAR2(100);
    v_msg_error VARCHAR2(4000);
BEGIN
    SELECT a.nom_agencia
      INTO v_agencia
      FROM huesped h
      JOIN agencia a
        ON a.id_agencia = h.id_agencia
     WHERE h.id_huesped = p_id_huesped;

    RETURN v_agencia;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_msg_error := 'HUESPED ' || p_id_huesped || ' - NO REGISTRA AGENCIA';

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'fn_obtiene_agencia',
            v_msg_error
        );

        RETURN 'NO REGISTRA AGENCIA';

    WHEN OTHERS THEN
        v_msg_error := 'HUESPED ' || p_id_huesped || ' - ' || SQLERRM;

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'fn_obtiene_agencia',
            v_msg_error
        );

        RETURN 'NO REGISTRA AGENCIA';
END;
/
SHOW ERRORS;

------------------------------------------------------------
---- FUNCION 2
-- OBTIENE TOTAL DE CONSUMOS
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_obtiene_consumos(
    p_id_huesped IN huesped.id_huesped%TYPE
)
RETURN NUMBER
IS
    v_consumos  NUMBER := 0;
    v_msg_error VARCHAR2(4000);
BEGIN
    SELECT monto_consumos
      INTO v_consumos
      FROM total_consumos
     WHERE id_huesped = p_id_huesped;

    RETURN NVL(v_consumos, 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_msg_error := 'HUESPED ' || p_id_huesped || ' - NO REGISTRA CONSUMOS';

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'fn_obtiene_consumos',
            v_msg_error
        );

        RETURN 0;

    WHEN OTHERS THEN
        v_msg_error := 'HUESPED ' || p_id_huesped || ' - ' || SQLERRM;

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'fn_obtiene_consumos',
            v_msg_error
        );

        RETURN 0;
END;
/
SHOW ERRORS;


----- FUNCION 3
-- OBTIENE MONTO DE ALOJAMIENTO EN DOLARES
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_obtiene_alojamiento(
    p_id_reserva IN reserva.id_reserva%TYPE
)
RETURN NUMBER
IS
    v_alojamiento NUMBER := 0;
    v_msg_error   VARCHAR2(4000);
BEGIN
    SELECT NVL(SUM((h.valor_habitacion + h.valor_minibar) * r.estadia), 0)
      INTO v_alojamiento
      FROM reserva r
      JOIN detalle_reserva dr
        ON dr.id_reserva = r.id_reserva
      JOIN habitacion h
        ON h.id_habitacion = dr.id_habitacion
     WHERE r.id_reserva = p_id_reserva;

    RETURN NVL(v_alojamiento, 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

    WHEN OTHERS THEN
        v_msg_error := 'RESERVA ' || p_id_reserva || ' - ' || SQLERRM;

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'fn_obtiene_alojamiento',
            v_msg_error
        );

        RETURN 0;
END;
/
SHOW ERRORS;

------------------------------------------------------------
--- FUNCION 4
-- CALCULA DESCUENTO POR CONSUMOS
------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_descuento_consumos(
    p_monto_consumos IN NUMBER
)
RETURN NUMBER
IS
    v_pct       NUMBER := 0;
    v_msg_error VARCHAR2(4000);
BEGIN
    SELECT NVL(pct, 0)
      INTO v_pct
      FROM tramos_consumos
     WHERE p_monto_consumos BETWEEN vmin_tramo AND vmax_tramo;

    RETURN ROUND(NVL(p_monto_consumos, 0) * NVL(v_pct, 0), 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

    WHEN OTHERS THEN
        v_msg_error := 'MONTO ' || NVL(p_monto_consumos, 0) || ' - ' || SQLERRM;

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'fn_descuento_consumos',
            v_msg_error
        );

        RETURN 0;
END;
/
SHOW ERRORS;

------------------------------------------------------------
--- PROCEDIMIENTO    PRINCIPAL
------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_proceso_cobranza_diaria(
    p_fecha_proceso IN DATE,
    p_valor_dolar   IN NUMBER
)
IS
    CURSOR c_huespedes_salida IS
        SELECT r.id_reserva,
               r.id_huesped,
               r.estadia,
               h.nom_huesped,
               h.appat_huesped,
               h.apmat_huesped
          FROM reserva r
          JOIN huesped h
            ON h.id_huesped = r.id_huesped
         WHERE TRUNC(r.ingreso + r.estadia) = TRUNC(p_fecha_proceso)
         ORDER BY r.id_huesped;

    v_nombre              VARCHAR2(200);
    v_agencia             VARCHAR2(100);
    v_alojamiento_usd     NUMBER := 0;
    v_consumos_usd        NUMBER := 0;
    v_tours_usd           NUMBER := 0;
    v_valor_persona_usd   NUMBER := 0;
    v_subtotal_usd        NUMBER := 0;
    v_desc_consumos_usd   NUMBER := 0;
    v_desc_agencia_usd    NUMBER := 0;
    v_total_usd           NUMBER := 0;

    v_alojamiento_clp     NUMBER := 0;
    v_consumos_clp        NUMBER := 0;
    v_tours_clp           NUMBER := 0;
    v_subtotal_clp        NUMBER := 0;
    v_desc_consumos_clp   NUMBER := 0;
    v_desc_agencia_clp    NUMBER := 0;
    v_total_clp           NUMBER := 0;

    v_msg_error           VARCHAR2(4000);
BEGIN
    DELETE FROM detalle_diario_huespedes;
    DELETE FROM reg_errores;
    COMMIT;

    FOR reg IN c_huespedes_salida LOOP
        v_nombre := RTRIM(
                        reg.nom_huesped || ' ' ||
                        reg.appat_huesped || ' ' ||
                        reg.apmat_huesped
                    );

        v_agencia           := fn_obtiene_agencia(reg.id_huesped);
        v_alojamiento_usd   := fn_obtiene_alojamiento(reg.id_reserva);
        v_consumos_usd      := fn_obtiene_consumos(reg.id_huesped);
        v_tours_usd         := pkg_cobranza_hotel.fn_monto_tours(reg.id_huesped);

        -- Cobro fijo por huesped expresado en CLP, convertido a USD
        v_valor_persona_usd := ROUND(35000 / p_valor_dolar, 2);

        v_subtotal_usd := NVL(v_alojamiento_usd, 0)
                        + NVL(v_consumos_usd, 0)
                        + NVL(v_tours_usd, 0)
                        + NVL(v_valor_persona_usd, 0);

        v_desc_consumos_usd := fn_descuento_consumos(v_consumos_usd);

        IF UPPER(v_agencia) = 'VIAJES ALBERTI' THEN
            v_desc_agencia_usd := ROUND(v_subtotal_usd * 0.12, 0);
        ELSE
            v_desc_agencia_usd := 0;
        END IF;

        v_total_usd := v_subtotal_usd - v_desc_consumos_usd - v_desc_agencia_usd;

        v_alojamiento_clp   := ROUND(v_alojamiento_usd * p_valor_dolar, 0);
        v_consumos_clp      := ROUND(v_consumos_usd * p_valor_dolar, 0);
        v_tours_clp         := ROUND(v_tours_usd * p_valor_dolar, 0);
        v_subtotal_clp      := ROUND(v_subtotal_usd * p_valor_dolar, 0);
        v_desc_consumos_clp := ROUND(v_desc_consumos_usd * p_valor_dolar, 0);
        v_desc_agencia_clp  := ROUND(v_desc_agencia_usd * p_valor_dolar, 0);
        v_total_clp         := ROUND(v_total_usd * p_valor_dolar, 0);

        INSERT INTO detalle_diario_huespedes (
            id_huesped,
            nombre,
            agencia,
            alojamiento,
            consumos,
            tours,
            subtotal_pago,
            descuento_consumos,
            descuentos_agencia,
            total
        ) VALUES (
            reg.id_huesped,
            v_nombre,
            v_agencia,
            v_alojamiento_clp,
            v_consumos_clp,
            v_tours_clp,
            v_subtotal_clp,
            v_desc_consumos_clp,
            v_desc_agencia_clp,
            v_total_clp
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso completado correctamente.');

EXCEPTION
    WHEN OTHERS THEN
        v_msg_error := SQLERRM;

        INSERT INTO reg_errores (
            id_error,
            nomsubprograma,
            msg_error
        ) VALUES (
            sq_error.NEXTVAL,
            'sp_proceso_cobranza_diaria',
            v_msg_error
        );

        ROLLBACK;
END;
/
SHOW ERRORS;

------------------------------------------------------------
--- PRUEBA DEL TRIGGER
------------------------------------------------------------
BEGIN
    INSERT INTO consumo (
        id_consumo,
        id_reserva,
        id_huesped,
        monto
    )
    VALUES (
        (SELECT NVL(MAX(id_consumo), 0) + 1 FROM consumo),
        1587,
        340006,
        150
    );

    DELETE FROM consumo
     WHERE id_consumo = 11473;

    UPDATE consumo
       SET monto = 95
     WHERE id_consumo = 10688;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Prueba de trigger ejecutada.');
END;
/
SHOW ERRORS;

------------------------------------------------------------
-- PRUEBA DEL PROCEDIMIENTO
------------------------------------------------------------
BEGIN
    sp_proceso_cobranza_diaria(
        TO_DATE('18/08/2021', 'DD/MM/YYYY'),
        915
    );
END;
/
SHOW ERRORS;

------------------------------------------------------------
-----------------------------------------
----- CONSULTAS FINALES  evidencia:
------------------------------------------------------------
SELECT *
FROM total_consumos
WHERE id_huesped = 340006
ORDER BY id_huesped;

SELECT *
FROM detalle_diario_huespedes
ORDER BY id_huesped;

SELECT *
FROM reg_errores
ORDER BY id_error;