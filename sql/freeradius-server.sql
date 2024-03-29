CREATE DATABASE IF NOT EXISTS radius;
USE radius;

CREATE TABLE IF NOT EXISTS radacct (
  radacctid bigint(21) NOT NULL auto_increment,
  acctsessionid varchar(64) NOT NULL default '',
  acctuniqueid varchar(32) NOT NULL default '',
  username varchar(64) NOT NULL default '',
  realm varchar(64) default '',
  nasipaddress varchar(15) NOT NULL default '',
  nasportid varchar(32) default NULL,
  nasporttype varchar(32) default NULL,
  acctstarttime datetime NULL default NULL,
  acctupdatetime datetime NULL default NULL,
  acctstoptime datetime NULL default NULL,
  acctinterval int(12) default NULL,
  acctsessiontime int(12) unsigned default NULL,
  acctauthentic varchar(32) default NULL,
  connectinfo_start varchar(128) default NULL,
  connectinfo_stop varchar(128) default NULL,
  acctinputoctets bigint(20) default NULL,
  acctoutputoctets bigint(20) default NULL,
  calledstationid varchar(50) NOT NULL default '',
  callingstationid varchar(50) NOT NULL default '',
  acctterminatecause varchar(32) NOT NULL default '',
  servicetype varchar(32) default NULL,
  framedprotocol varchar(32) default NULL,
  framedipaddress varchar(15) NOT NULL default '',
  framedipv6address varchar(45) NOT NULL default '',
  framedipv6prefix varchar(45) NOT NULL default '',
  framedinterfaceid varchar(44) NOT NULL default '',
  delegatedipv6prefix varchar(45) NOT NULL default '',
  class varchar(64) default NULL,
  PRIMARY KEY (radacctid),
  UNIQUE KEY acctuniqueid (acctuniqueid),
  KEY username (username),
  KEY framedipaddress (framedipaddress),
  KEY framedipv6address (framedipv6address),
  KEY framedipv6prefix (framedipv6prefix),
  KEY framedinterfaceid (framedinterfaceid),
  KEY delegatedipv6prefix (delegatedipv6prefix),
  KEY acctsessionid (acctsessionid),
  KEY acctsessiontime (acctsessiontime),
  KEY acctstarttime (acctstarttime),
  KEY acctinterval (acctinterval),
  KEY acctstoptime (acctstoptime),
  KEY nasipaddress (nasipaddress),
  KEY class (class)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS radcheck (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

CREATE TABLE IF NOT EXISTS radgroupcheck (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253)  NOT NULL default '',
  PRIMARY KEY  (id),
  KEY groupname (groupname(32))
);

CREATE TABLE IF NOT EXISTS radgroupreply (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253)  NOT NULL default '',
  PRIMARY KEY  (id),
  KEY groupname (groupname(32))
);

