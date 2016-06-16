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

```sql
    SHOW TABLE STATUS
	WHERE NAME = 'isv_semanas_tb' 
	OR NAME = 'isv_combi_geo_tb'
	OR NAME = 'isv_combi_prod_tb'
```

Lo que nos devuelve la siguiente información:

####Número de filas
Semanas | Combi Geo | Combi Prod
------- | --------- | ----------
21120415 | 1361 | 693

####Tamaño data:
Todo cuanto podemos deducir de aquí es que el mayor problema lo tenemos en la
gran cantidad de data que contiene la tabla 'isv_semanas_tb'. Lo que nos
sugiere que seguramente tengamos problemas de performance, más aun cuando 
hablamos de hacer JOINs con esta tabla.

####Engine:
Observamos también que el ENGINE que utilizan las tablas es MyISAM. En tablas
con mucha data y con un indexamiento correcto el motor InnoDB suele dar mejores
resultados de performance para consultas. Para empezar a realizar las pruebas
no vamos a modificar el ENGINE, aunque más adelante haremos una comparativa 
entre ambos motores.

####Índices:
Veamos ahora los indices en las tablas. 

##### isv_combi_geo_tb
| Key_name | Column_name |
| -------- | ----------- |
| PRIMARY | com_geo_idcom |

##### isv_combi_prod_tb
| Key_name | Column_name |
| -------- | ----------- |
| PRIMARY | com_prod_idcom |

##### isv_semanas_tb
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

De un primer vistazo, lo que podemos ver es que para los JOIN se están usando campos
que no están indexados. Esto hará que la consulta se demore muchisimo en recolectar
toda la información. Cambiar los indices de las tablas *'isv_combi_geo_tb'* y *'isv_combi_prod_tb'*
va a ser uno de los primeros pasos.

## 4.- PRIMERA EJECUCIÓN

Ejecutamos la query tal como estaba para tener los primeros resultados y mediciones.
Cabe matizar que las pruebas no se van a realizan en una máquina muy rápida por lo 
que los resultados no serán los más optimos:

##### Resultados:

| Ejecucción número | Duración |
| ----------------- | -------- |
| #1 | 294,684 sec |
| #2 | 285,178 sec |
| #3 | 306,765 sec |
| #4 | 307,489 sec |
| #5 | 296,367 sec |
| #6 | 299,126 sec |

Los resultados muestran unos tiempos inaceptables. Vamos a buscar las razones por las
que puede estar siendo ineficiente. Hagamos un *EXPLAIN*:

| id | select\_type |
| -- | ------------ |
| 1 | SIMPLE |
| 1 | SIMPLE |
| 1 | SIMPLE |
  


| id | select\_type | table | partitions | possible\_keys | key | key_len | rows | filtered | Extra |
| -- | ------------ | ----- | ---------- | -------------- | --- | ------- | ---- | -------- | ----- | 
| 1 | SIMPLE | p | NULL | ALL | NULL | NULL | 693 | 100.00 | Using temporary; Using filesort |
| 1 | SIMPLE | g | NULL | ALL | NULL | NULL | 1361 | 100.00 | Using join buffer (Block Nested Loop) | 
| 1 | SIMPLE | t | NULL | ALL | NULL | NULL | 21120415 | 0.03 | Using where; Using join buffer (Block Nested Loop) |

Si echamos un vistazo a la columna rows observamos que las tres tablas tienen tantas
filas como tiene la propia tabla. Obviamente esto pasa porque para los JOIN no se están 
comparando campos indexados.

Por otra parte tanto la tabla *p* como la *g* tienen una cantidad de filas relativamente
corta, en un principio una solución de particionado para estas tablas no sería de mucha 
ayuda. Sin embargo la tabla *t* es demasiado extensa y un indicador muy importante es
la columna _filtered_ donde nos indica esencialmente que de esos 21120414 registros,
solo el 0.03 por ciento se usan para el resultado final. Esto quiere decir que tenemos
una población de datos en la que se desecha el 98.97 de el. Un buen particionado de esta 
tabla recortaría la población de registros y haría la query mas eficiente.

## 5.- PROFILING DE LA QUERY

Vamos a hilar más fino que en el anterior apartado y vamos ha realizar un profiling de 
la query a optimizar y obtenemos el siguiente resultado:


