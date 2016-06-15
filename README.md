# Pruebas técnicas TechK

## Software

Para el desarrollo de estas tareas instalaré el siguiente Software  

* Mysql Server (5.7.12-0ubuntu1)  
* Mysql Workbench  

## 1.- Primeros pasos (Importando data)

Para comenzar a trabajar en las pruebas vamos a crear una base de datos a la que
llamaremos "isv".

    mysql> create database isv;

Con esto ya podemos crear las tablas a partir de los archivos proporcionados en
estructura_sql.zip. En una terminal con una máquina que tenga mysql-server en
marcha escribiremos los siguiente:

    mysql -u root -p isv < isv_combi_prod_tb.sql  
    mysql -u root -p isv < isv_combi_geo_tb.sql  
    mysql -u root -p isv < isv_semanas_tb.sql

Para terminar volcaremos toda la data en nuestra base de datos.

```
mysql -u root -p isv < isv_semanas_tb_data.sql
```
## 2.- CONOCIENDO LA DATA

Un comienzo para tener un buen punto de partida es conocer qué y cuanta data
tenemos. Como primer paso vamos a ver cuantos registros tenemos en cada una de
las tablas.

    SHOW TABLE STATUS
	WHERE NAME = 'isv_semanas_tb' 
	OR NAME = 'isv_combi_geo_tb'
	OR NAME = 'isv_combi_prod_tb'

Lo que nos devuelve la siguiente información:

####Número de filas
Semanas | Combi Geo | Combi Prod
------- | --------- | ----------
21120415 | 1361 | 693

###Tamaño data:
Todo cuanto podemos deducir de aquí es que el mayor problema lo tenemos en la
gran cantidad de data que contiene la tabla 'isv_semanas_tb'. Lo que nos
sugiere que seguramente tengamos problemas de performance, más aun cuando 
hablamos de hacer JOINs con esta tabla.

###Engine:
Observamos también que el ENGINE que utilizan las tablas es MyISAM. En tablas
con mucha data y con un indexamiento correcto el motor InnoDB suele dar mejores
resultados de performance para consultas. Para empezar a realizar las pruebas
no vamos a modificar el ENGINE, aunque más adelante haremos una comparativa 
entre ambos motores.

##Índices:
Veamos ahora los indices en las tablas. 

#### isv_combi_geo_tb
| Key_name | Column_name |
| -------- | ----------- |
| PRIMARY | com_geo_idcom |

#### isv_combi_prod_tb
| Key_name | Column_name |
| -------- | ----------- |
| PRIMARY | com_prod_idcom |

#### isv_semanas_tb
| Key_name | Column_name |
| -------- | ----------- |
| PRIMARY | can_idcantidad |

Viendo esto en principio todo es correcto. Aunque mas adelante cuando analizemos
la QUERY, veremos que por motivos de perfomance habrá que modificar algunos
indices.


## 3.- QUERY A OPTIMIZAR

```sql
select SQL_NO_CACHE  
	t.com_geo_agrup_1 AS id,  
	SUM(can_cantidad) AS resultado,  
	t.semana as semana  
from `isv_semanas_tb` as `t`  
inner join `isv_combi_geo_tb` as `g` on `g`.`com_geo_agrup_0` = `t`.`com_geo_agrup_0`  
inner join `isv_combi_prod_tb` as `p` on `p`.`com_prod_agrup_0` = `t`.`com_prod_agrup_0`  
where `t`.`status` = 1  
and `t`.`semana` in (47, 48, 49, 50, 51, 52, 1, 2, 3, 4, 5, 6)  
and `t`.`can_fecha` >= '2015-11-23'  
and `t`.`can_fecha` <= '2016-02-14'  
group by `t`.`com_geo_agrup_1`, `t`.`semana`;  
```


/*ALTER TABLE isv_semanas_tb MODIFY can_idcantidad INT NOT NULL*/

/*ALTER TABLE isv_semanas_tb DROP PRIMARY KEY*/

/*ALTER TABLE isv_semanas_tb ADD PRIMARY KEY(can_idcantidad,can_semana);*/

/*ALTER TABLE isv_semanas_tb
PARTITION BY HASH(can_semana) PARTITIONS 101;*/