CREATE TABLE IF NOT EXISTS radreply (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

CREATE TABLE IF NOT EXISTS radusergroup (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  groupname varchar(64) NOT NULL default '',
  priority int(11) NOT NULL default '1',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

CREATE TABLE IF NOT EXISTS radpostauth (
  id int(11) NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  pass varchar(64) NOT NULL default '',
  reply varchar(32) NOT NULL default '',
  authdate timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  class varchar(64) default NULL,
  PRIMARY KEY  (id),
  KEY username (username),
  KEY class (class)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS nas (
  id int(10) NOT NULL auto_increment,
  nasname varchar(128) NOT NULL,
  shortname varchar(32),
  type varchar(30) DEFAULT 'other',
  ports int(5),
  secret varchar(60) DEFAULT 'secret' NOT NULL,
  server varchar(64),
  community varchar(50),
  description varchar(200) DEFAULT 'RADIUS Client',
  PRIMARY KEY (id),
  KEY nasname (nasname)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS nasreload (
  nasipaddress varchar(15) NOT NULL,
  reloadtime datetime NOT NULL,
  PRIMARY KEY (nasipaddress)
) ENGINE = INNODB;

CREATE USER 'radius'@'localhost' IDENTIFIED BY 'radpass';

GRANT SELECT ON radius.radcheck TO 'radius'@'localhost';
GRANT SELECT ON radius.radreply TO 'radius'@'localhost';
GRANT SELECT ON radius.radusergroup TO 'radius'@'localhost';
GRANT SELECT ON radius.radgroupcheck TO 'radius'@'localhost';
GRANT SELECT ON radius.radgroupreply TO 'radius'@'localhost';
GRANT SELECT, INSERT, UPDATE ON radius.radacct TO 'radius'@'localhost';
GRANT SELECT, INSERT, UPDATE ON radius.radpostauth TO 'radius'@'localhost';
GRANT SELECT ON radius.nas TO 'radius'@'localhost';
GRANT SELECT, INSERT, UPDATE ON radius.nasreload TO 'radius'@'localhost';

CREATE USER 'radius'@'%' IDENTIFIED BY 'radpass';

GRANT SELECT ON radius.radcheck TO 'radius'@'%';
GRANT SELECT ON radius.radreply TO 'radius'@'%';
GRANT SELECT ON radius.radusergroup TO 'radius'@'%';
GRANT SELECT ON radius.radgroupcheck TO 'radius'@'%';
GRANT SELECT ON radius.radgroupreply TO 'radius'@'%';
GRANT SELECT, INSERT, UPDATE ON radius.radacct TO 'radius'@'%';
GRANT SELECT, INSERT, UPDATE ON radius.radpostauth TO 'radius'@'%';
GRANT SELECT ON radius.nas TO 'radius'@'%';
GRANT SELECT, INSERT, UPDATE ON radius.nasreload TO 'radius'@'%';

CREATE TABLE data_usage_by_period (
    username VARCHAR(64),
    period_start DATETIME,
    period_end DATETIME,
    acctinputoctets BIGINT(20),
    acctoutputoctets BIGINT(20),
    PRIMARY KEY (username,period_start)
);
CREATE INDEX idx_data_usage_by_period_period_start ON data_usage_by_period (period_start);
CREATE INDEX idx_data_usage_by_period_period_end ON data_usage_by_period (period_end);

DELIMITER $$

DROP PROCEDURE IF EXISTS fr_new_data_usage_period;
CREATE PROCEDURE fr_new_data_usage_period ()
SQL SECURITY INVOKER
BEGIN

    DECLARE v_start DATETIME;
    DECLARE v_end DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT IFNULL(DATE_ADD(MAX(period_end), INTERVAL 1 SECOND), FROM_UNIXTIME(0)) INTO v_start FROM data_usage_by_period;
    SELECT NOW() INTO v_end;

    START TRANSACTION;

    INSERT INTO data_usage_by_period (username, period_start, period_end, acctinputoctets, acctoutputoctets)
    SELECT *
    FROM (
        SELECT
            username,
            v_start,
            v_end,
            SUM(acctinputoctets) AS acctinputoctets,
            SUM(acctoutputoctets) AS acctoutputoctets
        FROM
            radacct
        WHERE
            acctstoptime > v_start OR
            acctstoptime IS NULL
        GROUP BY
            username
    ) AS s
    ON DUPLICATE KEY UPDATE
        acctinputoctets = data_usage_by_period.acctinputoctets + s.acctinputoctets,
        acctoutputoctets = data_usage_by_period.acctoutputoctets + s.acctoutputoctets,
        period_end = v_end;


    INSERT INTO data_usage_by_period (username, period_start, period_end, acctinputoctets, acctoutputoctets)
    SELECT *
    FROM (
        SELECT
            username,
            DATE_ADD(v_end, INTERVAL 1 SECOND),
            NULL,
            0 - SUM(acctinputoctets),
            0 - SUM(acctoutputoctets)
        FROM
            radacct
        WHERE
            acctstoptime IS NULL
        GROUP BY
            username
    ) AS s;

    COMMIT;

END$$

DELIMITER ;

CREATE VIEW radacct_with_reloads AS
SELECT
    a.*,
    COALESCE(a.acctstoptime,
        IF(a.acctstarttime < n.reloadtime, n.reloadtime, NULL)
    ) AS acctstoptime_with_reloads,
    COALESCE(a.acctsessiontime,
        IF(a.acctstoptime IS NULL AND a.acctstarttime < n.reloadtime,
            UNIX_TIMESTAMP(n.reloadtime) - UNIX_TIMESTAMP(a.acctstarttime), NULL)
    ) AS acctsessiontime_with_reloads
FROM radacct a
LEFT OUTER JOIN nasreload n USING (nasipaddress);


DELIMITER $$

DROP PROCEDURE IF EXISTS fr_radacct_close_after_reload;
CREATE PROCEDURE fr_radacct_close_after_reload ()
SQL SECURITY INVOKER
BEGIN

    DECLARE v_a BIGINT(21);
    DECLARE v_z BIGINT(21);
    DECLARE v_updated BIGINT(21) DEFAULT 0;
    DECLARE v_last_report DATETIME DEFAULT 0;
    DECLARE v_last BOOLEAN DEFAULT FALSE;
    DECLARE v_batch_size INT(12);

    SET v_batch_size = 2500;

    SELECT MIN(radacctid) INTO v_a FROM radacct WHERE acctstoptime IS NULL;

    update_loop: LOOP

        SET v_z = NULL;
        SELECT radacctid INTO v_z FROM radacct WHERE radacctid > v_a ORDER BY radacctid LIMIT v_batch_size,1;

        IF v_z IS NULL THEN
            SELECT MAX(radacctid) INTO v_z FROM radacct;
            SET v_last = TRUE;
        END IF;

        UPDATE radacct a INNER JOIN nasreload n USING (nasipaddress)
        SET
            acctstoptime = n.reloadtime,
            acctsessiontime = UNIX_TIMESTAMP(n.reloadtime) - UNIX_TIMESTAMP(acctstarttime),
            acctterminatecause = 'NAS reboot'
        WHERE
            radacctid BETWEEN v_a AND v_z
            AND acctstoptime IS NULL
            AND acctstarttime < n.reloadtime;

        SET v_updated = v_updated + ROW_COUNT();

        SET v_a = v_z + 1;

        IF v_last_report != NOW() OR v_last THEN
            SELECT v_z AS latest_radacctid, v_updated AS sessions_closed;
            SET v_last_report = NOW();
        END IF;

        IF v_last THEN
            LEAVE update_loop;
        END IF;

    END LOOP;

END$$

DELIMITER ;
