-- Estructura para la BD solar_weather
-- Creación de DataBase
CREATE DATABASE solar_weather;
USE solar_weather;

-- Entorno de seguridad --
-- Crear un usuario de "Analista": Que solo pueda leer, no borrar tablas--
CREATE USER 'analista_solar'@'localhost' IDENTIFIED BY 'PasswordSegura123!';
GRANT SELECT ON solar_weather.vw_analisis_solar TO 'analista_solar'@'localhost';

-- 1. Tablas Padre (Sin dependencias)
CREATE TABLE registro (
  id_registro INTEGER PRIMARY KEY,
  fecha DATETIME,
  hora INT,
  mes INT
)ENGINE=InnoDB;

-- 2. Tablas Intermedias
CREATE TABLE produccion_energetica (
  id_registro INTEGER,
  energia_delta FLOAT,
  FOREIGN KEY (id_registro) REFERENCES registro(id_registro) ON DELETE RESTRICT
)ENGINE=InnoDB;

CREATE TABLE radiacion_solar (
  id_registro INTEGER,
  ghi FLOAT,
  isSun BOOL,
  sunlightTime INT,
  dayLength INT,
  SunlightTimeDay FLOAT,
  FOREIGN KEY (id_registro) REFERENCES registro(id_registro) ON DELETE RESTRICT
)ENGINE=InnoDB;

CREATE TABLE cond_atmosferica (
  id_registro INTEGER,
  temp FLOAT,
  pressure INT,
  humidity INT,
  wind_speed FLOAT,
  FOREIGN KEY (id_registro) REFERENCES registro(id_registro) ON DELETE RESTRICT
)ENGINE=InnoDB;

CREATE TABLE precipitacion_clima (
  id_registro INTEGER,
  rain_1h FLOAT,
  snow_1h FLOAT,
  clouds_all INT,
  weather_type INT,
  FOREIGN KEY (id_registro) REFERENCES registro(id_registro) ON DELETE RESTRICT
)ENGINE=InnoDB;

-- 3. Consulta de ruta Dataset
SHOW VARIABLES LIKE "secure_file_priv";

-- 4. Carga de datos desde el Dataset para la tabla registro
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/registro.csv' 
INTO TABLE registro 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS 
(@var_id_registro, @var_fecha, @var_hora, @var_mes)
SET 
  id_registro = @var_id_registro,
  fecha = STR_TO_DATE(@var_fecha, '%d/%m/%Y %H:%i'),
  hora = @var_hora,
  mes = @var_mes;
  
  -- 5. Carga de datos desde el Dataset para la tabla produccion_energetica
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/produccion_energetica.csv' 
INTO TABLE produccion_energetica
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS
(id_registro, energia_delta);

-- 6. Carga de datos desde el Dataset para la tabla radiacion_solar
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/radiacion_solar.csv' 
INTO TABLE radiacion_solar 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS 
(@var_id_registro, @var_ghi, @var_isSun, @var_sunlight, @var_dayLength, @var_SunlightDay) 
SET 
  id_registro = @var_id_registro,
  ghi = REPLACE(@var_ghi, ',', '.'),
  isSun = @var_isSun,
  sunlightTime = REPLACE(@var_sunlight, ',', '.'),
  dayLength = REPLACE(@var_dayLength, ',', '.'),
  SunlightTimeDay = REPLACE(@var_SunlightDay, ',', '.');
  
  -- 7. Carga de datos desde el Dataset para la tabla cond_atmosferica
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cond_atmosferica.csv' 
INTO TABLE cond_atmosferica 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS 
(@var_id_registro, @v_temp, @v_press, @v_hum, @v_wind)
SET 
  id_registro = @var_id_registro,            
  temp = REPLACE(@v_temp, ',', '.'),  
  pressure = REPLACE(@v_press, ',', '.'),
  humidity = REPLACE(@v_hum, ',', '.'),
  wind_speed = REPLACE(@v_wind, ',', '.');

  -- 8. Carga de datos desde el Dataset para la tabla precipitacion_clima
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/precipitacion_clima.csv' 
INTO TABLE precipitacion_clima 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS 
(@var_id_registro, @v_rain, @v_snow, @v_clouds, @v_weather) 
SET 
  id_registro = @var_id_registro, 
  rain_1h = REPLACE(@v_rain, ',', '.'),    
  snow_1h = REPLACE(@v_snow, ',', '.'),   
  clouds_all = @v_clouds, 
  weather_type = @v_weather;
  
-- 9. Consultas solar_DB
SELECT * FROM registro;
SELECT id_registro FROM registro;

