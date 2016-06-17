SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

DROP TABLE IF EXISTS `isv_semanas_tb`;
CREATE TABLE IF NOT EXISTS `isv_semanas_tb` (
  `can_idcantidad` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `com_geo_agrup_0` smallint(6) unsigned NOT NULL,
  `com_geo_agrup_1` smallint(6) unsigned NOT NULL,
  `com_geo_agrup_2` smallint(6) unsigned NOT NULL,
  `com_geo_agrup_3` smallint(6) unsigned NOT NULL,
  `com_geo_agrup_4` smallint(6) unsigned NOT NULL,
  `com_geo_agrup_5` smallint(6) unsigned NOT NULL,
  `com_geo_agrup_6` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_0` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_1` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_2` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_3` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_4` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_5` smallint(6) unsigned NOT NULL,
  `com_prod_agrup_6` smallint(6) unsigned NOT NULL,
  `can_cadena` tinyint(2) unsigned NOT NULL,
  `can_fecha` date NOT NULL,
  `can_semana` smallint(6) NOT NULL,
  `can_anio` tinyint(4) NOT NULL,
  `can_cantidad` decimal(21,6) NOT NULL DEFAULT '0.000000',
  `can_valor` decimal(21,6) NOT NULL DEFAULT '0.000000',
  `can_valor_venta` decimal(21,6) NOT NULL DEFAULT '0.000000',
  `can_valor_convertido` decimal(21,6) NOT NULL DEFAULT '0.000000',
  `can_valor_convertido_2` decimal(21,6) NOT NULL DEFAULT '0.000000',
  `can_cantidad_convertido` decimal(21,6) NOT NULL DEFAULT '0.000000',
  `status` bit(1) NOT NULL,
  `unidad_medida` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `cadena` char(20) COLLATE utf8_spanish_ci NOT NULL,
  `codigo_cadena` varchar(30) COLLATE utf8_spanish_ci NOT NULL,
  `codigo_local` varchar(20) COLLATE utf8_spanish_ci NOT NULL,
  `can_fecha_ingreso` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `semana` tinyint(1) unsigned NOT NULL,
  `mes` tinyint(1) unsigned NOT NULL,
  `ano` smallint(2) unsigned NOT NULL,
  `week_year` int(11) NOT NULL,
  PRIMARY KEY (`can_idcantidad`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