| Status | Duration | Source\_function | Source\_file | Source_line |
| ------ | -------- | ---------------- | ------------ | ----------- |
| starting | '0.048877' | NULL | NULL | NULL |
|checking permissions | '0.000010' | 'check_access' | 'sql_authorization.cc' | '835' |
|checking permissions' | '0.000002' | 'check_access' | 'sql_authorization.cc' | '835' |
|checking permissions' | '0.000004' | 'check_access' | 'sql_authorization.cc' | '835' |
|Opening tables' | '0.000019' | 'open_tables' | 'sql_base.cc' | '5648' |
|init' | '0.010077' | 'handle_query' | 'sql_select.cc' | '121' |
|System lock' | '0.000020' | 'mysql_lock_tables' | 'lock.cc' | '321' |
|optimizing' | '0.000021' | 'optimize' | 'sql_optimizer.cc' | '151' |
|statistics' | '0.007150' | 'optimize' | 'sql_optimizer.cc' | '367' |
|preparing' | '0.000034' | 'optimize' | 'sql_optimizer.cc' | '475' |
|Creating tmp table' | '0.013395' | 'create_intermediate_table' | 'sql_executor.cc' | '216' |
|Sorting result' | '0.000016' | 'make_tmp_tables_info' | 'sql_select.cc' | '3817' |
|executing' | '0.000003' | 'exec' | 'sql_executor.cc' | '119' |
|Sending data' | '278.639426' | 'exec' | 'sql_executor.cc' | '195' |
|Creating sort index' | '0.024091' | 'sort_table' | 'sql_executor.cc' | '2585' |
|end' | '0.002872' | 'handle_query' | 'sql_select.cc' | '199' |
|query end' | '0.000012' | 'mysql_execute_command' | 'sql_parse.cc' | '4918' |
|removing tmp table' | '0.000703' | 'free_tmp_table' | 'sql_tmp_table.cc' | '2388' |
|query end' | '0.000006' | 'free_tmp_table' | 'sql_tmp_table.cc' | '2417' |
|closing tables' | '0.000012' | 'mysql_execute_command' | 'sql_parse.cc' | '4970' |
|freeing items' | '0.028558' | 'mysql_parse' | 'sql_parse.cc' | '5538' |
|cleaning up' | '0.000024' | 'dispatch_command' | 'sql_parse.cc' | '1866' |

Teniendo esta información ahora si que resulta evidente el problema de indexamiento.
Si observamos atentamente el _Sending data_ tiene una duración exagerada.

## 6.- REINDEXANDO LAS TABLAS

Con este paso vamos a conseguir que la consulta sea mucho mas rápida. Al final de
este apartado volveremos a ejecutar la query la misma cantidad de veces que en el
apartado 4. Así podremos sacar las primeras conclusiones.

El primer paso será eliminar los _primary keys_ de las tablas *'isv_combi_geo_tb'* y 
*'isv_combi_prod_tb'* y crear nuevas.


```sql
alter table isv_combi_geo_tb modify com_geo_idcom int not null;
alter table isv_combi_geo_tb drop primary key;
alter table isv_combi_prod_tb modify com_prod_idcom int not null;
alter table isv_combi_prod_tb drop primary key;

```

Ahora añadiremos una primary key para cada tabla que contendrá dos columnas.

```sql
alter table isv_combi_geo_tb add primary key( com_geo_agrup_0, com_geo_idcom);
alter table isv_combi_prod_tb add primary key( com_prod_agrup_0, com_prod_idcom);

```

Habiendo hecho esto, ahora tenemos que los JOIN se están realizando sobre campos
que están indexados. Probemos entonces la query a optimizar:


| Ejecucción número | Duración |
| ----------------- | -------- |
| #1 | 30,181 sec |
| #2 | 28,650 sec |
| #3 | 28,963 sec |
| #4 | 30,514 sec |
| #5 | 28,492 sec |
| #6 | 27,901 sec |


Haciendo profiling de la última consulta vemos que el _Sending data_ se ha reducido
hasta en un 90%. ¿ Y que diferencias encontrariamos si hacemos un *EXPLAIN* ?

| id | select\_type | table | partitions | type | possible\_keys | key | key_len | ref | rows | filtered | extra |
| -- | ------------ | ----- | ---------- | ---- | -------------- | --- | ------- | --- | ---- | -------- | ----- |
|  1 | SIMPLE | t | NULL| ALL | NULL | NULL | NULL | NULL | 21120415 | 2.78 | Using where; Using temporary; Using filesort |
|  1 | SIMPLE | p | NULL| ref | PRIMARY | PRIMARY | 2 | isv.t.com_prod_agrup_0 | 6 | 100.00 | Using where; Using index |
|  1 | SIMPLE | g | NULL | ref | PRIMARY | PRIMARY | 2 | isv.t.com_geo_agrup_0 | 13 | 100.00 | Using where; Using index |

