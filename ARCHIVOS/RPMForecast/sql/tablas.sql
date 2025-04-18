DROP TABLE IF EXISTS previsiones;

CREATE TABLE previsiones(
	periodo VARCHAR(6),
	serie VARCHAR(50),
	valor DECIMAL(38,2),
	es_prediccion VARCHAR(1),
	modelo VARCHAR(20)
);

DROP TABLE IF EXISTS indicadores;

CREATE TABLE indicadores(
	periodo VARCHAR(6),
	serie VARCHAR(50),
	valor DECIMAL(38,2)
);

--COPY indicadores FROM 'D:/dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF-8';

--SELECT * FROM indicadores;