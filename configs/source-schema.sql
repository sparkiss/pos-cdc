/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.3-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: 192.168.0.74    Database: pos
-- ------------------------------------------------------
-- Server version	5.7.23-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Current Database: `pos`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `pos` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `pos`;

--
-- Table structure for table `account`
--

DROP TABLE IF EXISTS `account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `account` (
  `ID` int(11) unsigned NOT NULL,
  `Account_ID` int(10) unsigned NOT NULL,
  `Name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Account_ID` (`Account_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `adyen_notification`
--

DROP TABLE IF EXISTS `adyen_notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `adyen_notification` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `PspReference` varchar(50) CHARACTER SET utf8 NOT NULL,
  `OrderId` int(11) NOT NULL,
  `Success` tinyint(1) DEFAULT NULL,
  `Response` varchar(2000) CHARACTER SET utf8 DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `IX_AdyenNotification_OrderId` (`OrderId`),
  KEY `IX_AdyenNotification_PspReference` (`PspReference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `barbies`
--

DROP TABLE IF EXISTS `barbies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `barbies` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `OrderId` int(11) NOT NULL,
  `CardNumber` varchar(50) CHARACTER SET utf8 NOT NULL,
  `Points` int(11) DEFAULT NULL,
  `PointsEarned` int(11) DEFAULT NULL,
  `PointsValueRedeemed` decimal(19,5) DEFAULT NULL,
  `BirthdayBonusUsed` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_Barbies_OrderId` (`OrderId`),
  KEY `IX_Barbies_CardNumber` (`CardNumber`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blobs`
--

DROP TABLE IF EXISTS `blobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `blobs` (
  `IdWorkstation` int(11) NOT NULL DEFAULT '0',
  `Name` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Data` mediumblob,
  `Hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `LastChange` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`Name`,`IdWorkstation`),
  KEY `idx_hash` (`Hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `call_course`
--

DROP TABLE IF EXISTS `call_course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `call_course` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Table_ID` smallint(4) unsigned NOT NULL,
  `Service` tinyint(3) unsigned NOT NULL,
  `DateTime` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Table_ID` (`Table_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPACT;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cashdrawer`
--

DROP TABLE IF EXISTS `cashdrawer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cashdrawer` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `User_ID` int(11) unsigned NOT NULL,
  `OpenDate` datetime NOT NULL,
  `Total` time NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `OpenDate` (`OpenDate`,`User_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `config` (
  `IdConfig` int(11) NOT NULL AUTO_INCREMENT,
  `IdParentConfig` int(11) DEFAULT NULL,
  `IdWorkstation` int(11) NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Value` text COLLATE utf8mb4_unicode_ci,
  `Note` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`IdConfig`),
  UNIQUE KEY `IdConfig_UNIQUE` (`IdConfig`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `datacandy`
--

DROP TABLE IF EXISTS `datacandy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `datacandy` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) unsigned NOT NULL,
  `CardID` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TransactionID` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Amount` decimal(13,4) NOT NULL,
  `PTS` decimal(10,2) NOT NULL,
  `Type` tinyint(2) unsigned NOT NULL,
  `DateTime` datetime NOT NULL,
  `PRG` tinyint(2) unsigned NOT NULL,
  `CTM` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `RWEMSG` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Order_ID` (`Order_ID`),
  KEY `DateTime` (`DateTime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `delivery_address`
--

DROP TABLE IF EXISTS `delivery_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_address` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Type` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `Address` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Corner` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `City` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Zip` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Note` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `Client_ID` (`Deleted`),
  KEY `Address` (`Address`,`Deleted`)
) ENGINE=InnoDB AUTO_INCREMENT=202 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `delivery_client`
--

DROP TABLE IF EXISTS `delivery_client`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_client` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Phone_Number` varchar(11) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Profile_ID` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Fullname` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Attn` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Memo` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Note` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Email` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Flag` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Allergy` bigint(64) unsigned NOT NULL DEFAULT '0',
  `Created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `Phone_Number` (`Phone_Number`,`Deleted`),
  KEY `Email` (`Email`,`Deleted`)
) ENGINE=InnoDB AUTO_INCREMENT=201 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `delivery_order`
--

DROP TABLE IF EXISTS `delivery_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_order` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Client_ID` int(11) unsigned NOT NULL,
  `Address_ID` int(11) unsigned NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Client_ID` (`Client_ID`),
  KEY `Address_ID` (`Address_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=202 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employeurd_user_mapping`
--

DROP TABLE IF EXISTS `employeurd_user_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `employeurd_user_mapping` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Automatically increment row ID',
  `UserID` int(11) unsigned NOT NULL COMMENT 'UserID matching an ID from users.',
  `ReferenceNumber` int(9) unsigned NOT NULL DEFAULT '0' COMMENT 'The Matricule as present in the Desjardins EmployeurD requirements. Has a length of 9 and is numeric.',
  `TeamLead` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Boolean value. True is 1, False is 0.',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `first_nation_certificate`
--

DROP TABLE IF EXISTS `first_nation_certificate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `first_nation_certificate` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) NOT NULL,
  `RegistrationNumber` varchar(50) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `geo_caching`
--

DROP TABLE IF EXISTS `geo_caching`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `geo_caching` (
  `IdGeoCaching` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `APIProvider` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RequestUriString` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RequestResponse` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateCreated` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`IdGeoCaching`),
  UNIQUE KEY `IdGeoCaching_UNIQUE` (`IdGeoCaching`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gggolf_member`
--

DROP TABLE IF EXISTS `gggolf_member`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gggolf_member` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `MemberID` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Name` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Action` tinyint(2) DEFAULT NULL,
  `CreditLimit` decimal(13,4) DEFAULT NULL,
  `Category` int(10) DEFAULT NULL,
  `PriceList` int(10) DEFAULT NULL,
  `Tips` tinyint(1) DEFAULT NULL,
  `ServiceMandatory` tinyint(1) DEFAULT NULL,
  `Service1` tinyint(1) DEFAULT NULL,
  `Service2` tinyint(1) DEFAULT NULL,
  `Service3` tinyint(1) DEFAULT NULL,
  `Service4` tinyint(1) DEFAULT NULL,
  `Service5` tinyint(1) DEFAULT NULL,
  `AutoDiscount` tinyint(1) DEFAULT NULL,
  `ExpirationDate` datetime DEFAULT NULL,
  `AutoDiscountCode` int(10) DEFAULT NULL,
  `UseLimit` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `MemberID` (`MemberID`) USING BTREE,
  KEY `IX_gggolf_member_name` (`Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gggolf_order_menu`
--

DROP TABLE IF EXISTS `gggolf_order_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gggolf_order_menu` (
  `OrderId` int(11) NOT NULL,
  `MenuNumber` int(11) NOT NULL,
  PRIMARY KEY (`OrderId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gggolf_station_menu_mapping`
--

DROP TABLE IF EXISTS `gggolf_station_menu_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gggolf_station_menu_mapping` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Serial` varchar(45) CHARACTER SET utf8 NOT NULL,
  `MenuNumber` int(11) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gift_card`
--

DROP TABLE IF EXISTS `gift_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gift_card` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ACTIVE` tinyint(1) unsigned NOT NULL,
  `CARD_NUMBER_MD5` char(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `LAST_FOUR_DIGITS` char(4) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AMOUNT` decimal(13,2) NOT NULL,
  `ISSUED_BY` int(11) unsigned NOT NULL,
  `ISSUE_DATE` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `CARD_NUMBER_MD5` (`CARD_NUMBER_MD5`),
  KEY `ACTIVE` (`ACTIVE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gift_card_sales`
--

DROP TABLE IF EXISTS `gift_card_sales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gift_card_sales` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderItemId` int(11) NOT NULL,
  `IntegrationId` int(11) NOT NULL DEFAULT '0',
  `ActivationDateUtc` datetime DEFAULT NULL,
  `ActivationInfo` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Amount` decimal(13,4) NOT NULL,
  `CardNumber` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Failed` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `OrderItemId` (`OrderItemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `history_combine`
--

DROP TABLE IF EXISTS `history_combine`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `history_combine` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ClientFrom` smallint(4) unsigned NOT NULL,
  `Table_ID` smallint(4) unsigned NOT NULL,
  `Delivery_ID` mediumint(5) NOT NULL DEFAULT '0',
  `ItemList` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Table_ID` (`Table_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `history_separate`
--

DROP TABLE IF EXISTS `history_separate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `history_separate` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ClientFrom` smallint(4) unsigned NOT NULL,
  `Table_ID` smallint(4) unsigned NOT NULL,
  `Delivery_ID` mediumint(5) NOT NULL DEFAULT '0',
  `ItemIDFrom` int(11) unsigned NOT NULL,
  `ItemIDTo` int(11) unsigned NOT NULL,
  `Action` tinyint(2) unsigned NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Table_ID` (`Table_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=93 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `UID` int(11) unsigned NOT NULL,
  `QTY` decimal(13,4) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `UID` (`UID`),
  KEY `QTY` (`QTY`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_in_out`
--

DROP TABLE IF EXISTS `inventory_in_out`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_in_out` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `UID` int(11) unsigned NOT NULL,
  `QTY` decimal(13,4) NOT NULL,
  `Date` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `UID` (`UID`),
  KEY `Date` (`Date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `itemweight`
--

DROP TABLE IF EXISTS `itemweight`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `itemweight` (
  `Id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ItemId` int(10) unsigned NOT NULL,
  `GrossWeight` decimal(10,4) NOT NULL,
  `TareWeight` decimal(10,4) NOT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_ItemWeight_ItemId` (`ItemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `liquor`
--

DROP TABLE IF EXISTS `liquor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `liquor` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(11) unsigned NOT NULL,
  `device_id` int(11) unsigned NOT NULL DEFAULT '0',
  `Item_uid` int(11) unsigned NOT NULL,
  `field_device_type` tinyint(2) unsigned NOT NULL,
  `pour` int(11) unsigned NOT NULL DEFAULT '0',
  `pour_level` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `device_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `virtual_bar_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `incomplete` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `type` tinyint(1) unsigned NOT NULL,
  `IP` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `device_time` (`device_time`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `live_cart_info`
--

DROP TABLE IF EXISTS `live_cart_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `live_cart_info` (
  `id_live_cart_info` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serial` varchar(45) CHARACTER SET utf8 NOT NULL,
  `cart_json` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_live_cart_info`),
  UNIQUE KEY `IX_live_cart_info_serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lock`
--

DROP TABLE IF EXISTS `lock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lock` (
  `Key` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Owner` int(11) NOT NULL,
  `Timestamp` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `TimeoutMs` int(11) NOT NULL DEFAULT '5000',
  PRIMARY KEY (`Key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `lock_view`
--

DROP TABLE IF EXISTS `lock_view`;
/*!50001 DROP VIEW IF EXISTS `lock_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `lock_view` AS SELECT
 1 AS `Key`,
  1 AS `Owner`,
  1 AS `Timestamp`,
  1 AS `TimeoutMs`,
  1 AS `Expired` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `log`
--

DROP TABLE IF EXISTS `log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `log` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `IdWorkstation` int(11) NOT NULL,
  `TimestampUtc` datetime(3) NOT NULL,
  `Level` int(11) NOT NULL,
  `SessionName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `PID` int(11) NOT NULL DEFAULT '-1',
  `Message` varchar(4100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Exception` varchar(4100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Attachment` blob,
  PRIMARY KEY (`Id`),
  KEY `IDX_Log_Timestamp` (`TimestampUtc`),
  KEY `IDX_Log_IdWorkstation` (`IdWorkstation`)
) ENGINE=InnoDB AUTO_INCREMENT=3835636 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu`
--

DROP TABLE IF EXISTS `menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu` (
  `IdMenu` int(11) NOT NULL AUTO_INCREMENT,
  `XMLMenu` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Type` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `LastChange` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DateCreated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Active` bit(1) DEFAULT NULL,
  `Checksum` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `IdWorkstation` int(11) NOT NULL,
  PRIMARY KEY (`IdMenu`),
  UNIQUE KEY `UC_Active` (`Active`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `message_queue`
--

DROP TABLE IF EXISTS `message_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `message_queue` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Type` int(11) DEFAULT NULL,
  `Timestamp` datetime DEFAULT NULL,
  `Data` mediumtext COLLATE utf8mb4_unicode_ci,
  `Attempts` int(11) DEFAULT NULL,
  `TargetQueueName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `UniqueId` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `message_queue_configuration`
--

DROP TABLE IF EXISTS `message_queue_configuration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `message_queue_configuration` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `TargetQueueName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `QueueUrl` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AccessKey` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SecretKey` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ServiceUrl` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `QueueName_UNIQUE` (`TargetQueueName`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mev_transaction`
--

DROP TABLE IF EXISTS `mev_transaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mev_transaction` (
  `TransactionId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `OrderId` int(10) unsigned NOT NULL,
  `UserId` int(10) unsigned NOT NULL,
  `IdApprl` varchar(14) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TypTrans` varchar(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ModTrans` varchar(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ModImpr` varchar(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Status` varchar(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransactionJson` text COLLATE utf8mb4_unicode_ci,
  `PsiNoTrans` varchar(19) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `PsiDatTrans` datetime DEFAULT NULL,
  `LotNumber` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `LotDate` datetime DEFAULT NULL,
  `QRCodeUrl` text COLLATE utf8mb4_unicode_ci,
  `DateCreated` datetime DEFAULT NULL,
  `DateProcessed` datetime DEFAULT NULL,
  `NoTrans` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Duration` int(10) unsigned DEFAULT NULL,
  `FormImpr` varchar(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Amount` decimal(13,4) DEFAULT NULL,
  `Reason` mediumtext COLLATE utf8mb4_unicode_ci,
  `DatTrans` datetime DEFAULT NULL,
  `ModPai` varchar(3) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`TransactionId`),
  KEY `IX_mev_transaction_orderID` (`OrderId`),
  KEY `IX_mev_transaction_DateCreated` (`DateCreated`),
  KEY `IX_mev_transaction_Status` (`Status`),
  KEY `IX_mev_transaction_UserId` (`UserId`),
  KEY `IX_mev_transaction_NoTrans` (`NoTrans`)
) ENGINE=InnoDB AUTO_INCREMENT=16067 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mews_account_mapping`
--

DROP TABLE IF EXISTS `mews_account_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mews_account_mapping` (
  `mews_account_mapping_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `mews_account` varchar(100) CHARACTER SET utf8 NOT NULL,
  `mews_account_id` varchar(50) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`mews_account_mapping_id`),
  UNIQUE KEY `IX_mews_account_mapping_account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mews_tax_mapping`
--

DROP TABLE IF EXISTS `mews_tax_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mews_tax_mapping` (
  `mews_tax_mapping_id` int(11) NOT NULL AUTO_INCREMENT,
  `tax_id` tinyint(3) unsigned NOT NULL,
  `mews_tax_name` varchar(50) CHARACTER SET utf8 NOT NULL,
  `mews_tax_code` varchar(50) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`mews_tax_mapping_id`),
  UNIQUE KEY `IX_mews_tax_mapping_tax_id` (`tax_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Date` datetime NOT NULL,
  `DateClose` datetime NOT NULL,
  `DatePreorder` datetime DEFAULT NULL,
  `Table_ID` smallint(4) unsigned NOT NULL DEFAULT '0',
  `Client_ID` smallint(4) unsigned NOT NULL,
  `User_ID` int(11) unsigned NOT NULL,
  `Delivery_ID` mediumint(5) unsigned NOT NULL,
  `SubTotal` decimal(13,4) NOT NULL,
  `Tax1` decimal(13,4) NOT NULL,
  `Tax2` decimal(13,4) NOT NULL,
  `Tax3` decimal(13,4) NOT NULL,
  `Tax4` decimal(13,4) NOT NULL,
  `Tax5` decimal(13,4) NOT NULL,
  `Tax6` decimal(13,4) NOT NULL,
  `NonTaxable` decimal(13,4) NOT NULL,
  `NonSale` decimal(13,4) NOT NULL,
  `Tax_Rounding` decimal(13,4) NOT NULL,
  `Total` decimal(13,4) NOT NULL,
  `Device` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `Client_Name` varchar(48) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Profile_ID` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Bill` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Completed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Closed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Prepared` tinyint(1) unsigned NOT NULL,
  `Close_Date` datetime DEFAULT NULL,
  `Note` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Reason` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Void_By` int(11) unsigned NOT NULL,
  `IP` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Online_Client_UID` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'UID received from online ordering. Unique id of device.',
  `License` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'POS station that made the sale.',
  `IsPreAuthorized` tinyint(4) NOT NULL DEFAULT '0',
  `EdgeFee` decimal(13,4) NOT NULL DEFAULT '0.0000',
  `CloseDayID` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MEVTransactionDate` datetime(3) DEFAULT NULL,
  `RefundForOrderId` int(11) unsigned DEFAULT NULL,
  `Updated_At` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `External_Id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `Closed` (`Closed`,`Deleted`,`Completed`),
  KEY `DateClose` (`DateClose`,`Deleted`,`Completed`),
  KEY `Table_ID` (`Table_ID`,`Deleted`,`Completed`) USING BTREE,
  KEY `Delivery_ID` (`Delivery_ID`),
  KEY `IX_orders_user_id` (`User_ID`),
  KEY `IX_orders_deleted` (`Deleted`),
  KEY `IX_orders_completed` (`Completed`),
  KEY `IX_orders_bill` (`Bill`)
) ENGINE=InnoDB AUTO_INCREMENT=14304 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='All Order information';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_combine`
--

DROP TABLE IF EXISTS `orders_combine`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_combine` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `IDFrom` int(11) unsigned NOT NULL,
  `IDTo` int(11) unsigned NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `IDTo` (`IDTo`)
) ENGINE=InnoDB AUTO_INCREMENT=165 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_discount`
--

DROP TABLE IF EXISTS `orders_discount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_discount` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `From_ID` int(11) unsigned NOT NULL,
  `From_Type` tinyint(2) unsigned NOT NULL,
  `Discount_uid` int(10) unsigned NOT NULL,
  `Type` tinyint(2) unsigned NOT NULL,
  `Value` decimal(13,4) NOT NULL,
  `Name` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Discount_User_ID` int(11) unsigned NOT NULL,
  `Price` decimal(13,4) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `From_ID` (`From_ID`,`From_Type`)
) ENGINE=InnoDB AUTO_INCREMENT=181 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_ingredient`
--

DROP TABLE IF EXISTS `orders_ingredient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_ingredient` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Item_ID` int(11) unsigned NOT NULL DEFAULT '0',
  `Ingredient_uid` int(10) unsigned NOT NULL,
  `Change_uid` int(10) unsigned NOT NULL,
  `Account` int(10) unsigned NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DefaultName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Price` decimal(13,4) NOT NULL,
  `PriceEdge` decimal(13,4) NOT NULL,
  `Tax_Type` tinyint(2) unsigned NOT NULL DEFAULT '31',
  `Qty` smallint(4) NOT NULL DEFAULT '1',
  `Modifier` tinyint(2) unsigned NOT NULL,
  `Modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `PriceLock` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `Account` (`Account`,`Deleted`),
  KEY `Item_ID` (`Item_ID`,`Modifier`,`Deleted`,`Price`)
) ENGINE=InnoDB AUTO_INCREMENT=865 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='individual item per order';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_item`
--

DROP TABLE IF EXISTS `orders_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_item` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) unsigned NOT NULL DEFAULT '0',
  `Item_uid` int(10) unsigned NOT NULL,
  `Account` int(10) unsigned NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DefaultName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Qty` smallint(4) NOT NULL DEFAULT '1',
  `Unit_Qty` decimal(13,4) NOT NULL DEFAULT '1.0000',
  `Unit_Type` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `Price` decimal(13,4) NOT NULL,
  `PriceEdge` decimal(13,4) NOT NULL,
  `Tax_Type` tinyint(2) unsigned NOT NULL DEFAULT '31',
  `SplitID` int(11) unsigned NOT NULL DEFAULT '0',
  `SplitBy` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `Category` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Combo` int(11) unsigned NOT NULL DEFAULT '0',
  `Service` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `Type` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Printed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `PrintDate` datetime NOT NULL,
  `Bill` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Note` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Reason` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Void_By` int(11) unsigned NOT NULL,
  `Modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `IsPreAuthorized` tinyint(4) NOT NULL DEFAULT '0',
  `PriceLock` tinyint(4) NOT NULL DEFAULT '0',
  `ActivitySubSector` varchar(3) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `MealCount` decimal(13,4) DEFAULT NULL,
  `CategoryHierarchy` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `OriginalPrice` decimal(13,4) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `Combo` (`Combo`) USING BTREE COMMENT 'IMPORTANT GetComboItems',
  KEY `Order_ID` (`Order_ID`,`Type`,`Deleted`,`Price`) USING BTREE,
  KEY `Account` (`Account`,`Deleted`)
) ENGINE=InnoDB AUTO_INCREMENT=34331 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='individual item per order';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_option`
--

DROP TABLE IF EXISTS `orders_option`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_option` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Item_ID` int(11) unsigned NOT NULL DEFAULT '0',
  `Option_uid` int(10) unsigned NOT NULL,
  `Account` int(10) unsigned NOT NULL,
  `Index_ID` tinyint(2) unsigned NOT NULL,
  `Value` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DefaultName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Price` decimal(13,4) NOT NULL,
  `PriceEdge` decimal(13,4) NOT NULL,
  `Tax_Type` tinyint(2) unsigned NOT NULL DEFAULT '31',
  `Qty` smallint(4) NOT NULL,
  `Type` tinyint(2) unsigned NOT NULL,
  `Modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PriceLock` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `Item_ID` (`Item_ID`,`Price`) USING BTREE,
  KEY `Account` (`Account`)
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='individual item per order';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_payment`
--

DROP TABLE IF EXISTS `orders_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_payment` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) unsigned NOT NULL,
  `Method` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Payment` decimal(13,4) NOT NULL,
  `Tip` decimal(13,4) NOT NULL,
  `Balance` decimal(13,4) NOT NULL,
  `Card_Number` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Device` tinyint(2) unsigned NOT NULL,
  `Language` tinyint(2) unsigned NOT NULL,
  `Card_Entry_Mode` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `Approval_Code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Message` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Date` datetime NOT NULL,
  `ConversionRate` decimal(13,4) NOT NULL DEFAULT '1.0000',
  `Currency` varchar(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `RefCode` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Type` int(11) NOT NULL DEFAULT '0',
  `HostCode` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Edge` int(11) NOT NULL,
  `Adjusted` tinyint(4) NOT NULL,
  `PinpadTransaction` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `BatchId` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ProcessorName` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CardReader` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `GUID` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TerminalID` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TerminalName` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UNIQUE_PAYMENT` (`GUID`),
  KEY `Order_ID` (`Order_ID`,`Deleted`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10851 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_pre_payment`
--

DROP TABLE IF EXISTS `orders_pre_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_pre_payment` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) DEFAULT NULL,
  `Transaction_ID` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Sequence` int(11) DEFAULT NULL,
  `Method` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Operation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Ammount` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransactionDate` datetime DEFAULT NULL,
  `Active` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_ref`
--

DROP TABLE IF EXISTS `orders_ref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_ref` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) unsigned NOT NULL,
  `MEV_REF` int(11) unsigned NOT NULL,
  `MEV_ADDI` int(11) unsigned NOT NULL,
  `MEV_SUB` decimal(13,4) NOT NULL,
  `MEV_DATE` datetime NOT NULL,
  `MEV_SUB_PREV` decimal(13,4) NOT NULL,
  `MEV_DATE_PREV` datetime NOT NULL,
  `Deleted` tinyint(1) unsigned NOT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `RefDatTrans` datetime DEFAULT NULL,
  `PrintDatTrans` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `Order_ID` (`Order_ID`,`Deleted`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9598 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_transfer_ownership`
--

DROP TABLE IF EXISTS `orders_transfer_ownership`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_transfer_ownership` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) unsigned NOT NULL,
  `User_IDBy` int(11) unsigned NOT NULL,
  `User_IDFrom` int(11) unsigned NOT NULL,
  `User_IDTo` int(11) unsigned NOT NULL,
  `Date` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Order_ID` (`Order_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_transfer_table`
--

DROP TABLE IF EXISTS `orders_transfer_table`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_transfer_table` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) unsigned NOT NULL,
  `User_ID_By` int(11) unsigned NOT NULL,
  `Table_ID_From` smallint(4) unsigned NOT NULL,
  `Table_ID_To` smallint(4) unsigned NOT NULL,
  `Date` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Order_ID` (`Order_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=174 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payout`
--

DROP TABLE IF EXISTS `payout`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payout` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `SupplierID` int(11) unsigned NOT NULL,
  `Description` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Amount` decimal(13,4) NOT NULL,
  `Date` datetime NOT NULL,
  `User_ID` int(11) unsigned NOT NULL,
  `Reason` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `Void_By` int(11) unsigned NOT NULL,
  `Deleted` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `User_ID` (`User_ID`),
  KEY `Date` (`Date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payout_supplier`
--

DROP TABLE IF EXISTS `payout_supplier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payout_supplier` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Deleted` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pos_version`
--

DROP TABLE IF EXISTS `pos_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pos_version` (
  `Id_POS_Version` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Serial` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Date_Created` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id_POS_Version`),
  UNIQUE KEY `Id_POS_Version` (`Id_POS_Version`)
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `processor_pendingoperation`
--

DROP TABLE IF EXISTS `processor_pendingoperation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `processor_pendingoperation` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `OrderId` int(11) NOT NULL,
  `OperationData` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `OperationId` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ProcessorName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_processor_pendingoperation_orderid` (`OrderId`),
  KEY `IX_processor_pendingoperation_processorName` (`ProcessorName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `punch_clock`
--

DROP TABLE IF EXISTS `punch_clock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `punch_clock` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `User_ID` int(11) unsigned NOT NULL,
  `PunchIn` datetime NOT NULL,
  `PunchOut` datetime NOT NULL,
  `Salary` decimal(13,2) DEFAULT '0.00',
  `IsManual` tinyint(1) unsigned NOT NULL,
  `Note` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `users_role_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `User_ID` (`User_ID`),
  KEY `PunchIn` (`PunchIn`),
  KEY `PunchOut` (`PunchOut`)
) ENGINE=InnoDB AUTO_INCREMENT=1224 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `recorded_order`
--

DROP TABLE IF EXISTS `recorded_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `recorded_order` (
  `order_id` int(10) unsigned NOT NULL,
  `table_id` smallint(4) unsigned DEFAULT NULL,
  `client_name` varchar(48) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_preorder` datetime DEFAULT NULL,
  `subtotal` decimal(13,4) DEFAULT NULL,
  `gst` decimal(13,4) DEFAULT NULL,
  `qst` decimal(13,4) DEFAULT NULL,
  `total` decimal(13,4) DEFAULT NULL,
  `items` mediumtext COLLATE utf8mb4_unicode_ci,
  `stamp` datetime DEFAULT NULL,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reservation`
--

DROP TABLE IF EXISTS `reservation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reservation` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Date` datetime NOT NULL,
  `DateEnd` datetime NOT NULL,
  `FirstName` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `LastName` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `PhoneNumber` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Email` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Guest` smallint(4) unsigned NOT NULL,
  `Table_ID` smallint(4) unsigned NOT NULL,
  `Note` mediumtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`ID`),
  KEY `Date` (`Date`,`DateEnd`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=175 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reservation_waitinglist`
--

DROP TABLE IF EXISTS `reservation_waitinglist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reservation_waitinglist` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Date` datetime NOT NULL,
  `Name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Guest` smallint(4) unsigned NOT NULL,
  `Note` mediumtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schedule`
--

DROP TABLE IF EXISTS `schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `schedule` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `DateFrom` datetime NOT NULL,
  `TimeTo` time NOT NULL,
  `User_ID` int(11) unsigned NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `DateFrom` (`DateFrom`),
  KEY `User_ID` (`User_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session_config`
--

DROP TABLE IF EXISTS `session_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `session_config` (
  `IdSessionConfig` int(11) NOT NULL AUTO_INCREMENT,
  `IdWorkstation` int(11) NOT NULL,
  `SessionName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `KeyName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Value` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`IdSessionConfig`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `system_users_view`
--

DROP TABLE IF EXISTS `system_users_view`;
/*!50001 DROP VIEW IF EXISTS `system_users_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `system_users_view` AS SELECT
 1 AS `Id`,
  1 AS `Name`,
  1 AS `Deleted`,
  1 AS `DateLastLogin` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `tablesidelog`
--

DROP TABLE IF EXISTS `tablesidelog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tablesidelog` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `TimestampUtc` datetime NOT NULL,
  `Level` int(11) NOT NULL,
  `TerminalName` varchar(64) CHARACTER SET utf8 NOT NULL,
  `Message` varchar(4096) CHARACTER SET utf8 NOT NULL,
  `Attachment` mediumtext CHARACTER SET utf8,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=17158 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tip_distribution`
--

DROP TABLE IF EXISTS `tip_distribution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tip_distribution` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `date_close` datetime NOT NULL,
  `users_id` int(10) unsigned NOT NULL,
  `users_role_id` int(11) NOT NULL,
  `users_role_name` varchar(100) CHARACTER SET utf8 NOT NULL,
  `time_worked` decimal(10,2) NOT NULL,
  `tip` decimal(10,2) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `transaction_payment_response`
--

DROP TABLE IF EXISTS `transaction_payment_response`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_payment_response` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Order_ID` int(11) DEFAULT NULL,
  `Transaction_ID` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransactionDate` datetime DEFAULT NULL,
  `Batch_ID` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Message` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `HostToken` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RequestRefCode` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ApprovalCode` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransactionType` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TerminalId` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_role_tip_distribution`
--

DROP TABLE IF EXISTS `user_role_tip_distribution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_role_tip_distribution` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `users_role_id` int(11) NOT NULL,
  `percent` decimal(10,2) NOT NULL,
  `enter_cash_tip` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `Name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Password` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `Level` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `flags` bigint(64) unsigned NOT NULL DEFAULT '0',
  `Last_Close` datetime NOT NULL,
  `Unlocked` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `Salary` decimal(13,2) unsigned NOT NULL,
  `CardNumber` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Phone` varchar(11) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Email` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Birthday` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Language` varchar(14) COLLATE utf8mb4_unicode_ci NOT NULL,
  `FingerPrint1` blob NOT NULL,
  `FingerPrint2` blob NOT NULL,
  `AddedToCloudMEV` bit(1) NOT NULL DEFAULT b'0',
  `DateLastLogin` datetime(3) DEFAULT NULL,
  `users_role_id` int(11) DEFAULT NULL,
  `multirole` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `Password` (`Password`),
  KEY `Deleted` (`Deleted`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Waiters / manager';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_role`
--

DROP TABLE IF EXISTS `users_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users_role` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `users_role_name` varchar(100) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `IX_users_role_users_role_name` (`users_role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `v__cal_2w`
--

DROP TABLE IF EXISTS `v__cal_2w`;
/*!50001 DROP VIEW IF EXISTS `v__cal_2w`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__cal_2w` AS SELECT
 1 AS `DT` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__cal_4w`
--

DROP TABLE IF EXISTS `v__cal_4w`;
/*!50001 DROP VIEW IF EXISTS `v__cal_4w`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__cal_4w` AS SELECT
 1 AS `DT` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__sales`
--

DROP TABLE IF EXISTS `v__sales`;
/*!50001 DROP VIEW IF EXISTS `v__sales`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__sales` AS SELECT
 1 AS `ORDERID`,
  1 AS `SUBTOTAL`,
  1 AS `TAX1`,
  1 AS `TAX2`,
  1 AS `TOTAL`,
  1 AS `METHOD`,
  1 AS `TIP`,
  1 AS `APPROVAL_CODE`,
  1 AS `PAYMENT`,
  1 AS `PAID_DATE`,
  1 AS `ORDER_DATE`,
  1 AS `DOW_NUM`,
  1 AS `DOW`,
  1 AS `DT`,
  1 AS `HR`,
  1 AS `TIME_DIV`,
  1 AS `ORDER_DIV` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__sales_today`
--

DROP TABLE IF EXISTS `v__sales_today`;
/*!50001 DROP VIEW IF EXISTS `v__sales_today`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__sales_today` AS SELECT
 1 AS `SORT`,
  1 AS `order_div`,
  1 AS `net`,
  1 AS `tax`,
  1 AS `gross`,
  1 AS `tip`,
  1 AS `cnt` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__sales_today_inner`
--

DROP TABLE IF EXISTS `v__sales_today_inner`;
/*!50001 DROP VIEW IF EXISTS `v__sales_today_inner`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__sales_today_inner` AS SELECT
 1 AS `SORT`,
  1 AS `order_div`,
  1 AS `net`,
  1 AS `tax`,
  1 AS `gross`,
  1 AS `tip`,
  1 AS `cnt` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__sales_weekly`
--

DROP TABLE IF EXISTS `v__sales_weekly`;
/*!50001 DROP VIEW IF EXISTS `v__sales_weekly`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__sales_weekly` AS SELECT
 1 AS `DOW`,
  1 AS `DOW_NUM`,
  1 AS `TIME_DIV`,
  1 AS `CNT`,
  1 AS `NET_SALE_TOTAL`,
  1 AS `NET_PICKUP`,
  1 AS `NET_DINE_IN`,
  1 AS `NET_ONLINE`,
  1 AS `NET_OFFLINE`,
  1 AS `AVG_NET_OFFLINE`,
  1 AS `AVG_NET_ONLINE` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__ticket`
--

DROP TABLE IF EXISTS `v__ticket`;
/*!50001 DROP VIEW IF EXISTS `v__ticket`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__ticket` AS SELECT
 1 AS `row_type`,
  1 AS `id`,
  1 AS `order_id`,
  1 AS `stamp`,
  1 AS `table_id`,
  1 AS `qty`,
  1 AS `category`,
  1 AS `name`,
  1 AS `note`,
  1 AS `server`,
  1 AS `client`,
  1 AS `subtotal`,
  1 AS `total`,
  1 AS `bill`,
  1 AS `completed`,
  1 AS `closed`,
  1 AS `prepared` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__tip_2w`
--

DROP TABLE IF EXISTS `v__tip_2w`;
/*!50001 DROP VIEW IF EXISTS `v__tip_2w`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__tip_2w` AS SELECT
 1 AS `DT`,
  1 AS `MANAGER`,
  1 AS `CK`,
  1 AS `LEE` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v__tip_4w`
--

DROP TABLE IF EXISTS `v__tip_4w`;
/*!50001 DROP VIEW IF EXISTS `v__tip_4w`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v__tip_4w` AS SELECT
 1 AS `DT`,
  1 AS `MANAGER`,
  1 AS `CK`,
  1 AS `HE` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `versioninfo`
--

DROP TABLE IF EXISTS `versioninfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `versioninfo` (
  `Version` bigint(20) NOT NULL,
  `AppliedOn` datetime DEFAULT NULL,
  `Description` varchar(1024) CHARACTER SET utf8 DEFAULT NULL,
  UNIQUE KEY `UC_Version` (`Version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `workstation`
--

DROP TABLE IF EXISTS `workstation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `workstation` (
  `IdWorkstation` int(11) NOT NULL AUTO_INCREMENT,
  `IdWorkstationType` int(11) NOT NULL,
  `Serial` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `IP` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`IdWorkstation`),
  UNIQUE KEY `Serial_UNIQUE` (`Serial`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `workstation_type`
--

DROP TABLE IF EXISTS `workstation_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `workstation_type` (
  `IdWorkstationType` int(11) NOT NULL AUTO_INCREMENT,
  `Code` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`IdWorkstationType`),
  UNIQUE KEY `IdWorkstationType_UNIQUE` (`IdWorkstationType`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;


-- Dump completed on 2025-11-21  0:48:33