Lo primero en lo que nos fijamos es la columna rows. Para las tablas *p* y *g*
la cantidad ha disminuido drásticamente. Con el nuevo indexamiento no es necesario
que se comparen "todos con todos". Con la nueva cantidad de filas:

	Geo -> 6/693*100 = 0.86
	Prod -> 13/1361*100 = 0.95

Lo que explica la ganancia de un 90% en el tiempo de respuesta de la query. 
Hemos conseguido reducir las comparaciones que la base de datos tiene que
realizar en los JOIN, ¿Pero se puede mejorar aún más?. Antes hemos hablado
de la gran población de registros que tenemos en la tabla 'isv_semanas_tb'.
Si pudieramos acotar los 21120415 registros aun reduciriamos mas los cálculos.
Es hora de particionar tablas.


## 7.- PARTICIONANDO

Si analizamos al detalle la tabla *'isv\_semanas\_tb'* podemos observar que
tenemos unos campos muy utiles para hacer un particionado óptimo. Ya que
MySQL ofrece la posibilidad de hacer Subparticiones haremos particiones 
RANGE por el año del campo 'can\_fecha' y las subparticiones serán un hash
del campo 'can\_semana'. Para ello haremos:

```sql
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
```

Hagamos un *EXPLAIN* de la Query

| id | select\_type | table | partitions | type | possible\_keys | key | key_len | ref | rows | filtered | extra |
| -- | ------------ | ----- | ---------- | ---- | -------------- | --- | ------- | --- | ---- | -------- | ----- |
|  1 | SIMPLE | t | 'p4_p4sp0,p4_p4s ...'| ALL | NULL | NULL | NULL | NULL | '8299605' | 2.78 | Using where; Using temporary; Using filesort |
|  1 | SIMPLE | p | NULL| ref | PRIMARY | PRIMARY | 2 | isv.t.com_prod_agrup_0 | 6 | 100.00 | Using where; Using index |
|  1 | SIMPLE | g | NULL | ref | PRIMARY | PRIMARY | 2 | isv.t.com_geo_agrup_0 | 13 | 100.00 | Using where; Using index |


Aquí ya podemos observar que la población de registros de *'isv\_semanas\_tb'* ha 
descendido, lo que seguramente se vea reflejado a la hora de ejecutar la Query.

| Ejecucción número | Duración |
| ----------------- | -------- |
| #1 | 15,364 sec |
| #2 | 14.585 sec |
| #3 | 14,088 sec |
| #4 | 13,950 sec |
| #5 | 14,220 sec |
| #6 | 13,988 sec |

Como consecuencia de limitar los registros a algo más de la mitad el tiempo se ha 
reducido a su vez proporcionalmente. Probablemente podamos reducir aún mas el 
tiempo. En el siguiente apartado.


## 8.- MEMORY TABLES

Cuando hablamos de tablas en memoria hay que ser muy cautelosos, entender el contexto
y determinar si nos sirven de ayuda. Están contraindicadas para almacenar tablas 
con frecuentes modificaciones (UPDATE, DELETE, INSERT). Por la cantidad de registros
en la tabla *'isv\_semanas\_tb'* podemos intuir que se trata de una tabla con 
mucho flujo de información pero aun así veremos el impacto de crear una tabla 
temporal almacenada en memoria en nuestra Query.

Otro problema que se nos presenta es el tamaño de la tabla. Si bien hemos conseguido
acotar los registros a 8299605, sigue siendo una gran cantidad. De no estar almacenado
en memoria, tendria que tirar del disco duro con la consecuente perdida de tiempo.
Almacenandolo en memoria RAM evitaremos el problema del timming pero aparece el 
problema del tamaño.

Por defecto MySQL trae un _max\_heap\_table\_size_ de 16M. Dificilmente vamos a
conseguir encajar 8299605 registros en ese tamaño. Lo que haremos será duplicar
la memoria.

```sql
SET max_heap_table_size = 1024*1024*32;
```

Con esto ya podemos crear la tabla temporal en memoria. Como consecuencia tendremos 
que modificar la Query a optimizar por lo siguiente:


```sql
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
group by `t`.`com_geo_agrup_1`, `t`.`semana`;
```

La primera vez que ejecutemos la Query no veremos ninguna mejora con respecto al
apartado anterior. Esto es porque si la tabla temporal no existe tendrá que crearla.
Si volvemos a ejecutarla query antes de que se elimine la tabla temporal notaremos
una mejoría.

| Ejecucción número | Duración |
| ----------------- | -------- |
| #1 | 12,508 + 2,829 sec |
| #2 | 2,813 sec |
| #3 | 2,865 sec |
| #4 | 2,933 sec |
| #5 | 2,817 sec |
| #6 | 2,829 sec |



