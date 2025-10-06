ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

BEGIN EXECUTE IMMEDIATE 'DROP TABLE detalle_venta PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE venta PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE vendedor PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE administrativo PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE producto PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE proveedor PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE comuna PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE marca PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE categoria PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE medio_pago PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE empleado PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE salud PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE afp PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE region PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE region (
  id_region   NUMBER(4),
  nom_region  VARCHAR2(255) NOT NULL,
  CONSTRAINT REGION_PK PRIMARY KEY (id_region)
);

CREATE TABLE comuna (
  id_comuna   NUMBER(6),
  nom_comuna  VARCHAR2(100) NOT NULL,
  cod_region  NUMBER(4) NOT NULL,
  CONSTRAINT COMUNA_PK PRIMARY KEY (id_comuna),
  CONSTRAINT COMUNA_FK_REGION FOREIGN KEY (cod_region) REFERENCES region(id_region)
);

CREATE TABLE proveedor (
  id_proveedor     NUMBER(5),
  nombre_proveedor VARCHAR2(150) NOT NULL,
  rut_proveedor    VARCHAR2(10),
  telefono         VARCHAR2(10),
  email            VARCHAR2(200) NOT NULL,
  direccion        VARCHAR2(200),
  cod_comuna       NUMBER(6) NOT NULL,
  CONSTRAINT PROVEEDOR_PK PRIMARY KEY (id_proveedor),
  CONSTRAINT PROVEEDOR_FK_COMUNA FOREIGN KEY (cod_comuna) REFERENCES comuna(id_comuna)
);

CREATE TABLE marca (
  id_marca     NUMBER(3),
  nombre_marca VARCHAR2(25) NOT NULL,
  CONSTRAINT MARCA_PK PRIMARY KEY (id_marca)
);

CREATE TABLE categoria (
  id_categoria     NUMBER(3),
  nombre_categoria VARCHAR2(255) NOT NULL,
  CONSTRAINT CATEGORIA_PK PRIMARY KEY (id_categoria)
);

CREATE TABLE afp (
  id_afp  NUMBER(5),
  nom_afp VARCHAR2(255) NOT NULL,
  CONSTRAINT AFP_PK PRIMARY KEY (id_afp)
);

CREATE TABLE salud (
  id_salud  NUMBER(4),
  nom_salud VARCHAR2(40) NOT NULL,
  CONSTRAINT SALUD_PK PRIMARY KEY (id_salud)
);

CREATE TABLE empleado (
  id_empleado         NUMBER(4),
  rut_empleado        VARCHAR2(10),
  nombre_empleado     VARCHAR2(25) NOT NULL,
  apellido_paterno    VARCHAR2(25) NOT NULL,
  apellido_materno    VARCHAR2(25),
  fecha_contratacion  DATE,
  sueldo_base         NUMBER(10) NOT NULL,
  bono_jefatura       NUMBER(10),
  activo              CHAR(1) DEFAULT 'S' NOT NULL,
  tipo_empleado       VARCHAR2(25),
  cod_empleado        NUMBER(4),
  cod_salud           NUMBER(4) NOT NULL,
  cod_afp             NUMBER(5) NOT NULL,
  CONSTRAINT EMPLEADO_PK PRIMARY KEY (id_empleado),
  CONSTRAINT EMPLEADO_FK_SALUD    FOREIGN KEY (cod_salud) REFERENCES salud(id_salud),
  CONSTRAINT EMPLEADO_FK_AFP      FOREIGN KEY (cod_afp)   REFERENCES afp(id_afp),
  CONSTRAINT EMPLEADO_FK_EMPLEADO FOREIGN KEY (cod_empleado) REFERENCES empleado(id_empleado)
);

