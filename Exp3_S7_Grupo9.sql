
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';


-- CASo1


-- Sinonimos privados 
----------------------------------------------
CREATE OR REPLACE SYNONYM syn_trabajador      FOR trabajador;
CREATE OR REPLACE SYNONYM syn_bono_antiguedad FOR bono_antiguedad;
CREATE OR REPLACE SYNONYM syn_tickets         FOR tickets_concierto;


DELETE FROM detalle_bonificaciones_trabajador;


INSERT INTO detalle_bonificaciones_trabajador (
    num,
    rut,
    nombre_trabajador,
    sueldo_base,
    num_ticket,
    direccion,
    sistema_salud,
    monto,
    bonif_x_ticket,
    simulacion_x_ticket,
    simulacion_antiguedad
)
SELECT
    seq_det_bonif.NEXTVAL                                     AS num,
    -- RUT
    SUBSTR(LPAD(TO_CHAR(b.numrut), 8, '0'), 1, 2) || '.' ||
    SUBSTR(LPAD(TO_CHAR(b.numrut), 8, '0'), 3, 3) || '.' ||
    SUBSTR(LPAD(TO_CHAR(b.numrut), 8, '0'), 6, 3) || '-' ||
    b.dvrut                                                   AS rut,
    -- Nombre completo
    INITCAP(b.nombre || ' ' || b.appaterno || ' ' ||
            b.apmaterno)                                      AS nombre_trabajador,
    -- Sueldo base
    TO_CHAR(b.sueldo_base,
            'FM$999G999G999')                                 AS sueldo_base,
    -- Numero de tickets (o el mensaje)
    CASE
        WHEN b.cant_tickets = 0 THEN 'No hay info'
        ELSE TO_CHAR(b.cant_tickets)
    END                                                       AS num_ticket,
    --    Direccion
    INITCAP(b.direccion)                                      AS direccion,
    -- Sistema de salud
    b.sistema_salud                                           AS sistema_salud,
    -- Monto total de tickets ( 0 cuando no hay)
    TO_CHAR(b.monto_tickets,
            'FM$999G999G999')                                 AS monto,
    -- Bonificacion por tickets
    TO_CHAR(b.bonif_ticket_num,
            'FM$999G999G999')                                 AS bonif_x_ticket,
    -- Simulacion por ticket = sueldo + bonificacion
    TO_CHAR(
        ROUND(b.sueldo_base + b.bonif_ticket_num),
        'FM$999G999G999'
    )                                                         AS simulacion_x_ticket,
    -- Simulacion  por antiguedad
    TO_CHAR(b.simul_antig_num,
            'FM$999G999G999')                                 AS simulacion_antiguedad
FROM (
    -- Base por trabajador: tickets, salud y su antiguedad
    SELECT
        t.numrut,
        t.dvrut,
        t.appaterno,
        t.apmaterno,
        t.nombre,
        t.direccion,
        i.nombre_isapre                        AS sistema_salud,
        t.sueldo_base,
        NVL(ba.porcentaje, 0)                  AS porc_antig,
        COUNT(tc.nro_ticket)                   AS cant_tickets,
        -- Total de tickets (0 cuando no hay)
        ROUND(NVL(SUM(tc.monto_ticket), 0))    AS monto_tickets,
    -- Bonificacion numerica por ticket
        ROUND(
            CASE
                WHEN NVL(SUM(tc.monto_ticket), 0) <= 50000
                    THEN 0
                WHEN NVL(SUM(tc.monto_ticket), 0) <= 100000
                    THEN NVL(SUM(tc.monto_ticket), 0) * 0.05
                ELSE
                    NVL(SUM(tc.monto_ticket), 0) * 0.07
            END
        )                                      AS bonif_ticket_num,
        -- Simulacion numerica por  antiguedadd
        ROUND(
            t.sueldo_base * (1 + NVL(ba.porcentaje, 0))
        )                                      AS simul_antig_num
    FROM (
        -- Trabajadores con años de antiguedad calculados
        SELECT
            tr.numrut,
            tr.dvrut,
            tr.appaterno,
            tr.apmaterno,
            tr.nombre,
            tr.direccion,
            tr.fecnac,
            tr.fecing,
            tr.sueldo_base,
            tr.cod_isapre,
            TRUNC(
                MONTHS_BETWEEN(TRUNC(SYSDATE), tr.fecing) / 12
            )                                 AS anios_antig
        FROM syn_trabajador tr
    ) t
    --Tickets : LEFT JOIN para asi incluir a los trabajadores sin tickets
    LEFT JOIN syn_tickets tc
           ON tc.numrut_t = t.numrut
    -- Bono por antiguedad:  NonEquiJoin por rango de años
    LEFT JOIN syn_bono_antiguedad ba
           ON t.anios_antig BETWEEN ba.limite_inferior
                               AND ba.limite_superior
    ---  Sistema de salud
    JOIN isapre i
      ON i.cod_isapre = t.cod_isapre
    -- Filtros de negocio:
    --   - Descuento de salud > 4%
    --   - Menores de 50 años
    WHERE i.porc_descto_isapre > 4
      AND t.fecnac IS NOT NULL
      AND TRUNC(
            MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecnac) / 12
          ) < 50
    GROUP BY
        t.numrut,
        t.dvrut,
        t.appaterno,
        t.apmaterno,
        t.nombre,
        t.direccion,
        i.nombre_isapre,
        t.sueldo_base,
        NVL(ba.porcentaje, 0)
) b;

