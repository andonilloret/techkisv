/*CREACIÓN DE LA BASE DE DATOS*/
create database isv2;
use isv2;
source Estructura/isv_combi_prod_tb.sql
source Estructura/isv_combi_geo_tb.sql
source Estructura/isv_semanas_tb.sql
/*Por favor dejar isv_semanas_tb_data.sql en la raiz del proyecto*/
source isv_semanas_tb_data.sql

/*REINDEXADO DE LAS TABLAS*/
ALTER TABLE isv_combi_geo_tb modify com_geo_idcom INT NOT NULL;
ALTER TABLE isv_combi_geo_tb drop PRIMARY KEY;
ALTER TABLE isv_combi_prod_tb modify com_prod_idcom INT NOT NULL;
ALTER TABLE isv_combi_prod_tb drop PRIMARY KEY;
ALTER TABLE isv_combi_geo_tb add PRIMARY KEY;( com_geo_agrup_0, com_geo_idcom);
ALTER TABLE isv_combi_prod_tb add PRIMARY KEY;( com_prod_agrup_0, com_prod_idcom);
ALTER TABLE isv_semanas_tb modify can_idcantidad INT NOT NULL;
ALTER TABLE isv_semanas_tb drop PRIMARY KEY;

/*PARTICIONADO*/
ALTER TABLE isv_semanas_tb
PARTITION BY RANGE( YEAR( can_fecha ) )
SUBPARTITION BY HASH ( can_semana )
SUBPARTITIONS 53 (
    PARTITION p0 VALUES LESS THAN (2012),
    PARTITION p1 VALUES LESS THAN (2013),
    PARTITION p2 VALUES LESS THAN (2014),
    PARTITION p3 VALUES LESS THAN (2015),
    PARTITION p4 VALUES LESS THAN (2016),
    PARTITION p5 VALUES LESS THAN (2017),
    PARTITION p6 VALUES LESS THAN MAXVALUE
);

/*TABLA EN MEMORIA*/
SET max_heap_table_size = 1024*1024*32;
CREATE TEMPORARY TABLE IF NOT EXISTS tmpSemanas ENGINE=MEMORY AS (
    SELECT com_geo_agrup_1, com_geo_agrup_0, com_prod_agrup_0, can_cantidad, semana, status
    From isv_semanas_tb `t`
    where `t`.`status` = 1
    and `t`.`semana` in (47, 48, 49, 50, 51, 52, 1, 2, 3, 4, 5, 6)
    and `t`.`can_fecha` >= '2015-11-23'
    and `t`.`can_fecha` <= '2016-02-14'
);

/*EJECUCIÓN DE LA QUERY*/
select SQL_NO_CACHE
    t.com_geo_agrup_1 AS id,
    SUM(can_cantidad) AS resultado,
    t.semana as semana
from `tmpSemanas` as `t`
inner join `isv_combi_geo_tb` as `g` on `g`.`com_geo_agrup_0` = `t`.`com_geo_agrup_0`
inner join `isv_combi_prod_tb` as `p` on `p`.`com_prod_agrup_0` = `t`.`com_prod_agrup_0`
group by `t`.`com_geo_agrup_1`, `t`.`semana`;