-- Ver tipo de precipitación --
SELECT weather_type
FROM precipitacion_clima
WHERE rain_1h != 0;

-- Uso de Inner Join entre tablas con alias--
SELECT r.id_registro, c.isSun
FROM radiacion_solar c
INNER JOIN registro r ON c.id_registro = r.id_registro;

-- Uso de Join on, order by con limite de registros--
SELECT r.fecha, c.temp, c.humidity
FROM registro r
JOIN cond_atmosferica c ON r.id_registro = c.id_registro
ORDER BY r.fecha DESC
LIMIT 30;

-- Días con lluvia (rain_1h > 0) y su impacto en la producción--
SELECT r.fecha, pr.rain_1h, pe.energia_delta
FROM registro r
JOIN precipitacion_clima pr ON r.id_registro = pr.id_registro
JOIN produccion_energetica pe ON r.id_registro = pe.id_registro
WHERE pr.rain_1h > 0
ORDER BY pr.rain_1h DESC;

-- Uso de union para cuenta de registros totales por tabla--
SELECT 'registro' como_tabla, COUNT(*) total FROM registro
UNION
SELECT 'cond_atmosferica', COUNT(*) FROM cond_atmosferica;

-- Uso de promedio de los datos de temperatura--
SELECT AVG(temp) AS promedio_temperatura
FROM cond_atmosferica;

-- Consulta para determinar qué horas y meses tienen más radiación--
SELECT 
    r.mes, 
    r.hora, 
    AVG(ra.ghi) as promedio_radiacion
FROM registro r
JOIN radiacion_solar ra ON r.id_registro = ra.id_registro
GROUP BY r.mes, r.hora
ORDER BY r.mes, r.hora;

-- Consulta de registros con condicional y operador lògico--
SELECT hora, mes
FROM registro
WHERE id_registro IN (SELECT id_registro FROM cond_atmosferica WHERE wind_speed > 4); 

-- Subconsulta contabla derivada y filtro segùn el total de energìa generada--
SELECT sub.total_energia 
FROM (
    SELECT p.id_registro, SUM(p.energia_delta) AS total_energia 
    FROM produccion_energetica AS p
    GROUP BY p.id_registro
) AS sub 
WHERE sub.total_energia > 1000 
LIMIT 0, 1000;

-- Uso de sentencia CASE para determinar el tipo de clima--
SELECT id_registro, 
    CASE 
        WHEN rain_1h != 0 THEN 'Lluvioso' 
        WHEN snow_1h != 0 THEN 'nevado' 
        WHEN clouds_all != 0 THEN 'nubado' 
        ELSE 'otro' 
    END AS tipo_precipitacion
FROM precipitacion_clima;

-- Inicialización de transacción de actualización de dato--
START TRANSACTION;
UPDATE registro 
SET fecha = STR_TO_DATE('01/01/2017 00:10', '%d/%m/%Y %H:%i') 
WHERE id_registro = 1;
ROLLBACK;
COMMIT;
SELECT * FROM registro;

-- Consulta avanzada para ver la eficiencia (Energía / Radiación) por hora:--
SELECT 
    r.hora, 
    AVG(p.energia_delta) AS avg_energia, 
    AVG(ra.ghi) AS avg_ghi,
    (AVG(p.energia_delta) / NULLIF(AVG(ra.ghi), 0)) AS factor_eficiencia
FROM registro r
JOIN produccion_energetica p ON r.id_registro = p.id_registro
JOIN radiacion_solar ra ON r.id_registro = ra.id_registro
WHERE ra.ghi > 10
GROUP BY r.hora
HAVING avg_ghi > 0
ORDER BY r.hora;

-- Consulta avanzada para ver el estado del cielo--
SELECT 
    CASE 
        WHEN pc.clouds_all < 20 THEN 'Despejado (0-20%)'
        WHEN pc.clouds_all BETWEEN 20 AND 70 THEN 'Nubes Dispersas (20-70%)'
        ELSE 'Nublado (>70%)'
    END AS estado_cielo,
    AVG(p.energia_delta) AS promedio_energia,
    AVG(ra.ghi) AS promedio_ghi
FROM precipitacion_clima pc
JOIN produccion_energetica p ON pc.id_registro = p.id_registro
JOIN radiacion_solar ra ON pc.id_registro = ra.id_registro
GROUP BY estado_cielo;

-- Obtimizacion de la DB solar_weather--

-- Optimización Índices tabla registro--
ALTER TABLE registro ADD INDEX idx_mes_hora (mes, hora);

-- Restricciones para evitar datos fuera de rangos en la temperatura --
ALTER TABLE cond_atmosferica 
ADD CONSTRAINT chk_humidity CHECK (humidity BETWEEN 0 AND 100);

