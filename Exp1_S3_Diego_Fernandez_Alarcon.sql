
-- Nombre: Diego Ignacio Fernandez Alarcon


-------------------------------------------------------
-- CASO 1: 
--------------------------------------------------------
SELECT
    -- RUT 
    SUBSTR(LPAD(TO_CHAR(numrut_cli), 8, '0'), 1, 2) || '.' ||
    SUBSTR(LPAD(TO_CHAR(numrut_cli), 8, '0'), 3, 3) || '.' ||
    SUBSTR(LPAD(TO_CHAR(numrut_cli), 8, '0'), 6, 3) || '-' ||
    dvrut_cli                                   AS "RUT Cliente",

    -- Nombre completo
    INITCAP(
        nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli
    )                                           AS "Nombre Completo Cliente",

    -- Direccion del cliente
    INITCAP(direccion_cli)                     AS "Direccion Cliente",

    -- Renta 
    TO_CHAR(
        ROUND(renta_cli, 0),
        '$999G999G999'
    )                                           AS "Renta Cliente",

    -- Celular 
    CASE
        WHEN celular_cli IS NULL THEN 'SIN CELULAR'
        ELSE
            SUBSTR(LPAD(TO_CHAR(celular_cli), 9, '0'), 1, 2) || '-' ||
            SUBSTR(LPAD(TO_CHAR(celular_cli), 9, '0'), 3, 3) || '-' ||
            SUBSTR(LPAD(TO_CHAR(celular_cli), 9, '0'), 6, 4)
    END                                         AS "Celular Cliente",

    -- Tramo de renta 
    CASE
        WHEN renta_cli > 500000 THEN 'TRAMO 1'
        WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END                                         AS "Tramo Renta Cliente"

FROM
    cliente
WHERE
        renta_cli BETWEEN TO_NUMBER('&RENTA_MINIMA')
                     AND TO_NUMBER('&RENTA_MAXIMA')
    AND celular_cli IS NOT NULL
ORDER BY
    "Nombre Completo Cliente";
    
--------------------------------------------------------
-- CASO 2: 
---------------------------------------------------
SELECT
    -- Codigo de categoria 
    e.id_categoria_emp                       AS "CODIGO_CATEGORIA",

    -- Descripcion de la categoria (Gerente, Supervisor, etc.)
    INITCAP(c.desc_categoria_emp)            AS "DESCRIPCION_CATEGORIA",

    -- Cantidad de empleados en esa categoria y  sucursal
    COUNT(*)                                 AS "CANTIDAD_EMPLEADOS",

    -- Nombre de  la sucursal
    INITCAP(
        REPLACE(s.desc_sucursal, 'Susursal', 'Sucursal')
    )                                        AS "SUCURSAL",

    -- Sueldo  promedio
    TO_CHAR(
        ROUND(AVG(e.sueldo_emp), 0),
        '$9G999G999G999'
    )                                        AS "SUELDO_PROMEDIO"

FROM
    empleado e
    JOIN categoria_empleado c ON e.id_categoria_emp = c.id_categoria_emp
    JOIN sucursal          s ON e.id_sucursal      = s.id_sucursal

GROUP BY
    e.id_categoria_emp,
    c.desc_categoria_emp,
    s.desc_sucursal

HAVING
    AVG(e.sueldo_emp) > TO_NUMBER('&SUELDO_PROMEDIO_MINIMO')

ORDER BY
    AVG(e.sueldo_emp) DESC;



----------------------------------------------------
-- CASO 3:
--------------------------------------------------------
SELECT
    -- Codigo del tipo de propiedad (A, B, C, D, E)
    p.id_tipo_propiedad                         AS CODIGO_TIPO,

    -- Descripcion del tipo
    UPPER(t.desc_tipo_propiedad)                AS DESCRIPCION_TIPO,

    -- Total de propiedades de ese tipo
    COUNT(*)                                    AS TOTAL_PROPIEDADES,

    -- Promedio de valor de arriendo 
    TO_CHAR(
        ROUND(AVG(p.valor_arriendo), 0),
        '$9G999G999G999'
    )                                           AS PROMEDIO_ARRIENDO,

    -- Promedio de superficie 
    TO_CHAR(
        ROUND(AVG(p.superficie), 2),
        '999G990D99'
    )                                           AS PROMEDIO_SUPERFICIE,

    -- Valor de arriendo promedio por m2 (promedio_arriendo / promedio_superficie)
    TO_CHAR(
        ROUND(AVG(p.valor_arriendo) / AVG(p.superficie), 0),
        '$99G999'
    )                                           AS VALOR_ARRIENDO_M2,

    -- Clasificacion segun valor de arriendo por m2
    CASE
        WHEN (AVG(p.valor_arriendo) / AVG(p.superficie)) < 5000
            THEN 'Económico'
        WHEN (AVG(p.valor_arriendo) / AVG(p.superficie)) BETWEEN 5000 AND 10000
            THEN 'Medio'
        ELSE 'Alto'
    END                                         AS CLASIFICACION

FROM
    propiedad      p
    JOIN tipo_propiedad t
        ON p.id_tipo_propiedad = t.id_tipo_propiedad

GROUP BY
    p.id_tipo_propiedad,
    t.desc_tipo_propiedad

HAVING
    -- Solo tipos cuyo promedio de arriendo por m2 sea > 1000
    (AVG(p.valor_arriendo) / AVG(p.superficie)) > 1000

ORDER BY
     -- Ordenado de mayor a menor valor de arriendo por m2
    (AVG(p.valor_arriendo) / AVG(p.superficie)) DESC;
