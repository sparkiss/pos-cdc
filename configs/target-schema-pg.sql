-- PostgreSQL Target Database Schema
-- Generated from MySQL source with CDC modifications
-- Added: deleted_at column (TIMESTAMPTZ) to all tables
-- Excluded tables: recorded_order, lock, log
-- Type conversions: DATETIME->TIMESTAMPTZ, TINYINT->SMALLINT, etc.

CREATE TABLE IF NOT EXISTS "account" (
  "ID" INTEGER NOT NULL,
  "Account_ID" INTEGER NOT NULL,
  "Name" varchar(64) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "adyen_notification" (
  "ID" INTEGER NOT NULL,
  "PspReference" varchar(50) NOT NULL,
  "OrderId" INTEGER NOT NULL,
  "Success" SMALLINT DEFAULT NULL,
  "Response" varchar(2000) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "barbies" (
  "Id" INTEGER NOT NULL,
  "OrderId" INTEGER NOT NULL,
  "CardNumber" varchar(50) NOT NULL,
  "Points" INTEGER DEFAULT NULL,
  "PointsEarned" INTEGER DEFAULT NULL,
  "PointsValueRedeemed" NUMERIC(19,5) DEFAULT NULL,
  "BirthdayBonusUsed" SMALLINT DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id"),
  UNIQUE ("OrderId")
);

CREATE TABLE IF NOT EXISTS "blobs" (
  "IdWorkstation" INTEGER NOT NULL DEFAULT '0',
  "Name" char(64) NOT NULL,
  "Data" BYTEA,
  "Hash" varchar(255) DEFAULT NULL,
  "LastChange" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Name","IdWorkstation")
);

CREATE TABLE IF NOT EXISTS "call_course" (
  "ID" INTEGER NOT NULL,
  "Table_ID" SMALLINT NOT NULL,
  "Service" SMALLINT NOT NULL,
  "TIMESTAMPTZ" TIMESTAMPTZ NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "cashdrawer" (
  "ID" INTEGER NOT NULL,
  "User_ID" INTEGER NOT NULL,
  "OpenDate" TIMESTAMPTZ NOT NULL,
  "Total" time NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "config" (
  "IdConfig" INTEGER NOT NULL,
  "IdParentConfig" INTEGER DEFAULT NULL,
  "IdWorkstation" INTEGER NOT NULL,
  "Name" varchar(100) DEFAULT NULL,
  "Value" text,
  "Note" varchar(1000) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("IdConfig"),
  UNIQUE ("IdConfig")
);

CREATE TABLE IF NOT EXISTS "datacandy" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL,
  "CardID" varchar(24) NOT NULL,
  "TransactionID" varchar(24) NOT NULL,
  "Amount" NUMERIC(13,4) NOT NULL,
  "PTS" NUMERIC(10,2) NOT NULL,
  "Type" SMALLINT NOT NULL,
  "TIMESTAMPTZ" TIMESTAMPTZ NOT NULL,
  "PRG" SMALLINT NOT NULL,
  "CTM" TEXT NOT NULL,
  "RWEMSG" TEXT NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "delivery_address" (
  "ID" INTEGER NOT NULL,
  "Type" SMALLINT NOT NULL DEFAULT '0',
  "Address" varchar(256) NOT NULL,
  "Corner" TEXT NOT NULL,
  "City" TEXT NOT NULL,
  "Zip" TEXT NOT NULL,
  "Note" TEXT NOT NULL,
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "delivery_client" (
  "ID" INTEGER NOT NULL,
  "Phone_Number" varchar(11) NOT NULL,
  "Profile_ID" varchar(32) NOT NULL,
  "Fullname" TEXT NOT NULL,
  "Attn" TEXT NOT NULL,
  "Memo" TEXT NOT NULL,
  "Note" TEXT NOT NULL,
  "Email" varchar(128) NOT NULL,
  "Flag" TEXT NOT NULL,
  "Allergy" BIGINT NOT NULL DEFAULT '0',
  "Created" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "delivery_order" (
  "ID" INTEGER NOT NULL,
  "Client_ID" INTEGER NOT NULL,
  "Address_ID" INTEGER NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "employeurd_user_mapping" (
  "ID" INTEGER NOT NULL,
  "UserID" INTEGER NOT NULL,
  "ReferenceNumber" INTEGER NOT NULL DEFAULT '0',
  "TeamLead" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "first_nation_certificate" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL,
  "RegistrationNumber" varchar(50) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "geo_caching" (
  "IdGeoCaching" INTEGER NOT NULL,
  "APIProvider" varchar(45) DEFAULT NULL,
  "RequestUriString" varchar(4000) DEFAULT NULL,
  "RequestResponse" varchar(4000) DEFAULT NULL,
  "DateCreated" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("IdGeoCaching"),
  UNIQUE ("IdGeoCaching")
);

CREATE TABLE IF NOT EXISTS "gggolf_member" (
  "ID" INTEGER NOT NULL,
  "MemberID" varchar(16) DEFAULT NULL,
  "Name" varchar(256) DEFAULT NULL,
  "Action" SMALLINT DEFAULT NULL,
  "CreditLimit" NUMERIC(13,4) DEFAULT NULL,
  "Category" INTEGER DEFAULT NULL,
  "PriceList" INTEGER DEFAULT NULL,
  "Tips" SMALLINT DEFAULT NULL,
  "ServiceMandatory" SMALLINT DEFAULT NULL,
  "Service1" SMALLINT DEFAULT NULL,
  "Service2" SMALLINT DEFAULT NULL,
  "Service3" SMALLINT DEFAULT NULL,
  "Service4" SMALLINT DEFAULT NULL,
  "Service5" SMALLINT DEFAULT NULL,
  "AutoDiscount" SMALLINT DEFAULT NULL,
  "ExpirationDate" TIMESTAMPTZ DEFAULT NULL,
  "AutoDiscountCode" INTEGER DEFAULT NULL,
  "UseLimit" SMALLINT DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "gggolf_order_menu" (
  "OrderId" INTEGER NOT NULL,
  "MenuNumber" INTEGER NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("OrderId")
);

CREATE TABLE IF NOT EXISTS "gggolf_station_menu_mapping" (
  "Id" INTEGER NOT NULL,
  "Serial" varchar(45) NOT NULL,
  "MenuNumber" INTEGER NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS "gift_card" (
  "ID" INTEGER NOT NULL,
  "ACTIVE" SMALLINT NOT NULL,
  "CARD_NUMBER_MD5" char(32) NOT NULL,
  "LAST_FOUR_DIGITS" char(4) NOT NULL,
  "AMOUNT" NUMERIC(13,2) NOT NULL,
  "ISSUED_BY" INTEGER NOT NULL,
  "ISSUE_DATE" TIMESTAMPTZ NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "gift_card_sales" (
  "ID" INTEGER NOT NULL,
  "OrderItemId" INTEGER NOT NULL,
  "IntegrationId" INTEGER NOT NULL DEFAULT '0',
  "ActivationDateUtc" TIMESTAMPTZ DEFAULT NULL,
  "ActivationInfo" varchar(500) DEFAULT NULL,
  "Amount" NUMERIC(13,4) NOT NULL,
  "CardNumber" varchar(50) DEFAULT NULL,
  "Failed" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID"),
  UNIQUE ("OrderItemId")
);

CREATE TABLE IF NOT EXISTS "history_combine" (
  "ID" INTEGER NOT NULL,
  "ClientFrom" SMALLINT NOT NULL,
  "Table_ID" SMALLINT NOT NULL,
  "Delivery_ID" INTEGER NOT NULL DEFAULT '0',
  "ItemList" TEXT NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "history_separate" (
  "ID" INTEGER NOT NULL,
  "ClientFrom" SMALLINT NOT NULL,
  "Table_ID" SMALLINT NOT NULL,
  "Delivery_ID" INTEGER NOT NULL DEFAULT '0',
  "ItemIDFrom" INTEGER NOT NULL,
  "ItemIDTo" INTEGER NOT NULL,
  "Action" SMALLINT NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "inventory" (
  "ID" INTEGER NOT NULL,
  "UID" INTEGER NOT NULL,
  "QTY" NUMERIC(13,4) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "inventory_in_out" (
  "ID" INTEGER NOT NULL,
  "UID" INTEGER NOT NULL,
  "QTY" NUMERIC(13,4) NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "itemweight" (
  "Id" INTEGER NOT NULL,
  "ItemId" INTEGER NOT NULL,
  "GrossWeight" NUMERIC(10,4) NOT NULL,
  "TareWeight" NUMERIC(10,4) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS "liquor" (
  "ID" INTEGER NOT NULL,
  "request_id" INTEGER NOT NULL,
  "device_id" INTEGER NOT NULL DEFAULT '0',
  "Item_uid" INTEGER NOT NULL,
  "field_device_type" SMALLINT NOT NULL,
  "pour" INTEGER NOT NULL DEFAULT '0',
  "pour_level" SMALLINT NOT NULL DEFAULT '0',
  "device_time" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "virtual_bar_id" SMALLINT NOT NULL DEFAULT '0',
  "incomplete" SMALLINT NOT NULL DEFAULT '0',
  "type" SMALLINT NOT NULL,
  "IP" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "live_cart_info" (
  "id_live_cart_info" INTEGER NOT NULL,
  "serial" varchar(45) NOT NULL,
  "cart_json" TEXT NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("id_live_cart_info"),
  UNIQUE ("serial")
);

CREATE TABLE IF NOT EXISTS "menu" (
  "IdMenu" INTEGER NOT NULL,
  "XMLMenu" TEXT NOT NULL,
  "Type" varchar(45) DEFAULT NULL,
  "LastChange" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "DateCreated" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "Active" BOOLEAN DEFAULT NULL,
  "Checksum" varchar(100) DEFAULT NULL,
  "IdWorkstation" INTEGER NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("IdMenu"),
  UNIQUE ("Active")
);

CREATE TABLE IF NOT EXISTS "message_queue" (
  "Id" INTEGER NOT NULL,
  "Type" INTEGER DEFAULT NULL,
  "TIMESTAMPTZ" TIMESTAMPTZ DEFAULT NULL,
  "Data" TEXT,
  "Attempts" INTEGER DEFAULT NULL,
  "TargetQueueName" varchar(256) NOT NULL,
  "UniqueId" varchar(256) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS "message_queue_configuration" (
  "Id" INTEGER NOT NULL,
  "TargetQueueName" varchar(256) NOT NULL,
  "QueueUrl" varchar(1024) DEFAULT NULL,
  "AccessKey" varchar(256) DEFAULT NULL,
  "SecretKey" varchar(256) DEFAULT NULL,
  "ServiceUrl" varchar(256) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id"),
  UNIQUE ("TargetQueueName")
);

CREATE TABLE IF NOT EXISTS "mev_transaction" (
  "TransactionId" INTEGER NOT NULL,
  "OrderId" INTEGER NOT NULL,
  "UserId" INTEGER NOT NULL,
  "IdApprl" varchar(14) DEFAULT NULL,
  "TypTrans" varchar(4) DEFAULT NULL,
  "ModTrans" varchar(4) DEFAULT NULL,
  "ModImpr" varchar(4) DEFAULT NULL,
  "Status" varchar(12) DEFAULT NULL,
  "TransactionJson" text,
  "PsiNoTrans" varchar(19) DEFAULT NULL,
  "PsiDatTrans" TIMESTAMPTZ DEFAULT NULL,
  "LotNumber" varchar(10) DEFAULT NULL,
  "LotDate" TIMESTAMPTZ DEFAULT NULL,
  "QRCodeUrl" text,
  "DateCreated" TIMESTAMPTZ DEFAULT NULL,
  "DateProcessed" TIMESTAMPTZ DEFAULT NULL,
  "NoTrans" varchar(50) DEFAULT NULL,
  "Duration" INTEGER DEFAULT NULL,
  "FormImpr" varchar(4) DEFAULT NULL,
  "Amount" NUMERIC(13,4) DEFAULT NULL,
  "Reason" TEXT,
  "DatTrans" TIMESTAMPTZ DEFAULT NULL,
  "ModPai" varchar(3) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("TransactionId")
);

CREATE TABLE IF NOT EXISTS "mews_account_mapping" (
  "mews_account_mapping_id" INTEGER NOT NULL,
  "account_id" INTEGER NOT NULL,
  "mews_account" varchar(100) NOT NULL,
  "mews_account_id" varchar(50) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("mews_account_mapping_id"),
  UNIQUE ("account_id")
);

CREATE TABLE IF NOT EXISTS "mews_tax_mapping" (
  "mews_tax_mapping_id" INTEGER NOT NULL,
  "tax_id" SMALLINT NOT NULL,
  "mews_tax_name" varchar(50) NOT NULL,
  "mews_tax_code" varchar(50) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("mews_tax_mapping_id"),
  UNIQUE ("tax_id")
);

CREATE TABLE IF NOT EXISTS "orders" (
  "ID" INTEGER NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "DateClose" TIMESTAMPTZ NOT NULL,
  "DatePreorder" TIMESTAMPTZ DEFAULT NULL,
  "Table_ID" SMALLINT NOT NULL DEFAULT '0',
  "Client_ID" SMALLINT NOT NULL,
  "User_ID" INTEGER NOT NULL,
  "Delivery_ID" INTEGER NOT NULL,
  "SubTotal" NUMERIC(13,4) NOT NULL,
  "Tax1" NUMERIC(13,4) NOT NULL,
  "Tax2" NUMERIC(13,4) NOT NULL,
  "Tax3" NUMERIC(13,4) NOT NULL,
  "Tax4" NUMERIC(13,4) NOT NULL,
  "Tax5" NUMERIC(13,4) NOT NULL,
  "Tax6" NUMERIC(13,4) NOT NULL,
  "NonTaxable" NUMERIC(13,4) NOT NULL,
  "NonSale" NUMERIC(13,4) NOT NULL,
  "Tax_Rounding" NUMERIC(13,4) NOT NULL,
  "Total" NUMERIC(13,4) NOT NULL,
  "Device" SMALLINT NOT NULL DEFAULT '0',
  "Client_Name" varchar(48) NOT NULL,
  "Profile_ID" varchar(32) NOT NULL,
  "Bill" SMALLINT NOT NULL DEFAULT '0',
  "Completed" SMALLINT NOT NULL DEFAULT '0',
  "Closed" SMALLINT NOT NULL DEFAULT '0',
  "Prepared" SMALLINT NOT NULL,
  "Close_Date" TIMESTAMPTZ DEFAULT NULL,
  "Note" TEXT NOT NULL,
  "Reason" TEXT NOT NULL,
  "Void_By" INTEGER NOT NULL,
  "IP" SMALLINT NOT NULL DEFAULT '0',
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "Online_Client_UID" varchar(50) DEFAULT NULL,
  "License" varchar(20) DEFAULT NULL,
  "IsPreAuthorized" SMALLINT NOT NULL DEFAULT '0',
  "EdgeFee" NUMERIC(13,4) NOT NULL DEFAULT '0.0000',
  "CloseDayID" varchar(100) DEFAULT NULL,
  "MEVTransactionDate" TIMESTAMPTZ DEFAULT NULL,
  "RefundForOrderId" INTEGER DEFAULT NULL,
  "Updated_At" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "External_Id" varchar(50) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_combine" (
  "ID" INTEGER NOT NULL,
  "IDFrom" INTEGER NOT NULL,
  "IDTo" INTEGER NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_discount" (
  "ID" INTEGER NOT NULL,
  "From_ID" INTEGER NOT NULL,
  "From_Type" SMALLINT NOT NULL,
  "Discount_uid" INTEGER NOT NULL,
  "Type" SMALLINT NOT NULL,
  "Value" NUMERIC(13,4) NOT NULL,
  "Name" varchar(32) NOT NULL,
  "Discount_User_ID" INTEGER NOT NULL,
  "Price" NUMERIC(13,4) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_ingredient" (
  "ID" INTEGER NOT NULL,
  "Item_ID" INTEGER NOT NULL DEFAULT '0',
  "Ingredient_uid" INTEGER NOT NULL,
  "Change_uid" INTEGER NOT NULL,
  "Account" INTEGER NOT NULL,
  "Name" varchar(100) NOT NULL,
  "DefaultName" varchar(100) NOT NULL DEFAULT '',
  "Price" NUMERIC(13,4) NOT NULL,
  "PriceEdge" NUMERIC(13,4) NOT NULL,
  "Tax_Type" SMALLINT NOT NULL DEFAULT '31',
  "Qty" SMALLINT NOT NULL DEFAULT '1',
  "Modifier" SMALLINT NOT NULL,
  "Modified" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "PriceLock" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_item" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL DEFAULT '0',
  "Item_uid" INTEGER NOT NULL,
  "Account" INTEGER NOT NULL,
  "Name" varchar(100) NOT NULL,
  "DefaultName" varchar(100) NOT NULL DEFAULT '',
  "Qty" SMALLINT NOT NULL DEFAULT '1',
  "Unit_Qty" NUMERIC(13,4) NOT NULL DEFAULT '1.0000',
  "Unit_Type" SMALLINT NOT NULL DEFAULT '0',
  "Price" NUMERIC(13,4) NOT NULL,
  "PriceEdge" NUMERIC(13,4) NOT NULL,
  "Tax_Type" SMALLINT NOT NULL DEFAULT '31',
  "SplitID" INTEGER NOT NULL DEFAULT '0',
  "SplitBy" SMALLINT NOT NULL DEFAULT '1',
  "Category" varchar(50) NOT NULL DEFAULT '',
  "Combo" INTEGER NOT NULL DEFAULT '0',
  "Service" SMALLINT NOT NULL DEFAULT '0',
  "Type" SMALLINT NOT NULL DEFAULT '0',
  "Printed" SMALLINT NOT NULL DEFAULT '0',
  "PrintDate" TIMESTAMPTZ NOT NULL,
  "Bill" SMALLINT NOT NULL DEFAULT '0',
  "Note" TEXT NOT NULL,
  "Reason" TEXT NOT NULL,
  "Void_By" INTEGER NOT NULL,
  "Modified" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "IsPreAuthorized" SMALLINT NOT NULL DEFAULT '0',
  "PriceLock" SMALLINT NOT NULL DEFAULT '0',
  "ActivitySubSector" varchar(3) NOT NULL DEFAULT '',
  "MealCount" NUMERIC(13,4) DEFAULT NULL,
  "CategoryHierarchy" TEXT NOT NULL,
  "OriginalPrice" NUMERIC(13,4) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_option" (
  "ID" INTEGER NOT NULL,
  "Item_ID" INTEGER NOT NULL DEFAULT '0',
  "Option_uid" INTEGER NOT NULL,
  "Account" INTEGER NOT NULL,
  "Index_ID" SMALLINT NOT NULL,
  "Value" varchar(100) NOT NULL,
  "DefaultName" varchar(100) NOT NULL DEFAULT '',
  "Price" NUMERIC(13,4) NOT NULL,
  "PriceEdge" NUMERIC(13,4) NOT NULL,
  "Tax_Type" SMALLINT NOT NULL DEFAULT '31',
  "Qty" SMALLINT NOT NULL,
  "Type" SMALLINT NOT NULL,
  "Modified" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "PriceLock" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_payment" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL,
  "Method" varchar(20) NOT NULL,
  "Payment" NUMERIC(13,4) NOT NULL,
  "Tip" NUMERIC(13,4) NOT NULL,
  "Balance" NUMERIC(13,4) NOT NULL,
  "Card_Number" varchar(16) NOT NULL,
  "Device" SMALLINT NOT NULL,
  "Language" SMALLINT NOT NULL,
  "Card_Entry_Mode" SMALLINT NOT NULL DEFAULT '0',
  "Approval_Code" varchar(10) NOT NULL,
  "Message" TEXT NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "ConversionRate" NUMERIC(13,4) NOT NULL DEFAULT '1.0000',
  "Currency" varchar(3) NOT NULL,
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "RefCode" varchar(100) NOT NULL DEFAULT '',
  "Type" INTEGER NOT NULL DEFAULT '0',
  "HostCode" varchar(100) NOT NULL DEFAULT '',
  "Edge" INTEGER NOT NULL,
  "Adjusted" SMALLINT NOT NULL,
  "PinpadTransaction" varchar(100) DEFAULT NULL,
  "BatchId" varchar(256) DEFAULT NULL,
  "ProcessorName" varchar(256) DEFAULT NULL,
  "CardReader" varchar(256) DEFAULT NULL,
  "GUID" varchar(50) DEFAULT NULL,
  "TerminalID" varchar(100) DEFAULT NULL,
  "TerminalName" varchar(255) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID"),
  UNIQUE ("GUID")
);

CREATE TABLE IF NOT EXISTS "orders_pre_payment" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER DEFAULT NULL,
  "Transaction_ID" varchar(256) DEFAULT NULL,
  "Sequence" INTEGER DEFAULT NULL,
  "Method" varchar(100) DEFAULT NULL,
  "Operation" varchar(100) DEFAULT NULL,
  "Ammount" varchar(256) DEFAULT NULL,
  "TransactionDate" TIMESTAMPTZ DEFAULT NULL,
  "Active" SMALLINT DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_ref" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL,
  "MEV_REF" INTEGER NOT NULL,
  "MEV_ADDI" INTEGER NOT NULL,
  "MEV_SUB" NUMERIC(13,4) NOT NULL,
  "MEV_DATE" TIMESTAMPTZ NOT NULL,
  "MEV_SUB_PREV" NUMERIC(13,4) NOT NULL,
  "MEV_DATE_PREV" TIMESTAMPTZ NOT NULL,
  "Deleted" SMALLINT NOT NULL,
  "CreatedDate" TIMESTAMPTZ DEFAULT NULL,
  "RefDatTrans" TIMESTAMPTZ DEFAULT NULL,
  "PrintDatTrans" TIMESTAMPTZ DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_transfer_ownership" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL,
  "User_IDBy" INTEGER NOT NULL,
  "User_IDFrom" INTEGER NOT NULL,
  "User_IDTo" INTEGER NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "orders_transfer_table" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER NOT NULL,
  "User_ID_By" INTEGER NOT NULL,
  "Table_ID_From" SMALLINT NOT NULL,
  "Table_ID_To" SMALLINT NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "payout" (
  "ID" INTEGER NOT NULL,
  "SupplierID" INTEGER NOT NULL,
  "Description" TEXT NOT NULL,
  "Amount" NUMERIC(13,4) NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "User_ID" INTEGER NOT NULL,
  "Reason" TEXT NOT NULL,
  "Void_By" INTEGER NOT NULL,
  "Deleted" SMALLINT NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "payout_supplier" (
  "ID" INTEGER NOT NULL,
  "Name" varchar(64) NOT NULL,
  "Deleted" SMALLINT NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "pos_version" (
  "Id_POS_Version" INTEGER NOT NULL,
  "Serial" varchar(45) DEFAULT NULL,
  "Type" varchar(20) DEFAULT NULL,
  "Version" varchar(20) DEFAULT NULL,
  "Date_Created" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id_POS_Version"),
  UNIQUE ("Id_POS_Version")
);

CREATE TABLE IF NOT EXISTS "processor_pendingoperation" (
  "Id" INTEGER NOT NULL,
  "OrderId" INTEGER NOT NULL,
  "OperationData" text NOT NULL,
  "OperationId" varchar(50) NOT NULL,
  "ProcessorName" varchar(50) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS "punch_clock" (
  "ID" INTEGER NOT NULL,
  "User_ID" INTEGER NOT NULL,
  "PunchIn" TIMESTAMPTZ NOT NULL,
  "PunchOut" TIMESTAMPTZ NOT NULL,
  "Salary" NUMERIC(13,2) DEFAULT '0.00',
  "IsManual" SMALLINT NOT NULL,
  "Note" TEXT NOT NULL,
  "users_role_id" INTEGER DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "reservation" (
  "ID" INTEGER NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "DateEnd" TIMESTAMPTZ NOT NULL,
  "FirstName" varchar(64) DEFAULT NULL,
  "LastName" varchar(64) DEFAULT NULL,
  "PhoneNumber" varchar(16) DEFAULT NULL,
  "Email" varchar(128) DEFAULT NULL,
  "Guest" SMALLINT NOT NULL,
  "Table_ID" SMALLINT NOT NULL,
  "Note" TEXT,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "reservation_waitinglist" (
  "ID" INTEGER NOT NULL,
  "Date" TIMESTAMPTZ NOT NULL,
  "Name" varchar(128) NOT NULL,
  "Guest" SMALLINT NOT NULL,
  "Note" TEXT,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "schedule" (
  "ID" INTEGER NOT NULL,
  "DateFrom" TIMESTAMPTZ NOT NULL,
  "TimeTo" time NOT NULL,
  "User_ID" INTEGER NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "session_config" (
  "IdSessionConfig" INTEGER NOT NULL,
  "IdWorkstation" INTEGER NOT NULL,
  "SessionName" varchar(256) NOT NULL,
  "KeyName" varchar(256) NOT NULL,
  "Value" varchar(256) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("IdSessionConfig")
);

CREATE TABLE IF NOT EXISTS "tablesidelog" (
  "Id" INTEGER NOT NULL,
  "TimestampUtc" TIMESTAMPTZ NOT NULL,
  "Level" INTEGER NOT NULL,
  "TerminalName" varchar(64) NOT NULL,
  "Message" varchar(4096) NOT NULL,
  "Attachment" TEXT,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS "tip_distribution" (
  "ID" INTEGER NOT NULL,
  "date_close" TIMESTAMPTZ NOT NULL,
  "users_id" INTEGER NOT NULL,
  "users_role_id" INTEGER NOT NULL,
  "users_role_name" varchar(100) NOT NULL,
  "time_worked" NUMERIC(10,2) NOT NULL,
  "tip" NUMERIC(10,2) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "transaction_payment_response" (
  "ID" INTEGER NOT NULL,
  "Order_ID" INTEGER DEFAULT NULL,
  "Transaction_ID" varchar(256) DEFAULT NULL,
  "TransactionDate" TIMESTAMPTZ DEFAULT NULL,
  "Batch_ID" varchar(256) DEFAULT NULL,
  "Message" varchar(1024) DEFAULT NULL,
  "HostToken" varchar(256) DEFAULT NULL,
  "RequestRefCode" varchar(256) DEFAULT NULL,
  "ApprovalCode" varchar(256) DEFAULT NULL,
  "TransactionType" varchar(256) DEFAULT NULL,
  "TerminalId" varchar(100) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "user_role_tip_distribution" (
  "ID" INTEGER NOT NULL,
  "users_role_id" INTEGER NOT NULL,
  "percent" NUMERIC(10,2) NOT NULL,
  "enter_cash_tip" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "users" (
  "ID" INTEGER NOT NULL,
  "Name" varchar(64) NOT NULL DEFAULT '',
  "Password" varchar(10) NOT NULL DEFAULT '',
  "Level" SMALLINT NOT NULL DEFAULT '0',
  "flags" BIGINT NOT NULL DEFAULT '0',
  "Last_Close" TIMESTAMPTZ NOT NULL,
  "Unlocked" SMALLINT NOT NULL DEFAULT '0',
  "Deleted" SMALLINT NOT NULL DEFAULT '0',
  "Salary" NUMERIC(13,2) NOT NULL,
  "CardNumber" varchar(256) NOT NULL,
  "Phone" varchar(11) NOT NULL,
  "Email" varchar(128) NOT NULL,
  "Birthday" varchar(16) NOT NULL,
  "Language" varchar(14) NOT NULL,
  "FingerPrint1" BYTEA NOT NULL,
  "FingerPrint2" BYTEA NOT NULL,
  "AddedToCloudMEV" BOOLEAN NOT NULL DEFAULT FALSE,
  "DateLastLogin" TIMESTAMPTZ DEFAULT NULL,
  "users_role_id" INTEGER DEFAULT NULL,
  "multirole" SMALLINT NOT NULL DEFAULT '0',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID")
);

CREATE TABLE IF NOT EXISTS "users_role" (
  "ID" INTEGER NOT NULL,
  "users_role_name" varchar(100) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("ID"),
  UNIQUE ("users_role_name")
);

CREATE TABLE IF NOT EXISTS "versioninfo" (
  "Version" BIGINT NOT NULL,
  "AppliedOn" TIMESTAMPTZ DEFAULT NULL,
  "Description" varchar(1024) DEFAULT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  UNIQUE ("Version")
);

CREATE TABLE IF NOT EXISTS "workstation" (
  "IdWorkstation" INTEGER NOT NULL,
  "IdWorkstationType" INTEGER NOT NULL,
  "Serial" varchar(45) DEFAULT NULL,
  "IP" varchar(20) DEFAULT NULL,
  "Active" SMALLINT DEFAULT '1',
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("IdWorkstation"),
  UNIQUE ("Serial")
);

CREATE TABLE IF NOT EXISTS "workstation_type" (
  "IdWorkstationType" INTEGER NOT NULL,
  "Code" varchar(45) NOT NULL,
  "deleted_at" TIMESTAMPTZ NULL DEFAULT NULL,
  PRIMARY KEY ("IdWorkstationType"),
  UNIQUE ("IdWorkstationType")
);


-- Indexes
CREATE INDEX IF NOT EXISTS "idx_account_Account_ID" ON "account" ("Account_ID");
CREATE INDEX IF NOT EXISTS "idx_adyen_notification_IX_AdyenNotification_OrderId" ON "adyen_notification" ("OrderId");
CREATE INDEX IF NOT EXISTS "idx_adyen_notification_IX_AdyenNotification_PspReference" ON "adyen_notification" ("PspReference");
CREATE INDEX IF NOT EXISTS "idx_barbies_IX_Barbies_CardNumber" ON "barbies" ("CardNumber");
CREATE INDEX IF NOT EXISTS "idx_blobs_idx_hash" ON "blobs" ("Hash");
CREATE INDEX IF NOT EXISTS "idx_call_course_Table_ID" ON "call_course" ("Table_ID");
CREATE INDEX IF NOT EXISTS "idx_cashdrawer_OpenDate" ON "cashdrawer" ("OpenDate","User_ID");
CREATE INDEX IF NOT EXISTS "idx_datacandy_Order_ID" ON "datacandy" ("Order_ID");
CREATE INDEX IF NOT EXISTS "idx_datacandy_DateTime" ON "datacandy" ("DateTime");
CREATE INDEX IF NOT EXISTS "idx_delivery_address_Client_ID" ON "delivery_address" ("Deleted");
CREATE INDEX IF NOT EXISTS "idx_delivery_address_Address" ON "delivery_address" ("Address","Deleted");
CREATE INDEX IF NOT EXISTS "idx_delivery_client_Phone_Number" ON "delivery_client" ("Phone_Number","Deleted");
CREATE INDEX IF NOT EXISTS "idx_delivery_client_Email" ON "delivery_client" ("Email","Deleted");
CREATE INDEX IF NOT EXISTS "idx_delivery_order_Client_ID" ON "delivery_order" ("Client_ID");
CREATE INDEX IF NOT EXISTS "idx_delivery_order_Address_ID" ON "delivery_order" ("Address_ID");
CREATE INDEX IF NOT EXISTS "idx_gggolf_member_MemberID" ON "gggolf_member" ("MemberID");
CREATE INDEX IF NOT EXISTS "idx_gggolf_member_IX_gggolf_member_name" ON "gggolf_member" ("Name");
CREATE INDEX IF NOT EXISTS "idx_gift_card_CARD_NUMBER_MD5" ON "gift_card" ("CARD_NUMBER_MD5");
CREATE INDEX IF NOT EXISTS "idx_gift_card_ACTIVE" ON "gift_card" ("ACTIVE");
CREATE INDEX IF NOT EXISTS "idx_history_combine_Table_ID" ON "history_combine" ("Table_ID");
CREATE INDEX IF NOT EXISTS "idx_history_separate_Table_ID" ON "history_separate" ("Table_ID");
CREATE INDEX IF NOT EXISTS "idx_inventory_UID" ON "inventory" ("UID");
CREATE INDEX IF NOT EXISTS "idx_inventory_QTY" ON "inventory" ("QTY");
CREATE INDEX IF NOT EXISTS "idx_inventory_in_out_UID" ON "inventory_in_out" ("UID");
CREATE INDEX IF NOT EXISTS "idx_inventory_in_out_Date" ON "inventory_in_out" ("Date");
CREATE INDEX IF NOT EXISTS "idx_itemweight_IX_ItemWeight_ItemId" ON "itemweight" ("ItemId");
CREATE INDEX IF NOT EXISTS "idx_liquor_device_time" ON "liquor" ("device_time","type");
CREATE INDEX IF NOT EXISTS "idx_mev_transaction_IX_mev_transaction_orderID" ON "mev_transaction" ("OrderId");
CREATE INDEX IF NOT EXISTS "idx_mev_transaction_IX_mev_transaction_DateCreated" ON "mev_transaction" ("DateCreated");
CREATE INDEX IF NOT EXISTS "idx_mev_transaction_IX_mev_transaction_Status" ON "mev_transaction" ("Status");
CREATE INDEX IF NOT EXISTS "idx_mev_transaction_IX_mev_transaction_UserId" ON "mev_transaction" ("UserId");
CREATE INDEX IF NOT EXISTS "idx_mev_transaction_IX_mev_transaction_NoTrans" ON "mev_transaction" ("NoTrans");
CREATE INDEX IF NOT EXISTS "idx_orders_Closed" ON "orders" ("Closed","Deleted","Completed");
CREATE INDEX IF NOT EXISTS "idx_orders_DateClose" ON "orders" ("DateClose","Deleted","Completed");
CREATE INDEX IF NOT EXISTS "idx_orders_Table_ID" ON "orders" ("Table_ID","Deleted","Completed");
CREATE INDEX IF NOT EXISTS "idx_orders_Delivery_ID" ON "orders" ("Delivery_ID");
CREATE INDEX IF NOT EXISTS "idx_orders_IX_orders_user_id" ON "orders" ("User_ID");
CREATE INDEX IF NOT EXISTS "idx_orders_IX_orders_deleted" ON "orders" ("Deleted");
CREATE INDEX IF NOT EXISTS "idx_orders_IX_orders_completed" ON "orders" ("Completed");
CREATE INDEX IF NOT EXISTS "idx_orders_IX_orders_bill" ON "orders" ("Bill");
CREATE INDEX IF NOT EXISTS "idx_orders_combine_IDTo" ON "orders_combine" ("IDTo");
CREATE INDEX IF NOT EXISTS "idx_orders_discount_From_ID" ON "orders_discount" ("From_ID","From_Type");
CREATE INDEX IF NOT EXISTS "idx_orders_ingredient_Account" ON "orders_ingredient" ("Account","Deleted");
CREATE INDEX IF NOT EXISTS "idx_orders_ingredient_Item_ID" ON "orders_ingredient" ("Item_ID","Modifier","Deleted","Price");
CREATE INDEX IF NOT EXISTS "idx_orders_item_Combo" ON "orders_item" ("Combo");
CREATE INDEX IF NOT EXISTS "idx_orders_item_Order_ID" ON "orders_item" ("Order_ID","Type","Deleted","Price");
CREATE INDEX IF NOT EXISTS "idx_orders_item_Account" ON "orders_item" ("Account","Deleted");
CREATE INDEX IF NOT EXISTS "idx_orders_option_Item_ID" ON "orders_option" ("Item_ID","Price");
CREATE INDEX IF NOT EXISTS "idx_orders_option_Account" ON "orders_option" ("Account");
CREATE INDEX IF NOT EXISTS "idx_orders_payment_Order_ID" ON "orders_payment" ("Order_ID","Deleted");
CREATE INDEX IF NOT EXISTS "idx_orders_ref_Order_ID" ON "orders_ref" ("Order_ID","Deleted");
CREATE INDEX IF NOT EXISTS "idx_orders_transfer_ownership_Order_ID" ON "orders_transfer_ownership" ("Order_ID");
CREATE INDEX IF NOT EXISTS "idx_orders_transfer_table_Order_ID" ON "orders_transfer_table" ("Order_ID");
CREATE INDEX IF NOT EXISTS "idx_payout_User_ID" ON "payout" ("User_ID");
CREATE INDEX IF NOT EXISTS "idx_payout_Date" ON "payout" ("Date");
CREATE INDEX IF NOT EXISTS "idx_processor_pendingoperation_IX_processor_pendingoperation_orderid" ON "processor_pendingoperation" ("OrderId");
CREATE INDEX IF NOT EXISTS "idx_processor_pendingoperation_IX_processor_pendingoperation_processorName" ON "processor_pendingoperation" ("ProcessorName");
CREATE INDEX IF NOT EXISTS "idx_punch_clock_User_ID" ON "punch_clock" ("User_ID");
CREATE INDEX IF NOT EXISTS "idx_punch_clock_PunchIn" ON "punch_clock" ("PunchIn");
CREATE INDEX IF NOT EXISTS "idx_punch_clock_PunchOut" ON "punch_clock" ("PunchOut");
CREATE INDEX IF NOT EXISTS "idx_reservation_Date" ON "reservation" ("Date","DateEnd");
CREATE INDEX IF NOT EXISTS "idx_schedule_DateFrom" ON "schedule" ("DateFrom");
CREATE INDEX IF NOT EXISTS "idx_schedule_User_ID" ON "schedule" ("User_ID");
CREATE INDEX IF NOT EXISTS "idx_users_Password" ON "users" ("Password");
CREATE INDEX IF NOT EXISTS "idx_users_Deleted" ON "users" ("Deleted");