-- creación vista integra de todas las tablas para optimizar consultas y mejorar la seguridad--
CREATE OR REPLACE VIEW vw_analisis_solar AS
SELECT 
    r.id_registro,
    r.fecha,
    r.mes,
    r.hora,
    ra.ghi,
    ra.isSun,
    ca.temp,
    ca.humidity,
    ca.wind_speed,
    pc.rain_1h,
    pc.clouds_all,
    pe.energia_delta,
    CASE 
        WHEN ra.ghi > 0 THEN (pe.energia_delta / ra.ghi)
        ELSE 0 
    END AS eficiencia
FROM registro r
LEFT JOIN radiacion_solar ra ON r.id_registro = ra.id_registro
LEFT JOIN cond_atmosferica ca ON r.id_registro = ca.id_registro
LEFT JOIN precipitacion_clima pc ON r.id_registro = pc.id_registro
LEFT JOIN produccion_energetica pe ON r.id_registro = pe.id_registro;

-- Consulta de prueba tabla virtual--
SELECT * FROM vw_analisis_solar WHERE mes = 6;

-- Optimización de consultas avanzadas --
EXPLAIN SELECT * FROM cond_atmosferica WHERE humidity = '50';
EXPLAIN ANALYZE SELECT * FROM radiacion_solar WHERE ghi >'200';

-- Procedimiento almacenado para consultar el total de comsumo por mes--

DELIMITER //
CREATE PROCEDURE sp_total_produccion_energetica(
    IN p_mes TINYINT,          
    OUT p_total_energia FLOAT
)
BEGIN
    DECLARE v_suma FLOAT;
    SELECT SUM(pe.energia_delta) INTO v_suma
    FROM produccion_energetica pe
    JOIN registro r ON pe.id_registro = r.id_registro
    WHERE r.mes = p_mes;
    SET p_total_energia = IFNULL(v_suma, 0);
END //
DELIMITER ;

-- Llamar el procedimiento sp_total_produccion_energetica--
CALL sp_total_produccion_energetica(6, @resultado);
SELECT @resultado AS Total_Energia_Junio;

-- Uso de pivot para agrupar y consultar el consumo por mes y el año--
SELECT 
    r.hora, 
    SUM(CASE WHEN r.mes = 1 THEN pe.energia_delta ELSE 0 END) AS ENERO,
    SUM(CASE WHEN r.mes = 2 THEN pe.energia_delta ELSE 0 END) AS FEBRERO,
    SUM(CASE WHEN r.mes = 3 THEN pe.energia_delta ELSE 0 END) AS MARZO,
    SUM(CASE WHEN r.mes = 4 THEN pe.energia_delta ELSE 0 END) AS ABRIL,
    SUM(CASE WHEN r.mes = 5 THEN pe.energia_delta ELSE 0 END) AS MAYO,
    SUM(CASE WHEN r.mes = 6 THEN pe.energia_delta ELSE 0 END) AS JUNIO,
    SUM(CASE WHEN r.mes = 7 THEN pe.energia_delta ELSE 0 END) AS JULIO,
    SUM(CASE WHEN r.mes = 8 THEN pe.energia_delta ELSE 0 END) AS AGOSTO,
    SUM(CASE WHEN r.mes = 9 THEN pe.energia_delta ELSE 0 END) AS SEPTIEMBRE,
    SUM(CASE WHEN r.mes = 10 THEN pe.energia_delta ELSE 0 END) AS OCTUBRE,
    SUM(CASE WHEN r.mes = 11 THEN pe.energia_delta ELSE 0 END) AS NOVIEMBRE,
    SUM(CASE WHEN r.mes = 12 THEN pe.energia_delta ELSE 0 END) AS DICIEMBRE,
    SUM(pe.energia_delta) AS TOTAL_ANUAL
FROM registro r
JOIN produccion_energetica pe ON r.id_registro = pe.id_registro
GROUP BY r.hora
ORDER BY r.hora;


-- Tabla de auditoria para registrar cambios en la tablas de producción--
CREATE TABLE log_cambios_energia (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_registro INT,
    valor_anterior FLOAT,
    valor_nuevo FLOAT,
    usuario VARCHAR(50),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER tr_audit_energia
AFTER UPDATE ON produccion_energetica
FOR EACH ROW
BEGIN
    INSERT INTO log_cambios_energia (id_registro, valor_anterior, valor_nuevo, usuario)
    VALUES (OLD.id_registro, OLD.energia_delta, NEW.energia_delta, USER());
END //
DELIMITER ;