-----------------------------------------------
--- 4) Comprobacion de filas insertadas
------------------------------------------------
SELECT COUNT(*) AS FILAS_EN_DETALLE
FROM detalle_bonificaciones_trabajador;

------------------------------------------------
-- 5) Reporte   del Caso 1
------------------------------------------------
SELECT
    num                   AS "NUM",
    rut                   AS "RUT",
    nombre_trabajador     AS "NOMBRE_TRABAJADOR",
    sueldo_base           AS "SUELDO_BASE",
    num_ticket            AS "NUM_TICKET",
    direccion             AS "DIRECCION",
    sistema_salud         AS "SISTEMA_SALUD",
    monto                 AS "MONTO",
    bonif_x_ticket        AS "BONIF_X_TICKET",
    simulacion_x_ticket   AS "SIMULACION_X_TICKET",
    simulacion_antiguedad AS "SIMULACION_ANTIGUEDAD"
FROM detalle_bonificaciones_trabajador
ORDER BY
    monto DESC,
    nombre_trabajador ASC;




-- CASO 2

------------------------------------------------
-- 1) Sinonimos privados que use 
--    (TRABAJADOR y BONO_ESCOLAR)
------------------------------------------------
CREATE OR REPLACE SYNONYM syn_trabajador   FOR trabajador;
CREATE OR REPLACE SYNONYM syn_bono_escolar FOR bono_escolar;

------------------------------------------------
-- 2) vista  V_AUMENTOS_ESTUDIOS

------------------------------------------------
CREATE OR REPLACE VIEW v_aumentos_estudios AS
SELECT
    -- RUT  
    SUBSTR(LPAD(TO_CHAR(t.numrut), 8, '0'), 1, 2) || '.' ||
    SUBSTR(LPAD(TO_CHAR(t.numrut), 8, '0'), 3, 3) || '.' ||
    SUBSTR(LPAD(TO_CHAR(t.numrut), 8, '0'), 6, 3) || '-' ||
    t.dvrut                                                   AS rut_trabajador,
    -- Nombre completo
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' ||
            t.apmaterno)                                      AS trabajador,
    ---- Nivel  de estudios
    be.descrip                                                AS descrip,
    -- Porcentaje de bono de estudio
    LPAD(TO_CHAR(be.porc_bono), 6, '0')                       AS pct_estudios,
    --- Sueldo actual 
    t.sueldo_base                                             AS sueldo_actual,
    -- Aumento segun porcentaje de estudios
    ROUND(t.sueldo_base * (be.porc_bono / 100))               AS aumento,
    -- Sueldo aumentado 
    TO_CHAR(
        t.sueldo_base
        + ROUND(t.sueldo_base * (be.porc_bono / 100)),
        'FM$999G999G999'
    )                                                         AS sueldo_aumentado
FROM syn_trabajador t
JOIN syn_bono_escolar be
  ON be.id_escolar = t.id_escolaridad_t
JOIN tipo_trabajador tt
  ON tt.id_categoria = t.id_categoria_t
LEFT JOIN (
    --  Subconsulta con GROUP BY para contar las cargas por trabajador
    SELECT
        numrut_t,
        COUNT(*) AS cant_cargas
    FROM asignacion_familiar
    GROUP BY numrut_t
) af
  ON af.numrut_t = t.numrut
WHERE
      tt.desc_categoria = 'CAJERO'              --- todos los cajeros
   OR NVL(af.cant_cargas, 0) BETWEEN 1 AND 2;   -- o  trabajadores con 1 o 2 cargas


 ------------------------------------------------
--  Consulta  caso 2
 
------------------------------ ---------------
SELECT
    rut_trabajador,
    trabajador,
    descrip,
    pct_estudios,
    sueldo_actual,
    aumento,
    sueldo_aumentado
FROM v_aumentos_estudios
ORDER BY
    pct_estudios ASC,
    trabajador   ASC;



/* =============================
   CASO 2 - Etapa 2: indices
    ================================ */

------------------------------------------------
--  Indice B-Tree sobre  (APMATERNO

------------------------------------------------
CREATE INDEX idx_trabajador_apm
    ON trabajador (apmaterno);

------------------------------------------------
--  Indice function-based para UPPER( APMATERNO)
------------------------------------------------
CREATE INDEX idx_trabajador_apm_2
    ON trabajador (UPPER(apmaterno));

------------------------------------------------
--  Consulta sin UPPER (idx_trabajador_apm)
------------------------------------------------
SELECT
    t.numrut,
    t.fecnac,
    t.nombre,
    t.appaterno,
    t.apmaterno
FROM trabajador t
JOIN isapre i
  ON i.cod_isapre = t.cod_isapre
WHERE t.apmaterno = 'CASTILLO'
ORDER BY 3;

------------------------------------------------
--  Consulta con UPPER ( se usa idx_trabajador_apm_2)
------------------------------------------------
SELECT
    t.numrut,
    t.fecnac,
    t.nombre,
    t.appaterno,
    t.apmaterno
FROM trabajador t
JOIN isapre i
  ON i.cod_isapre = t.cod_isapre
WHERE UPPER(t.apmaterno) = 'CASTILLO'
ORDER BY 3;

