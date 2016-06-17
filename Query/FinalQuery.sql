/*SHOW PROFILES;*/
 
/*SHOW PROFILE SOURCE FOR QUERY 33;*/

/*SET max_heap_table_size = 1024*1024*32;*/
drop table tmpSemanas

CREATE TEMPORARY TABLE IF NOT EXISTS tmpSemanas ENGINE=MEMORY AS (
	SELECT com_geo_agrup_1, com_geo_agrup_0, com_prod_agrup_0, can_cantidad, semana, status
    From isv_semanas_tb `t`
    where `t`.`status` = 1
	and `t`.`semana` in (47, 48, 49, 50, 51, 52, 1, 2, 3, 4, 5, 6)
	and `t`.`can_fecha` >= '2015-11-23'
	and `t`.`can_fecha` <= '2016-02-14'
);

select SQL_NO_CACHE
	t.com_geo_agrup_1 AS id,
	SUM(can_cantidad) AS resultado,
	t.semana as semana
from `tmpSemanas` as `t`
inner join `isv_combi_geo_tb` as `g` on `g`.`com_geo_agrup_0` = `t`.`com_geo_agrup_0`
inner join `isv_combi_prod_tb` as `p` on `p`.`com_prod_agrup_0` = `t`.`com_prod_agrup_0`
group by `t`.`com_geo_agrup_1`, `t`.`semana`