-- MySQL dump 10.13  Distrib 5.7.21, for Linux (x86_64)
--
-- Host: localhost    Database: usb_device
-- ------------------------------------------------------
-- Server version	5.5.5-10.2.11-MariaDB-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `usb_device`
--

CREATE DATABASE  IF NOT EXISTS `usb_device` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;
USE `usb_device`;

--
-- Table structure for table `returned`
--

DROP TABLE IF EXISTS `returned`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `returned` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serialnum` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deviceid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `caption` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sizebytes` bigint(20) NOT NULL,
  `date` date NOT NULL DEFAULT current_timestamp(),
  `time` time NOT NULL DEFAULT current_timestamp(),
  `ownership` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `timestamp` (`date`,`time`),
  KEY `device_wo_serial` (`deviceid`,`caption`),
  KEY `device_w_serial` (`deviceid`,`caption`,`serialnum`)
) ENGINE=InnoDB AUTO_INCREMENT=200 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `storage`
--

DROP TABLE IF EXISTS `storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `storage` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serialnum` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deviceid` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `caption` varchar(60) CHARACTER SET utf8mb4 NOT NULL,
  `sizebytes` bigint(20) NOT NULL,
  `computername` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `username` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `date` date NOT NULL DEFAULT current_timestamp(),
  `time` time NOT NULL DEFAULT current_timestamp(),
  `fullname` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `device_user_pc` (`serialnum`,`deviceid`,`caption`,`sizebytes`,`computername`,`username`),
  KEY `timestamp` (`date`,`time`),
  KEY `device_w_serial` (`deviceid`,`caption`,`serialnum`),
  KEY `device_wo_serial` (`deviceid`,`caption`)
) ENGINE=InnoDB AUTO_INCREMENT=20616 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-03-15  8:15:31
