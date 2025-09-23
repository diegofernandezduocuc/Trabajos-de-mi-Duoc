-- cine_db_gui.sql
DROP DATABASE IF EXISTS Cine_DB;
CREATE DATABASE Cine_DB;
USE Cine_DB;

CREATE TABLE Cartelera (
  id INT NOT NULL AUTO_INCREMENT,
  titulo VARCHAR(150) NOT NULL,
  director VARCHAR(50) NOT NULL,
  anio INT NOT NULL,
  duracion INT NOT NULL,
  genero ENUM('Accion','Comedia','Drama','Romance','Terror','Suspenso','Animacion','Documental') NOT NULL,
  PRIMARY KEY (id),
  CHECK (anio >= 1888),
  CHECK (duracion > 0)
);


INSERT INTO Cartelera (titulo, director, anio, duracion, genero) VALUES
('Parasite', 'Bong Joon-ho', 2019, 132, 'Drama'),
('Spirited Away', 'Hayao Miyazaki', 2001, 125, 'Animacion'),
('Everything Everywhere All at Once', 'Daniel Kwan / Daniel Scheinert', 2022, 139, 'Comedia'),
('Toy Story 3', 'Lee Unkrich', 2010, 103, 'Animacion');


SELECT * FROM Cartelera;