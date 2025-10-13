-- =========================================================
-- COMPUTEC - Base de datos + Stored Procedures (MySQL 8)
-- Script inicial con datos de ejemplo (mitad marcas reales / mitad modelos ficticios)
-- =========================================================

DROP DATABASE IF EXISTS computec_db;
CREATE DATABASE computec_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE computec_db;

-- ======================
-- Tablas
-- ======================
CREATE TABLE clientes (
  rut        VARCHAR(12)  NOT NULL,
  nombre     VARCHAR(100) NOT NULL,
  direccion  VARCHAR(150) NOT NULL,
  comuna     VARCHAR(80)  NOT NULL,
  email      VARCHAR(120) NOT NULL,
  telefono   VARCHAR(20)  NOT NULL,
  PRIMARY KEY (rut),
  UNIQUE KEY uq_clientes_email (email)
) ENGINE=InnoDB;

CREATE TABLE equipos (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  modelo     VARCHAR(120) NOT NULL,
  cpu        VARCHAR(120) NOT NULL,
  disco_mb   INT          NOT NULL CHECK (disco_mb > 0),
  ram_gb     INT          NOT NULL CHECK (ram_gb > 0),
  precio     DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  tipo       ENUM('desktop','laptop') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE equipos_desktop (
  id_equipo      INT PRIMARY KEY,
  fuente_watts   INT NOT NULL CHECK (fuente_watts > 0),
  factor_forma   ENUM('atx','eatx','microatx','itx','otro') NOT NULL,
  CONSTRAINT fk_desk_equipo FOREIGN KEY (id_equipo) REFERENCES equipos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE equipos_laptop (
  id_equipo     INT PRIMARY KEY,
  pantalla_pulg DECIMAL(4,1) NOT NULL CHECK (pantalla_pulg > 0),
  touch         TINYINT(1)   NOT NULL,
  puertos_usb   INT          NOT NULL CHECK (puertos_usb >= 0),
  CONSTRAINT fk_lap_equipo FOREIGN KEY (id_equipo) REFERENCES equipos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ventas (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  rut_cliente  VARCHAR(12) NOT NULL,
  id_equipo    INT NOT NULL,
  fecha_hora   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  precio_final DECIMAL(12,2) NOT NULL CHECK (precio_final >= 0),
  CONSTRAINT fk_vta_cli FOREIGN KEY (rut_cliente) REFERENCES clientes(rut),
  CONSTRAINT fk_vta_eq  FOREIGN KEY (id_equipo)   REFERENCES equipos(id),
  CONSTRAINT uq_vta_equipo UNIQUE (id_equipo)
) ENGINE=InnoDB;

CREATE INDEX ix_clientes_nombre   ON clientes(nombre);
CREATE INDEX ix_equipos_tipo      ON equipos(tipo);
CREATE INDEX ix_ventas_rut        ON ventas(rut_cliente);

-- ======================
-- Stored Procedures
-- ======================
DELIMITER $$

CREATE PROCEDURE sp_cliente_insert(
  IN p_rut VARCHAR(12), IN p_nombre VARCHAR(100),
  IN p_direccion VARCHAR(150), IN p_comuna VARCHAR(80),
  IN p_email VARCHAR(120), IN p_telefono VARCHAR(20)
)
BEGIN
  INSERT INTO clientes(rut,nombre,direccion,comuna,email,telefono)
  VALUES (p_rut,p_nombre,p_direccion,p_comuna,p_email,p_telefono);
END$$

CREATE PROCEDURE sp_cliente_update(
  IN p_rut VARCHAR(12), IN p_nombre VARCHAR(100),
  IN p_direccion VARCHAR(150), IN p_comuna VARCHAR(80),
  IN p_email VARCHAR(120), IN p_telefono VARCHAR(20)
)
BEGIN
  UPDATE clientes
  SET nombre=p_nombre, direccion=p_direccion, comuna=p_comuna,
      email=p_email, telefono=p_telefono
  WHERE rut=p_rut;
END$$

CREATE PROCEDURE sp_cliente_delete(IN p_rut VARCHAR(12))
BEGIN
  DELETE FROM clientes WHERE rut=p_rut;
END$$

CREATE PROCEDURE sp_cliente_get(IN p_rut VARCHAR(12))
BEGIN
  SELECT rut,nombre,direccion,comuna,email,telefono
  FROM clientes WHERE rut=p_rut;
END$$

CREATE PROCEDURE sp_cliente_list()
BEGIN
  SELECT rut,nombre,direccion,comuna,email,telefono
  FROM clientes
  ORDER BY nombre;
END$$

CREATE PROCEDURE sp_equipo_insert_desktop(
  IN p_modelo VARCHAR(120), IN p_cpu VARCHAR(120),
  IN p_disco INT, IN p_ram INT, IN p_precio DECIMAL(12,2),
  IN p_fuente INT, IN p_factor VARCHAR(10),
  OUT p_id INT
)
BEGIN
  INSERT INTO equipos(modelo,cpu,disco_mb,ram_gb,precio,tipo)
  VALUES (p_modelo,p_cpu,p_disco,p_ram,p_precio,'desktop');
  SET p_id = LAST_INSERT_ID();
  INSERT INTO equipos_desktop(id_equipo,fuente_watts,factor_forma)
  VALUES (p_id,p_fuente,p_factor);
END$$

CREATE PROCEDURE sp_equipo_insert_laptop(
  IN p_modelo VARCHAR(120), IN p_cpu VARCHAR(120),
  IN p_disco INT, IN p_ram INT, IN p_precio DECIMAL(12,2),
  IN p_pantalla DECIMAL(4,1), IN p_touch TINYINT(1), IN p_usb INT,
  OUT p_id INT
)
BEGIN
  INSERT INTO equipos(modelo,cpu,disco_mb,ram_gb,precio,tipo)
  VALUES (p_modelo,p_cpu,p_disco,p_ram,p_precio,'laptop');
  SET p_id = LAST_INSERT_ID();
  INSERT INTO equipos_laptop(id_equipo,pantalla_pulg,touch,puertos_usb)
  VALUES (p_id,p_pantalla,p_touch,p_usb);
END$$

CREATE PROCEDURE sp_equipo_list(IN p_tipo VARCHAR(10))
BEGIN
  IF p_tipo IS NULL OR p_tipo = '' OR p_tipo = 'todos' THEN
    SELECT * FROM equipos ORDER BY id DESC;
  ELSE
    SELECT * FROM equipos WHERE tipo=p_tipo ORDER BY id DESC;
  END IF;
END$$

CREATE PROCEDURE sp_venta_insert(
  IN p_rut VARCHAR(12),
  IN p_id_equipo INT,
  IN p_precio_final DECIMAL(12,2),
  OUT p_id_venta INT
)
BEGIN
  INSERT INTO ventas(rut_cliente,id_equipo,precio_final)
  VALUES (p_rut,p_id_equipo,p_precio_final);
  SET p_id_venta = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_reporte_listado(IN p_tipo VARCHAR(10))
BEGIN
  SELECT e.id, e.modelo, e.cpu, e.ram_gb, e.disco_mb, e.precio, e.tipo,
         c.rut, c.nombre AS cliente, c.telefono, c.email,
         v.id AS id_venta, v.fecha_hora, v.precio_final
  FROM ventas v
  JOIN clientes c ON c.rut = v.rut_cliente
  JOIN equipos  e ON e.id  = v.id_equipo
  WHERE (p_tipo IS NULL OR p_tipo='' OR p_tipo='todos' OR e.tipo = p_tipo)
  ORDER BY v.id DESC;
END$$

CREATE PROCEDURE sp_reporte_resumen()
BEGIN
  SELECT COUNT(*) AS cantidad, IFNULL(SUM(precio_final),0) AS total
  FROM ventas;
END$$

DELIMITER ;

-- ======================
-- Datos de ejemplo
-- ======================
-- Clientes
INSERT INTO clientes(rut,nombre,direccion,comuna,email,telefono) VALUES
('11.111.111-1','Ana Pérez','Av. Uno 123','Santiago','ana@correo.com','+56 9 11111111'),
('22.222.222-2','Bruno Díaz','Calle Dos 456','Ñuñoa','bruno@correo.com','+56 9 22222222'),
('33.333.333-3','Carla Soto','Calle Tres 789','Providencia','carla@correo.com','+56 9 33333333'),
('44.444.444-4','Diego Mora','Calle Cuatro 321','Maipú','diego@correo.com','+56 9 44444444'),
('55.555.555-5','Elisa Rivas','Calle Cinco 654','La Florida','elisa@correo.com','+56 9 55555555');

-- Equipos (mitad marcas reales, mitad ficticios)
-- Desktop (reales / ficticios)
CALL sp_equipo_insert_desktop('MSI MAG Infinite S3','Intel i5-12400F',1024000,16,899990,650,'atx', @id_d1);
CALL sp_equipo_insert_desktop('HP OMEN 40L','AMD Ryzen 7 5700X',1024000,16,1299990,750,'atx', @id_d2);
CALL sp_equipo_insert_desktop('PC Gamer A123','Ryzen 5 5600',1024000,16,799990,650,'atx', @id_d3);
CALL sp_equipo_insert_desktop('Workstation Pro W900','Ryzen 9 7900',2048000,64,1599990,750,'atx', @id_d4);
CALL sp_equipo_insert_desktop('MiniPC M100','Intel N100',256000,8,229990,250,'itx', @id_d5);

-- Laptop (reales / ficticios)
CALL sp_equipo_insert_laptop('ASUS TUF Gaming A15','AMD Ryzen 7 6800H',1024000,16,1099990,15.6,0,3, @id_l1);
CALL sp_equipo_insert_laptop('Lenovo ThinkPad E14','Intel i5-1235U',512000,16,799990,14.0,0,2, @id_l2);
CALL sp_equipo_insert_laptop('Ultrabook Premium U900','Intel i7-1360P',512000,16,1099990,14.0,0,2, @id_l3);
CALL sp_equipo_insert_laptop('Notebook Estudiante L100','Ryzen 5 5500U',256000,8,349990,15.6,0,3, @id_l4);
CALL sp_equipo_insert_laptop('Acer Nitro 5 AN515','Intel i7-12700H',1024000,16,1199990,15.6,0,3, @id_l5);

-- Venta inicial para reportes
CALL sp_venta_insert('11.111.111-1', @id_d1, 869990.00, @id_v1);

-- selecs/call para confirmar mis datos
-- SELECT * FROM clientes;
-- SELECT * FROM equipos;
   -- SELECT * FROM equipos_desktop;  fuente y factor de forma
-- SELECT * FROM equipos_laptop;
-- SELECT * FROM ventas;
-- CALL sp_equipo_list('todos');
-- CALL sp_reporte_listado('todos');
-- CALL sp_reporte_resumen();