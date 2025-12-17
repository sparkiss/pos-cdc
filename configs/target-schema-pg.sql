-- PostgreSQL Target Database Schema
-- Generated from MySQL source with CDC modifications
-- Added: deleted_at column (TIMESTAMPTZ) to all tables
-- Excluded tables: recorded_order, lock, log
-- Type conversions: DATETIME->TIMESTAMPTZ, TINYINT->SMALLINT, etc.

CREATE TABLE IF NOT EXISTS account (
  id INTEGER NOT NULL,
  account_id INTEGER NOT NULL,
  name varchar(64) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS adyen_notification (
  id INTEGER NOT NULL,
  pspreference varchar(50) NOT NULL,
  orderid INTEGER NOT NULL,
  success SMALLINT DEFAULT NULL,
  response varchar(2000) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS barbies (
  id INTEGER NOT NULL,
  orderid INTEGER NOT NULL,
  cardnumber varchar(50) NOT NULL,
  points INTEGER DEFAULT NULL,
  pointsearned INTEGER DEFAULT NULL,
  pointsvalueredeemed NUMERIC(19,5) DEFAULT NULL,
  birthdaybonusused SMALLINT DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (orderid)
);

CREATE TABLE IF NOT EXISTS blobs (
  idworkstation INTEGER NOT NULL DEFAULT '0',
  name char(64) NOT NULL,
  data BYTEA,
  hash varchar(255) DEFAULT NULL,
  lastchange TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (name,idworkstation)
);

CREATE TABLE IF NOT EXISTS call_course (
  id INTEGER NOT NULL,
  table_id SMALLINT NOT NULL,
  service SMALLINT NOT NULL,
  TIMESTAMPTZ TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS cashdrawer (
  id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  opendate TIMESTAMPTZ NOT NULL,
  total time NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config (
  idconfig INTEGER NOT NULL,
  idparentconfig INTEGER DEFAULT NULL,
  idworkstation INTEGER NOT NULL,
  name varchar(100) DEFAULT NULL,
  value text,
  note varchar(1000) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (idconfig),
  UNIQUE (idconfig)
);

CREATE TABLE IF NOT EXISTS datacandy (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL,
  cardid varchar(24) NOT NULL,
  transactionid varchar(24) NOT NULL,
  amount NUMERIC(13,4) NOT NULL,
  pts NUMERIC(10,2) NOT NULL,
  type SMALLINT NOT NULL,
  TIMESTAMPTZ TIMESTAMPTZ NOT NULL,
  prg SMALLINT NOT NULL,
  ctm TEXT NOT NULL,
  rwemsg TEXT NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS delivery_address (
  id INTEGER NOT NULL,
  type SMALLINT NOT NULL DEFAULT '0',
  address varchar(256) NOT NULL,
  corner TEXT NOT NULL,
  city TEXT NOT NULL,
  zip TEXT NOT NULL,
  note TEXT NOT NULL,
  deleted SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS delivery_client (
  id INTEGER NOT NULL,
  phone_number varchar(11) NOT NULL,
  profile_id varchar(32) NOT NULL,
  fullname TEXT NOT NULL,
  attn TEXT NOT NULL,
  memo TEXT NOT NULL,
  note TEXT NOT NULL,
  email varchar(128) NOT NULL,
  flag TEXT NOT NULL,
  allergy BIGINT NOT NULL DEFAULT '0',
  created TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS delivery_order (
  id INTEGER NOT NULL,
  client_id INTEGER NOT NULL,
  address_id INTEGER NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS employeurd_user_mapping (
  id INTEGER NOT NULL,
  userid INTEGER NOT NULL,
  referencenumber INTEGER NOT NULL DEFAULT '0',
  teamlead SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS first_nation_certificate (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL,
  registrationnumber varchar(50) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS geo_caching (
  idgeocaching INTEGER NOT NULL,
  apiprovider varchar(45) DEFAULT NULL,
  requesturistring varchar(4000) DEFAULT NULL,
  requestresponse varchar(4000) DEFAULT NULL,
  datecreated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (idgeocaching),
  UNIQUE (idgeocaching)
);

CREATE TABLE IF NOT EXISTS gggolf_member (
  id INTEGER NOT NULL,
  memberid varchar(16) DEFAULT NULL,
  name varchar(256) DEFAULT NULL,
  action SMALLINT DEFAULT NULL,
  creditlimit NUMERIC(13,4) DEFAULT NULL,
  category INTEGER DEFAULT NULL,
  pricelist INTEGER DEFAULT NULL,
  tips SMALLINT DEFAULT NULL,
  servicemandatory SMALLINT DEFAULT NULL,
  service1 SMALLINT DEFAULT NULL,
  service2 SMALLINT DEFAULT NULL,
  service3 SMALLINT DEFAULT NULL,
  service4 SMALLINT DEFAULT NULL,
  service5 SMALLINT DEFAULT NULL,
  autodiscount SMALLINT DEFAULT NULL,
  expirationdate TIMESTAMPTZ DEFAULT NULL,
  autodiscountcode INTEGER DEFAULT NULL,
  uselimit SMALLINT DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS gggolf_order_menu (
  orderid INTEGER NOT NULL,
  menunumber INTEGER NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (orderid)
);

CREATE TABLE IF NOT EXISTS gggolf_station_menu_mapping (
  id INTEGER NOT NULL,
  serial varchar(45) NOT NULL,
  menunumber INTEGER NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS gift_card (
  id INTEGER NOT NULL,
  active SMALLINT NOT NULL,
  card_number_md5 char(32) NOT NULL,
  last_four_digits char(4) NOT NULL,
  amount NUMERIC(13,2) NOT NULL,
  issued_by INTEGER NOT NULL,
  issue_date TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS gift_card_sales (
  id INTEGER NOT NULL,
  orderitemid INTEGER NOT NULL,
  integrationid INTEGER NOT NULL DEFAULT '0',
  activationdateutc TIMESTAMPTZ DEFAULT NULL,
  activationinfo varchar(500) DEFAULT NULL,
  amount NUMERIC(13,4) NOT NULL,
  cardnumber varchar(50) DEFAULT NULL,
  failed SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (orderitemid)
);

CREATE TABLE IF NOT EXISTS history_combine (
  id INTEGER NOT NULL,
  clientfrom SMALLINT NOT NULL,
  table_id SMALLINT NOT NULL,
  delivery_id INTEGER NOT NULL DEFAULT '0',
  itemlist TEXT NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS history_separate (
  id INTEGER NOT NULL,
  clientfrom SMALLINT NOT NULL,
  table_id SMALLINT NOT NULL,
  delivery_id INTEGER NOT NULL DEFAULT '0',
  itemidfrom INTEGER NOT NULL,
  itemidto INTEGER NOT NULL,
  action SMALLINT NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS inventory (
  id INTEGER NOT NULL,
  uid INTEGER NOT NULL,
  qty NUMERIC(13,4) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS inventory_in_out (
  id INTEGER NOT NULL,
  uid INTEGER NOT NULL,
  qty NUMERIC(13,4) NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS itemweight (
  id INTEGER NOT NULL,
  itemid INTEGER NOT NULL,
  grossweight NUMERIC(10,4) NOT NULL,
  tareweight NUMERIC(10,4) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS liquor (
  id INTEGER NOT NULL,
  request_id INTEGER NOT NULL,
  device_id INTEGER NOT NULL DEFAULT '0',
  item_uid INTEGER NOT NULL,
  field_device_type SMALLINT NOT NULL,
  pour INTEGER NOT NULL DEFAULT '0',
  pour_level SMALLINT NOT NULL DEFAULT '0',
  device_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  virtual_bar_id SMALLINT NOT NULL DEFAULT '0',
  incomplete SMALLINT NOT NULL DEFAULT '0',
  type SMALLINT NOT NULL,
  ip SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS live_cart_info (
  id_live_cart_info INTEGER NOT NULL,
  serial varchar(45) NOT NULL,
  cart_json TEXT NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id_live_cart_info),
  UNIQUE (serial)
);

CREATE TABLE IF NOT EXISTS menu (
  idmenu INTEGER NOT NULL,
  xmlmenu TEXT NOT NULL,
  type varchar(45) DEFAULT NULL,
  lastchange TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  datecreated TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN DEFAULT NULL,
  checksum varchar(100) DEFAULT NULL,
  idworkstation INTEGER NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (idmenu),
  UNIQUE (active)
);

CREATE TABLE IF NOT EXISTS message_queue (
  id INTEGER NOT NULL,
  type INTEGER DEFAULT NULL,
  TIMESTAMPTZ TIMESTAMPTZ DEFAULT NULL,
  data TEXT,
  attempts INTEGER DEFAULT NULL,
  targetqueuename varchar(256) NOT NULL,
  uniqueid varchar(256) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS message_queue_configuration (
  id INTEGER NOT NULL,
  targetqueuename varchar(256) NOT NULL,
  queueurl varchar(1024) DEFAULT NULL,
  accesskey varchar(256) DEFAULT NULL,
  secretkey varchar(256) DEFAULT NULL,
  serviceurl varchar(256) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (targetqueuename)
);

CREATE TABLE IF NOT EXISTS mev_transaction (
  transactionid INTEGER NOT NULL,
  orderid INTEGER NOT NULL,
  userid INTEGER NOT NULL,
  idapprl varchar(14) DEFAULT NULL,
  typtrans varchar(4) DEFAULT NULL,
  modtrans varchar(4) DEFAULT NULL,
  modimpr varchar(4) DEFAULT NULL,
  status varchar(12) DEFAULT NULL,
  transactionjson text,
  psinotrans varchar(19) DEFAULT NULL,
  psidattrans TIMESTAMPTZ DEFAULT NULL,
  lotnumber varchar(10) DEFAULT NULL,
  lotdate TIMESTAMPTZ DEFAULT NULL,
  qrcodeurl text,
  datecreated TIMESTAMPTZ DEFAULT NULL,
  dateprocessed TIMESTAMPTZ DEFAULT NULL,
  notrans varchar(50) DEFAULT NULL,
  duration INTEGER DEFAULT NULL,
  formimpr varchar(4) DEFAULT NULL,
  amount NUMERIC(13,4) DEFAULT NULL,
  reason TEXT,
  dattrans TIMESTAMPTZ DEFAULT NULL,
  modpai varchar(3) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (transactionid)
);

CREATE TABLE IF NOT EXISTS mews_account_mapping (
  mews_account_mapping_id INTEGER NOT NULL,
  account_id INTEGER NOT NULL,
  mews_account varchar(100) NOT NULL,
  mews_account_id varchar(50) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (mews_account_mapping_id),
  UNIQUE (account_id)
);

CREATE TABLE IF NOT EXISTS mews_tax_mapping (
  mews_tax_mapping_id INTEGER NOT NULL,
  tax_id SMALLINT NOT NULL,
  mews_tax_name varchar(50) NOT NULL,
  mews_tax_code varchar(50) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (mews_tax_mapping_id),
  UNIQUE (tax_id)
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  dateclose TIMESTAMPTZ NOT NULL,
  datepreorder TIMESTAMPTZ DEFAULT NULL,
  table_id SMALLINT NOT NULL DEFAULT '0',
  client_id SMALLINT NOT NULL,
  user_id INTEGER NOT NULL,
  delivery_id INTEGER NOT NULL,
  subtotal NUMERIC(13,4) NOT NULL,
  tax1 NUMERIC(13,4) NOT NULL,
  tax2 NUMERIC(13,4) NOT NULL,
  tax3 NUMERIC(13,4) NOT NULL,
  tax4 NUMERIC(13,4) NOT NULL,
  tax5 NUMERIC(13,4) NOT NULL,
  tax6 NUMERIC(13,4) NOT NULL,
  nontaxable NUMERIC(13,4) NOT NULL,
  nonsale NUMERIC(13,4) NOT NULL,
  tax_rounding NUMERIC(13,4) NOT NULL,
  total NUMERIC(13,4) NOT NULL,
  device SMALLINT NOT NULL DEFAULT '0',
  client_name varchar(48) NOT NULL,
  profile_id varchar(32) NOT NULL,
  bill SMALLINT NOT NULL DEFAULT '0',
  completed SMALLINT NOT NULL DEFAULT '0',
  closed SMALLINT NOT NULL DEFAULT '0',
  prepared SMALLINT NOT NULL,
  close_date TIMESTAMPTZ DEFAULT NULL,
  note TEXT NOT NULL,
  reason TEXT NOT NULL,
  void_by INTEGER NOT NULL,
  ip SMALLINT NOT NULL DEFAULT '0',
  deleted SMALLINT NOT NULL DEFAULT '0',
  online_client_uid varchar(50) DEFAULT NULL,
  license varchar(20) DEFAULT NULL,
  ispreauthorized SMALLINT NOT NULL DEFAULT '0',
  edgefee NUMERIC(13,4) NOT NULL DEFAULT '0.0000',
  closedayid varchar(100) DEFAULT NULL,
  mevtransactiondate TIMESTAMPTZ DEFAULT NULL,
  refundfororderid INTEGER DEFAULT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  external_id varchar(50) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_combine (
  id INTEGER NOT NULL,
  idfrom INTEGER NOT NULL,
  idto INTEGER NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_discount (
  id INTEGER NOT NULL,
  from_id INTEGER NOT NULL,
  from_type SMALLINT NOT NULL,
  discount_uid INTEGER NOT NULL,
  type SMALLINT NOT NULL,
  value NUMERIC(13,4) NOT NULL,
  name varchar(32) NOT NULL,
  discount_user_id INTEGER NOT NULL,
  price NUMERIC(13,4) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_ingredient (
  id INTEGER NOT NULL,
  item_id INTEGER NOT NULL DEFAULT '0',
  ingredient_uid INTEGER NOT NULL,
  change_uid INTEGER NOT NULL,
  account INTEGER NOT NULL,
  name varchar(100) NOT NULL,
  defaultname varchar(100) NOT NULL DEFAULT '',
  price NUMERIC(13,4) NOT NULL,
  priceedge NUMERIC(13,4) NOT NULL,
  tax_type SMALLINT NOT NULL DEFAULT '31',
  qty SMALLINT NOT NULL DEFAULT '1',
  modifier SMALLINT NOT NULL,
  modified TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted SMALLINT NOT NULL DEFAULT '0',
  pricelock SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_item (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL DEFAULT '0',
  item_uid INTEGER NOT NULL,
  account INTEGER NOT NULL,
  name varchar(100) NOT NULL,
  defaultname varchar(100) NOT NULL DEFAULT '',
  qty SMALLINT NOT NULL DEFAULT '1',
  unit_qty NUMERIC(13,4) NOT NULL DEFAULT '1.0000',
  unit_type SMALLINT NOT NULL DEFAULT '0',
  price NUMERIC(13,4) NOT NULL,
  priceedge NUMERIC(13,4) NOT NULL,
  tax_type SMALLINT NOT NULL DEFAULT '31',
  splitid INTEGER NOT NULL DEFAULT '0',
  splitby SMALLINT NOT NULL DEFAULT '1',
  category varchar(50) NOT NULL DEFAULT '',
  combo INTEGER NOT NULL DEFAULT '0',
  service SMALLINT NOT NULL DEFAULT '0',
  type SMALLINT NOT NULL DEFAULT '0',
  printed SMALLINT NOT NULL DEFAULT '0',
  printdate TIMESTAMPTZ NOT NULL,
  bill SMALLINT NOT NULL DEFAULT '0',
  note TEXT NOT NULL,
  reason TEXT NOT NULL,
  void_by INTEGER NOT NULL,
  modified TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted SMALLINT NOT NULL DEFAULT '0',
  ispreauthorized SMALLINT NOT NULL DEFAULT '0',
  pricelock SMALLINT NOT NULL DEFAULT '0',
  activitysubsector varchar(3) NOT NULL DEFAULT '',
  mealcount NUMERIC(13,4) DEFAULT NULL,
  categoryhierarchy TEXT NOT NULL,
  originalprice NUMERIC(13,4) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_option (
  id INTEGER NOT NULL,
  item_id INTEGER NOT NULL DEFAULT '0',
  option_uid INTEGER NOT NULL,
  account INTEGER NOT NULL,
  index_id SMALLINT NOT NULL,
  value varchar(100) NOT NULL,
  defaultname varchar(100) NOT NULL DEFAULT '',
  price NUMERIC(13,4) NOT NULL,
  priceedge NUMERIC(13,4) NOT NULL,
  tax_type SMALLINT NOT NULL DEFAULT '31',
  qty SMALLINT NOT NULL,
  type SMALLINT NOT NULL,
  modified TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  pricelock SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_payment (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL,
  method varchar(20) NOT NULL,
  payment NUMERIC(13,4) NOT NULL,
  tip NUMERIC(13,4) NOT NULL,
  balance NUMERIC(13,4) NOT NULL,
  card_number varchar(16) NOT NULL,
  device SMALLINT NOT NULL,
  language SMALLINT NOT NULL,
  card_entry_mode SMALLINT NOT NULL DEFAULT '0',
  approval_code varchar(10) NOT NULL,
  message TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  conversionrate NUMERIC(13,4) NOT NULL DEFAULT '1.0000',
  currency varchar(3) NOT NULL,
  deleted SMALLINT NOT NULL DEFAULT '0',
  refcode varchar(100) NOT NULL DEFAULT '',
  type INTEGER NOT NULL DEFAULT '0',
  hostcode varchar(100) NOT NULL DEFAULT '',
  edge INTEGER NOT NULL,
  adjusted SMALLINT NOT NULL,
  pinpadtransaction varchar(100) DEFAULT NULL,
  batchid varchar(256) DEFAULT NULL,
  processorname varchar(256) DEFAULT NULL,
  cardreader varchar(256) DEFAULT NULL,
  guid varchar(50) DEFAULT NULL,
  terminalid varchar(100) DEFAULT NULL,
  terminalname varchar(255) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (guid)
);

CREATE TABLE IF NOT EXISTS orders_pre_payment (
  id INTEGER NOT NULL,
  order_id INTEGER DEFAULT NULL,
  transaction_id varchar(256) DEFAULT NULL,
  sequence INTEGER DEFAULT NULL,
  method varchar(100) DEFAULT NULL,
  operation varchar(100) DEFAULT NULL,
  ammount varchar(256) DEFAULT NULL,
  transactiondate TIMESTAMPTZ DEFAULT NULL,
  active SMALLINT DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_ref (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL,
  mev_ref INTEGER NOT NULL,
  mev_addi INTEGER NOT NULL,
  mev_sub NUMERIC(13,4) NOT NULL,
  mev_date TIMESTAMPTZ NOT NULL,
  mev_sub_prev NUMERIC(13,4) NOT NULL,
  mev_date_prev TIMESTAMPTZ NOT NULL,
  deleted SMALLINT NOT NULL,
  createddate TIMESTAMPTZ DEFAULT NULL,
  refdattrans TIMESTAMPTZ DEFAULT NULL,
  printdattrans TIMESTAMPTZ DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_transfer_ownership (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL,
  user_idby INTEGER NOT NULL,
  user_idfrom INTEGER NOT NULL,
  user_idto INTEGER NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders_transfer_table (
  id INTEGER NOT NULL,
  order_id INTEGER NOT NULL,
  user_id_by INTEGER NOT NULL,
  table_id_from SMALLINT NOT NULL,
  table_id_to SMALLINT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS payout (
  id INTEGER NOT NULL,
  supplierid INTEGER NOT NULL,
  description TEXT NOT NULL,
  amount NUMERIC(13,4) NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  user_id INTEGER NOT NULL,
  reason TEXT NOT NULL,
  void_by INTEGER NOT NULL,
  deleted SMALLINT NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS payout_supplier (
  id INTEGER NOT NULL,
  name varchar(64) NOT NULL,
  deleted SMALLINT NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS pos_version (
  id_pos_version INTEGER NOT NULL,
  serial varchar(45) DEFAULT NULL,
  type varchar(20) DEFAULT NULL,
  version varchar(20) DEFAULT NULL,
  date_created TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id_pos_version),
  UNIQUE (id_pos_version)
);

CREATE TABLE IF NOT EXISTS processor_pendingoperation (
  id INTEGER NOT NULL,
  orderid INTEGER NOT NULL,
  operationdata text NOT NULL,
  operationid varchar(50) NOT NULL,
  processorname varchar(50) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS punch_clock (
  id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  punchin TIMESTAMPTZ NOT NULL,
  punchout TIMESTAMPTZ NOT NULL,
  salary NUMERIC(13,2) DEFAULT '0.00',
  ismanual SMALLINT NOT NULL,
  note TEXT NOT NULL,
  users_role_id INTEGER DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS reservation (
  id INTEGER NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  dateend TIMESTAMPTZ NOT NULL,
  firstname varchar(64) DEFAULT NULL,
  lastname varchar(64) DEFAULT NULL,
  phonenumber varchar(16) DEFAULT NULL,
  email varchar(128) DEFAULT NULL,
  guest SMALLINT NOT NULL,
  table_id SMALLINT NOT NULL,
  note TEXT,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS reservation_waitinglist (
  id INTEGER NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  name varchar(128) NOT NULL,
  guest SMALLINT NOT NULL,
  note TEXT,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS schedule (
  id INTEGER NOT NULL,
  datefrom TIMESTAMPTZ NOT NULL,
  timeto time NOT NULL,
  user_id INTEGER NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS session_config (
  idsessionconfig INTEGER NOT NULL,
  idworkstation INTEGER NOT NULL,
  sessionname varchar(256) NOT NULL,
  keyname varchar(256) NOT NULL,
  value varchar(256) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (idsessionconfig)
);

CREATE TABLE IF NOT EXISTS tablesidelog (
  id INTEGER NOT NULL,
  timestamputc TIMESTAMPTZ NOT NULL,
  level INTEGER NOT NULL,
  terminalname varchar(64) NOT NULL,
  message varchar(4096) NOT NULL,
  attachment TEXT,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS tip_distribution (
  id INTEGER NOT NULL,
  date_close TIMESTAMPTZ NOT NULL,
  users_id INTEGER NOT NULL,
  users_role_id INTEGER NOT NULL,
  users_role_name varchar(100) NOT NULL,
  time_worked NUMERIC(10,2) NOT NULL,
  tip NUMERIC(10,2) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS transaction_payment_response (
  id INTEGER NOT NULL,
  order_id INTEGER DEFAULT NULL,
  transaction_id varchar(256) DEFAULT NULL,
  transactiondate TIMESTAMPTZ DEFAULT NULL,
  batch_id varchar(256) DEFAULT NULL,
  message varchar(1024) DEFAULT NULL,
  hosttoken varchar(256) DEFAULT NULL,
  requestrefcode varchar(256) DEFAULT NULL,
  approvalcode varchar(256) DEFAULT NULL,
  transactiontype varchar(256) DEFAULT NULL,
  terminalid varchar(100) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS user_role_tip_distribution (
  id INTEGER NOT NULL,
  users_role_id INTEGER NOT NULL,
  percent NUMERIC(10,2) NOT NULL,
  enter_cash_tip SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS users (
  id INTEGER NOT NULL,
  name varchar(64) NOT NULL DEFAULT '',
  password varchar(10) NOT NULL DEFAULT '',
  level SMALLINT NOT NULL DEFAULT '0',
  flags BIGINT NOT NULL DEFAULT '0',
  last_close TIMESTAMPTZ NOT NULL,
  unlocked SMALLINT NOT NULL DEFAULT '0',
  deleted SMALLINT NOT NULL DEFAULT '0',
  salary NUMERIC(13,2) NOT NULL,
  cardnumber varchar(256) NOT NULL,
  phone varchar(11) NOT NULL,
  email varchar(128) NOT NULL,
  birthday varchar(16) NOT NULL,
  language varchar(14) NOT NULL,
  fingerprint1 BYTEA NOT NULL,
  fingerprint2 BYTEA NOT NULL,
  addedtocloudmev BOOLEAN NOT NULL DEFAULT FALSE,
  datelastlogin TIMESTAMPTZ DEFAULT NULL,
  users_role_id INTEGER DEFAULT NULL,
  multirole SMALLINT NOT NULL DEFAULT '0',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS users_role (
  id INTEGER NOT NULL,
  users_role_name varchar(100) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (users_role_name)
);

CREATE TABLE IF NOT EXISTS versioninfo (
  version BIGINT NOT NULL,
  appliedon TIMESTAMPTZ DEFAULT NULL,
  description varchar(1024) DEFAULT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  UNIQUE (version)
);

CREATE TABLE IF NOT EXISTS workstation (
  idworkstation INTEGER NOT NULL,
  idworkstationtype INTEGER NOT NULL,
  serial varchar(45) DEFAULT NULL,
  ip varchar(20) DEFAULT NULL,
  active SMALLINT DEFAULT '1',
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (idworkstation),
  UNIQUE (serial)
);

CREATE TABLE IF NOT EXISTS workstation_type (
  idworkstationtype INTEGER NOT NULL,
  code varchar(45) NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NULL,
  PRIMARY KEY (idworkstationtype),
  UNIQUE (idworkstationtype)
);


-- Indexes
CREATE INDEX IF NOT EXISTS idx_account_account_id ON account (account_id);
CREATE INDEX IF NOT EXISTS idx_account_deleted_at ON account (deleted_at);
CREATE INDEX IF NOT EXISTS idx_adyen_notification_ix_adyennotification_orderid ON adyen_notification (orderid);
CREATE INDEX IF NOT EXISTS idx_adyen_notification_ix_adyennotification_pspreference ON adyen_notification (pspreference);
CREATE INDEX IF NOT EXISTS idx_adyen_notification_deleted_at ON adyen_notification (deleted_at);
CREATE INDEX IF NOT EXISTS idx_barbies_ix_barbies_cardnumber ON barbies (cardnumber);
CREATE INDEX IF NOT EXISTS idx_barbies_deleted_at ON barbies (deleted_at);
CREATE INDEX IF NOT EXISTS idx_blobs_idx_hash ON blobs (hash);
CREATE INDEX IF NOT EXISTS idx_blobs_deleted_at ON blobs (deleted_at);
CREATE INDEX IF NOT EXISTS idx_call_course_table_id ON call_course (table_id);
CREATE INDEX IF NOT EXISTS idx_call_course_deleted_at ON call_course (deleted_at);
CREATE INDEX IF NOT EXISTS idx_cashdrawer_opendate ON cashdrawer (opendate,user_id);
CREATE INDEX IF NOT EXISTS idx_cashdrawer_deleted_at ON cashdrawer (deleted_at);
CREATE INDEX IF NOT EXISTS idx_config_deleted_at ON config (deleted_at);
CREATE INDEX IF NOT EXISTS idx_datacandy_order_id ON datacandy (order_id);
CREATE INDEX IF NOT EXISTS idx_datacandy_datetime ON datacandy (datetime);
CREATE INDEX IF NOT EXISTS idx_datacandy_deleted_at ON datacandy (deleted_at);
CREATE INDEX IF NOT EXISTS idx_delivery_address_client_id ON delivery_address (deleted);
CREATE INDEX IF NOT EXISTS idx_delivery_address_address ON delivery_address (address,deleted);
CREATE INDEX IF NOT EXISTS idx_delivery_address_deleted_at ON delivery_address (deleted_at);
CREATE INDEX IF NOT EXISTS idx_delivery_client_phone_number ON delivery_client (phone_number,deleted);
CREATE INDEX IF NOT EXISTS idx_delivery_client_email ON delivery_client (email,deleted);
CREATE INDEX IF NOT EXISTS idx_delivery_client_deleted_at ON delivery_client (deleted_at);
CREATE INDEX IF NOT EXISTS idx_delivery_order_client_id ON delivery_order (client_id);
CREATE INDEX IF NOT EXISTS idx_delivery_order_address_id ON delivery_order (address_id);
CREATE INDEX IF NOT EXISTS idx_delivery_order_deleted_at ON delivery_order (deleted_at);
CREATE INDEX IF NOT EXISTS idx_employeurd_user_mapping_deleted_at ON employeurd_user_mapping (deleted_at);
CREATE INDEX IF NOT EXISTS idx_first_nation_certificate_deleted_at ON first_nation_certificate (deleted_at);
CREATE INDEX IF NOT EXISTS idx_geo_caching_deleted_at ON geo_caching (deleted_at);
CREATE INDEX IF NOT EXISTS idx_gggolf_member_memberid ON gggolf_member (memberid);
CREATE INDEX IF NOT EXISTS idx_gggolf_member_ix_gggolf_member_name ON gggolf_member (name);
CREATE INDEX IF NOT EXISTS idx_gggolf_member_deleted_at ON gggolf_member (deleted_at);
CREATE INDEX IF NOT EXISTS idx_gggolf_order_menu_deleted_at ON gggolf_order_menu (deleted_at);
CREATE INDEX IF NOT EXISTS idx_gggolf_station_menu_mapping_deleted_at ON gggolf_station_menu_mapping (deleted_at);
CREATE INDEX IF NOT EXISTS idx_gift_card_card_number_md5 ON gift_card (card_number_md5);
CREATE INDEX IF NOT EXISTS idx_gift_card_active ON gift_card (active);
CREATE INDEX IF NOT EXISTS idx_gift_card_deleted_at ON gift_card (deleted_at);
CREATE INDEX IF NOT EXISTS idx_gift_card_sales_deleted_at ON gift_card_sales (deleted_at);
CREATE INDEX IF NOT EXISTS idx_history_combine_table_id ON history_combine (table_id);
CREATE INDEX IF NOT EXISTS idx_history_combine_deleted_at ON history_combine (deleted_at);
CREATE INDEX IF NOT EXISTS idx_history_separate_table_id ON history_separate (table_id);
CREATE INDEX IF NOT EXISTS idx_history_separate_deleted_at ON history_separate (deleted_at);
CREATE INDEX IF NOT EXISTS idx_inventory_uid ON inventory (uid);
CREATE INDEX IF NOT EXISTS idx_inventory_qty ON inventory (qty);
CREATE INDEX IF NOT EXISTS idx_inventory_deleted_at ON inventory (deleted_at);
CREATE INDEX IF NOT EXISTS idx_inventory_in_out_uid ON inventory_in_out (uid);
CREATE INDEX IF NOT EXISTS idx_inventory_in_out_date ON inventory_in_out (date);
CREATE INDEX IF NOT EXISTS idx_inventory_in_out_deleted_at ON inventory_in_out (deleted_at);
CREATE INDEX IF NOT EXISTS idx_itemweight_ix_itemweight_itemid ON itemweight (itemid);
CREATE INDEX IF NOT EXISTS idx_itemweight_deleted_at ON itemweight (deleted_at);
CREATE INDEX IF NOT EXISTS idx_liquor_device_time ON liquor (device_time,type);
CREATE INDEX IF NOT EXISTS idx_liquor_deleted_at ON liquor (deleted_at);
CREATE INDEX IF NOT EXISTS idx_live_cart_info_deleted_at ON live_cart_info (deleted_at);
CREATE INDEX IF NOT EXISTS idx_menu_deleted_at ON menu (deleted_at);
CREATE INDEX IF NOT EXISTS idx_message_queue_deleted_at ON message_queue (deleted_at);
CREATE INDEX IF NOT EXISTS idx_message_queue_configuration_deleted_at ON message_queue_configuration (deleted_at);
CREATE INDEX IF NOT EXISTS idx_mev_transaction_ix_mev_transaction_orderid ON mev_transaction (orderid);
CREATE INDEX IF NOT EXISTS idx_mev_transaction_ix_mev_transaction_datecreated ON mev_transaction (datecreated);
CREATE INDEX IF NOT EXISTS idx_mev_transaction_ix_mev_transaction_status ON mev_transaction (status);
CREATE INDEX IF NOT EXISTS idx_mev_transaction_ix_mev_transaction_userid ON mev_transaction (userid);
CREATE INDEX IF NOT EXISTS idx_mev_transaction_ix_mev_transaction_notrans ON mev_transaction (notrans);
CREATE INDEX IF NOT EXISTS idx_mev_transaction_deleted_at ON mev_transaction (deleted_at);
CREATE INDEX IF NOT EXISTS idx_mews_account_mapping_deleted_at ON mews_account_mapping (deleted_at);
CREATE INDEX IF NOT EXISTS idx_mews_tax_mapping_deleted_at ON mews_tax_mapping (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_closed ON orders (closed,deleted,completed);
CREATE INDEX IF NOT EXISTS idx_orders_dateclose ON orders (dateclose,deleted,completed);
CREATE INDEX IF NOT EXISTS idx_orders_table_id ON orders (table_id,deleted,completed);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_id ON orders (delivery_id);
CREATE INDEX IF NOT EXISTS idx_orders_ix_orders_user_id ON orders (user_id);
CREATE INDEX IF NOT EXISTS idx_orders_ix_orders_deleted ON orders (deleted);
CREATE INDEX IF NOT EXISTS idx_orders_ix_orders_completed ON orders (completed);
CREATE INDEX IF NOT EXISTS idx_orders_ix_orders_bill ON orders (bill);
CREATE INDEX IF NOT EXISTS idx_orders_deleted_at ON orders (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_combine_idto ON orders_combine (idto);
CREATE INDEX IF NOT EXISTS idx_orders_combine_deleted_at ON orders_combine (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_discount_from_id ON orders_discount (from_id,from_type);
CREATE INDEX IF NOT EXISTS idx_orders_discount_deleted_at ON orders_discount (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_ingredient_account ON orders_ingredient (account,deleted);
CREATE INDEX IF NOT EXISTS idx_orders_ingredient_item_id ON orders_ingredient (item_id,modifier,deleted,price);
CREATE INDEX IF NOT EXISTS idx_orders_ingredient_deleted_at ON orders_ingredient (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_item_combo ON orders_item (combo);
CREATE INDEX IF NOT EXISTS idx_orders_item_order_id ON orders_item (order_id,type,deleted,price);
CREATE INDEX IF NOT EXISTS idx_orders_item_account ON orders_item (account,deleted);
CREATE INDEX IF NOT EXISTS idx_orders_item_deleted_at ON orders_item (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_option_item_id ON orders_option (item_id,price);
CREATE INDEX IF NOT EXISTS idx_orders_option_account ON orders_option (account);
CREATE INDEX IF NOT EXISTS idx_orders_option_deleted_at ON orders_option (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_payment_order_id ON orders_payment (order_id,deleted);
CREATE INDEX IF NOT EXISTS idx_orders_payment_deleted_at ON orders_payment (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_pre_payment_deleted_at ON orders_pre_payment (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_ref_order_id ON orders_ref (order_id,deleted);
CREATE INDEX IF NOT EXISTS idx_orders_ref_deleted_at ON orders_ref (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_transfer_ownership_order_id ON orders_transfer_ownership (order_id);
CREATE INDEX IF NOT EXISTS idx_orders_transfer_ownership_deleted_at ON orders_transfer_ownership (deleted_at);
CREATE INDEX IF NOT EXISTS idx_orders_transfer_table_order_id ON orders_transfer_table (order_id);
CREATE INDEX IF NOT EXISTS idx_orders_transfer_table_deleted_at ON orders_transfer_table (deleted_at);
CREATE INDEX IF NOT EXISTS idx_payout_user_id ON payout (user_id);
CREATE INDEX IF NOT EXISTS idx_payout_date ON payout (date);
CREATE INDEX IF NOT EXISTS idx_payout_deleted_at ON payout (deleted_at);
CREATE INDEX IF NOT EXISTS idx_payout_supplier_deleted_at ON payout_supplier (deleted_at);
CREATE INDEX IF NOT EXISTS idx_pos_version_deleted_at ON pos_version (deleted_at);
CREATE INDEX IF NOT EXISTS idx_processor_pendingoperation_ix_processor_pendingoperation_orderid ON processor_pendingoperation (orderid);
CREATE INDEX IF NOT EXISTS idx_processor_pendingoperation_ix_processor_pendingoperation_processorname ON processor_pendingoperation (processorname);
CREATE INDEX IF NOT EXISTS idx_processor_pendingoperation_deleted_at ON processor_pendingoperation (deleted_at);
CREATE INDEX IF NOT EXISTS idx_punch_clock_user_id ON punch_clock (user_id);
CREATE INDEX IF NOT EXISTS idx_punch_clock_punchin ON punch_clock (punchin);
CREATE INDEX IF NOT EXISTS idx_punch_clock_punchout ON punch_clock (punchout);
CREATE INDEX IF NOT EXISTS idx_punch_clock_deleted_at ON punch_clock (deleted_at);
CREATE INDEX IF NOT EXISTS idx_reservation_date ON reservation (date,dateend);
CREATE INDEX IF NOT EXISTS idx_reservation_deleted_at ON reservation (deleted_at);
CREATE INDEX IF NOT EXISTS idx_reservation_waitinglist_deleted_at ON reservation_waitinglist (deleted_at);
CREATE INDEX IF NOT EXISTS idx_schedule_datefrom ON schedule (datefrom);
CREATE INDEX IF NOT EXISTS idx_schedule_user_id ON schedule (user_id);
CREATE INDEX IF NOT EXISTS idx_schedule_deleted_at ON schedule (deleted_at);
CREATE INDEX IF NOT EXISTS idx_session_config_deleted_at ON session_config (deleted_at);
CREATE INDEX IF NOT EXISTS idx_tablesidelog_deleted_at ON tablesidelog (deleted_at);
CREATE INDEX IF NOT EXISTS idx_tip_distribution_deleted_at ON tip_distribution (deleted_at);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_response_deleted_at ON transaction_payment_response (deleted_at);
CREATE INDEX IF NOT EXISTS idx_user_role_tip_distribution_deleted_at ON user_role_tip_distribution (deleted_at);
CREATE INDEX IF NOT EXISTS idx_users_password ON users (password);
CREATE INDEX IF NOT EXISTS idx_users_deleted ON users (deleted);
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users (deleted_at);
CREATE INDEX IF NOT EXISTS idx_users_role_deleted_at ON users_role (deleted_at);
CREATE INDEX IF NOT EXISTS idx_versioninfo_deleted_at ON versioninfo (deleted_at);
CREATE INDEX IF NOT EXISTS idx_workstation_deleted_at ON workstation (deleted_at);
CREATE INDEX IF NOT EXISTS idx_workstation_type_deleted_at ON workstation_type (deleted_at);