CREATE TABLE vendedor (
  id_empleado    NUMBER(4),
  comision_venta NUMBER(5,2),
  CONSTRAINT VENDEDOR_PK PRIMARY KEY (id_empleado),
  CONSTRAINT VENDEDOR_FK_EMPLEADO FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

CREATE TABLE administrativo (
  id_empleado NUMBER(4),
  CONSTRAINT ADMINISTRATIVO_PK PRIMARY KEY (id_empleado),
  CONSTRAINT ADMIN_FK_EMPLEADO FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

CREATE TABLE medio_pago (
  id_mpago     NUMBER(3),
  nombre_mpago VARCHAR2(50) NOT NULL,
  CONSTRAINT MEDIO_PAGO_PK PRIMARY KEY (id_mpago)
);

CREATE TABLE producto (
  id_producto      NUMBER(4),
  nombre_producto  VARCHAR2(100) NOT NULL,
  precio_unitario  NUMBER(10,2) NOT NULL,
  origen_nacional  CHAR(1) NOT NULL,
  stock_minimo     NUMBER(3) NOT NULL,
  activo           CHAR(1) DEFAULT 'S' NOT NULL,
  cod_marca        NUMBER(3) NOT NULL,
  cod_categoria    NUMBER(3) NOT NULL,
  cod_proveedor    NUMBER(5) NOT NULL,
  CONSTRAINT PRODUCTO_PK PRIMARY KEY (id_producto),
  CONSTRAINT PRODUCTO_FK_MARCA     FOREIGN KEY (cod_marca)     REFERENCES marca(id_marca),
  CONSTRAINT PRODUCTO_FK_CATEGORIA FOREIGN KEY (cod_categoria) REFERENCES categoria(id_categoria),
  CONSTRAINT PRODUCTO_FK_PROVEEDOR FOREIGN KEY (cod_proveedor) REFERENCES proveedor(id_proveedor)
);

CREATE TABLE venta (
  id_venta     NUMBER(4),
  fecha_venta  DATE DEFAULT SYSDATE NOT NULL,
  cod_mpago    NUMBER(3) NOT NULL,
  cod_empleado NUMBER(4) NOT NULL,
  CONSTRAINT VENTA_PK PRIMARY KEY (id_venta),
  CONSTRAINT VENTA_FK_EMPLEADO   FOREIGN KEY (cod_empleado) REFERENCES empleado(id_empleado),
  CONSTRAINT VENTA_FK_MEDIO_PAGO FOREIGN KEY (cod_mpago)    REFERENCES medio_pago(id_mpago)
);

CREATE TABLE detalle_venta (
  cod_venta    NUMBER(4),
  cod_producto NUMBER(4),
  cantidad     NUMBER(4) NOT NULL,
  CONSTRAINT DETALLE_VENTA_PK PRIMARY KEY (cod_venta, cod_producto),
  CONSTRAINT DET_VENTA_FK_VENTA    FOREIGN KEY (cod_venta)    REFERENCES venta(id_venta),
  CONSTRAINT DET_VENTA_FK_PRODUCTO FOREIGN KEY (cod_producto) REFERENCES producto(id_producto)
);

ALTER TABLE empleado
  ADD CONSTRAINT CK_EMPLEADO_ACTIVO CHECK (activo IN ('S','N'));

ALTER TABLE empleado
  ADD CONSTRAINT CK_EMPLEADO_SUELDO CHECK (sueldo_base >= 400000);

ALTER TABLE empleado
  ADD CONSTRAINT CK_EMPLEADO_TIPO CHECK (tipo_empleado IN ('VENDEDOR','ADMINISTRATIVO'));

ALTER TABLE vendedor
  ADD CONSTRAINT CK_VENDEDOR_COMISION CHECK (comision_venta BETWEEN 0 AND 0.25);

ALTER TABLE producto
  ADD CONSTRAINT CK_PRODUCTO_STOCK CHECK (stock_minimo >= 3);

ALTER TABLE producto
  ADD CONSTRAINT CK_PRODUCTO_ACTIVO CHECK (activo IN ('S','N'));

ALTER TABLE producto
  ADD CONSTRAINT CK_PRODUCTO_ORIGEN CHECK (origen_nacional IN ('S','N'));

ALTER TABLE proveedor
  ADD CONSTRAINT UN_PROVEEDOR_EMAIL UNIQUE (email);

ALTER TABLE marca
  ADD CONSTRAINT UN_MARCA_NOMBRE UNIQUE (nombre_marca);

ALTER TABLE categoria
  ADD CONSTRAINT UN_CATEGORIA_NOMBRE UNIQUE (nombre_categoria);

ALTER TABLE medio_pago
  ADD CONSTRAINT UN_MEDIO_PAGO UNIQUE (nombre_mpago);

ALTER TABLE detalle_venta
  ADD CONSTRAINT CK_DETALLE_CANTIDAD CHECK (cantidad >= 1);

INSERT INTO region (id_region, nom_region) VALUES (13, 'Los Rios');

INSERT INTO comuna (id_comuna, nom_comuna, cod_region)
VALUES (13101, 'Valdivia', 13);

INSERT INTO proveedor (id_proveedor, nombre_proveedor, rut_proveedor, telefono, email, direccion, cod_comuna)
VALUES (100, 'Distribuidora Sur', '76123456-7', '6321234567', 'contacto@distsur.cl', 'Av. Central 123', 13101);

INSERT INTO marca (id_marca, nombre_marca) VALUES (101, 'Alerce');

INSERT INTO categoria (id_categoria, nombre_categoria) VALUES (10, 'Lacteos');
INSERT INTO categoria (id_categoria, nombre_categoria) VALUES (20, 'Aseo');

INSERT INTO afp (id_afp, nom_afp) VALUES (210, 'Provida');
INSERT INTO afp (id_afp, nom_afp) VALUES (216, 'Habitat');

INSERT INTO salud (id_salud, nom_salud) VALUES (2050, 'Fonasa');
INSERT INTO salud (id_salud, nom_salud) VALUES (2060, 'Colmena');

INSERT INTO empleado (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno,
                      fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado,
                      cod_empleado, cod_salud, cod_afp)
VALUES (750, '12345678-9', 'Marta', 'Rios', NULL, SYSDATE, 650000, 50000, 'S', 'VENDEDOR',
        NULL, 2050, 210);

INSERT INTO empleado (id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno,
                      fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado,
                      cod_empleado, cod_salud, cod_afp)
VALUES (753, '98765432-1', 'Diego', 'Lagos', 'Vera', SYSDATE, 520000, NULL, 'S', 'ADMINISTRATIVO',
        750, 2060, 216);

INSERT INTO vendedor (id_empleado, comision_venta) VALUES (750, 0.10);
INSERT INTO administrativo (id_empleado) VALUES (753);

INSERT INTO medio_pago (id_mpago, nombre_mpago) VALUES (1, 'Efectivo');
INSERT INTO medio_pago (id_mpago, nombre_mpago) VALUES (2, 'Tarjeta');

INSERT INTO producto (id_producto, nombre_producto, precio_unitario, origen_nacional, stock_minimo, activo,
                      cod_marca, cod_categoria, cod_proveedor)
VALUES (100, 'Leche Entera 1L', 1190.00, 'S', 5, 'S', 101, 10, 100);

INSERT INTO producto (id_producto, nombre_producto, precio_unitario, origen_nacional, stock_minimo, activo,
                      cod_marca, cod_categoria, cod_proveedor)
VALUES (101, 'Detergente 1kg', 1990.00, 'N', 3, 'S', 101, 20, 100);

INSERT INTO venta (id_venta, fecha_venta, cod_mpago, cod_empleado)
VALUES (5050, SYSDATE, 1, 750);

INSERT INTO detalle_venta (cod_venta, cod_producto, cantidad)
VALUES (5050, 100, 2);

INSERT INTO detalle_venta (cod_venta, cod_producto, cantidad)
VALUES (5050, 101, 1);

COMMIT;

-- Informe 1
SELECT
  e.id_empleado AS "IDENTIFICADOR",
  e.nombre_empleado || ' ' || e.apellido_paterno || ' ' || NVL(e.apellido_materno,'') AS "NOMBRE COMPLETO",
  e.sueldo_base AS "SALARIO",
  e.bono_jefatura AS "BONIFICACION",
  (e.sueldo_base + e.bono_jefatura) AS "SALARIO SIMULADO"
FROM empleado e
WHERE e.activo = 'S'
  AND e.bono_jefatura IS NOT NULL
ORDER BY "SALARIO SIMULADO" DESC, e.apellido_paterno DESC;

-- Informe 2 
SELECT
  e.nombre_empleado || ' ' || e.apellido_paterno || ' ' || NVL(e.apellido_materno,'') AS "EMPLEADO",
  e.sueldo_base AS "SUELDO",
  '8%' AS "POSIBLE AUMENTO",
  (e.sueldo_base * 1.08) AS "SALARIO SIMULADO"
FROM empleado e
WHERE e.sueldo_base BETWEEN 550000 AND 800000
ORDER BY e.sueldo_base ASC;
