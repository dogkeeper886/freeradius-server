create Database radius;
use radius;

###########################################################################
# $Id: 84846b20c93e92ba785a9f9e49375246309b48b9 $                 #
#                                                                         #
#  schema.sql                       rlm_sql - FreeRADIUS SQL Module       #
#                                                                         #
#     Database schema for MySQL rlm_sql module                            #
#                                                                         #
#     To load:                                                            #
#         mysql -uroot -prootpass radius < schema.sql                     #
#                                                                         #
#                                   Mike Machado <mike@innercite.com>     #
###########################################################################
#
# Table structure for table 'radacct'
#

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

#
# Table structure for table 'radcheck'
#

CREATE TABLE IF NOT EXISTS radcheck (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

#
# Table structure for table 'radgroupcheck'
#

CREATE TABLE IF NOT EXISTS radgroupcheck (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '==',
  value varchar(253)  NOT NULL default '',
  PRIMARY KEY  (id),
  KEY groupname (groupname(32))
);

#
# Table structure for table 'radgroupreply'
#

CREATE TABLE IF NOT EXISTS radgroupreply (
  id int(11) unsigned NOT NULL auto_increment,
  groupname varchar(64) NOT NULL default '',
  attribute varchar(64)  NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253)  NOT NULL default '',
  PRIMARY KEY  (id),
  KEY groupname (groupname(32))
);

#
# Table structure for table 'radreply'
#

CREATE TABLE IF NOT EXISTS radreply (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  attribute varchar(64) NOT NULL default '',
  op char(2) NOT NULL DEFAULT '=',
  value varchar(253) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY username (username(32))
);


#
# Table structure for table 'radusergroup'
#

CREATE TABLE IF NOT EXISTS radusergroup (
  id int(11) unsigned NOT NULL auto_increment,
  username varchar(64) NOT NULL default '',
  groupname varchar(64) NOT NULL default '',
  priority int(11) NOT NULL default '1',
  PRIMARY KEY  (id),
  KEY username (username(32))
);

#
# Table structure for table 'radpostauth'
#
# Note: MySQL versions since 5.6.4 support fractional precision timestamps
#        which we use here. Replace the authdate definition with the following
#        if your software is too old:
#
#   authdate timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
#
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

#
# Table structure for table 'nas'
#
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

#
# Table structure for table 'nasreload'
#
CREATE TABLE IF NOT EXISTS nasreload (
  nasipaddress varchar(15) NOT NULL,
  reloadtime datetime NOT NULL,
  PRIMARY KEY (nasipaddress)
) ENGINE = INNODB;

# -*- text -*-
##
## setup.sql -- MySQL commands for creating the RADIUS user.
##
##	WARNING: You should change 'localhost' and 'radpass'
##		 to something else.  Also update raddb/mods-available/sql
##		 with the new RADIUS password.
##
##	$Id: 5ae98cc204a9b19573e75ba83183f0a2dc93757e $

#
#  Create default administrator for RADIUS
#
CREATE USER 'radius'@'localhost' IDENTIFIED BY 'radpass';

#
#  The server can read the authorisation data
#
GRANT SELECT ON radius.radcheck TO 'radius'@'localhost';
GRANT SELECT ON radius.radreply TO 'radius'@'localhost';
GRANT SELECT ON radius.radusergroup TO 'radius'@'localhost';
GRANT SELECT ON radius.radgroupcheck TO 'radius'@'localhost';
GRANT SELECT ON radius.radgroupreply TO 'radius'@'localhost';

#
#  The server can write accounting and post-auth data
#
GRANT SELECT, INSERT, UPDATE ON radius.radacct TO 'radius'@'localhost';
GRANT SELECT, INSERT, UPDATE ON radius.radpostauth TO 'radius'@'localhost';

#
#  The server can read the NAS data
#
GRANT SELECT ON radius.nas TO 'radius'@'localhost';

#
#  In the case of the "lightweight accounting-on/off" strategy, the server also
#  records NAS reload times
#
GRANT SELECT, INSERT, UPDATE ON radius.nasreload TO 'radius'@'localhost';


CREATE USER 'radius'@'%' IDENTIFIED BY 'radpass';

GRANT SELECT ON radius.radcheck TO 'radius'@'%';
GRANT SELECT ON radius.radreply TO 'radius'@'%';
GRANT SELECT ON radius.radusergroup TO 'radius'@'%';
GRANT SELECT ON radius.radgroupcheck TO 'radius'@'%';
GRANT SELECT ON radius.radgroupreply TO 'radius'@'%';

#
#  The server can write accounting and post-auth data
#
GRANT SELECT, INSERT, UPDATE ON radius.radacct TO 'radius'@'%';
GRANT SELECT, INSERT, UPDATE ON radius.radpostauth TO 'radius'@'%';

#
#  The server can read the NAS data
#
GRANT SELECT ON radius.nas TO 'radius'@'%';

#
#  In the case of the "lightweight accounting-on/off" strategy, the server also
#  records NAS reload times
#
GRANT SELECT, INSERT, UPDATE ON radius.nasreload TO 'radius'@'%';

#  -*- text -*-
#
#  main/mysql/process-radacct.sql -- Schema extensions for processing radacct entries
#
#  $Id: 04c1c5b555f7791df8b84fce402994f8032a0251 $

--  ---------------------------------
--  - Per-user data usage over time -
--  ---------------------------------
--
--  An extension to the standard schema to hold per-user data usage statistics
--  for arbitrary periods.
--
--  The data_usage_by_period table is populated by periodically calling the
--  fr_new_data_usage_period stored procedure.
--
--  This table can be queried in various ways to produce reports of aggregate
--  data use over time. For example, if the fr_new_data_usage_period SP is
--  invoked one per day just after midnight, to produce usage data with daily
--  granularity, then a reasonably accurate monthly bandwidth summary for a
--  given user could be obtained with:
--
--      SELECT
--          DATE_FORMAT(period_start, '%Y-%M') AS month,
--          SUM(acctinputoctets)/1000/1000/1000 AS GB_in,
--          SUM(acctoutputoctets)/1000/1000/1000 AS GB_out
--      FROM
--          data_usage_by_period
--      WHERE
--          username='bob' AND
--          period_end IS NOT NULL
--      GROUP BY
--          YEAR(period_start), MONTH(period_start);
--
--      +----------------+----------------+-----------------+
--      | month          | GB_in          | GB_out          |
--      +----------------+----------------+-----------------+
--      | 2019-July      | 5.782279230000 | 50.545664820000 |
--      | 2019-August    | 4.230543340000 | 48.523096420000 |
--      | 2019-September | 4.847360590000 | 48.631835480000 |
--      | 2019-October   | 6.456763250000 | 51.686231930000 |
--      | 2019-November  | 6.362537730000 | 52.385710570000 |
--      | 2019-December  | 4.301524440000 | 50.762240270000 |
--      | 2020-January   | 5.436280540000 | 49.067775280000 |
--      +----------------+----------------+-----------------+
--      7 rows in set (0.000 sec)
--
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


--
--  Stored procedure that when run with some arbitrary frequency, say
--  once per day by cron, will process the recent radacct entries to extract
--  time-windowed data containing acct{input,output}octets ("data usage") per
--  username, per period.
--
--  Each invocation will create new rows in the data_usage_by_period tables
--  containing the data used by each user since the procedure was last invoked.
--  The intervals do not need to be identical but care should be taken to
--  ensure that the start/end of each period aligns well with any intended
--  reporting intervals.
--
--  It can be invoked by running:
--
--      CALL fr_new_data_usage_period();
--
--
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

    --
    -- Add the data usage for the sessions that were active in the current
    -- period to the table. Include all sessions that finished since the start
    -- of this period as well as those still ongoing.
    --
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

    --
    -- Create an open-ended "next period" for all ongoing sessions and carry a
    -- negative value of their data usage to avoid double-accounting when we
    -- process the next period. Their current data usage has already been
    -- allocated to the current and possibly previous periods.
    --
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


--  ------------------------------------------------------
--  - "Lightweight" Accounting-On/Off strategy resources -
--  ------------------------------------------------------
--
--  The following resources are for use only when the "lightweight"
--  Accounting-On/Off strategy is enabled in queries.conf.
--
--  Instead of bulk closing the radacct sessions belonging to a reloaded NAS,
--  this strategy leaves them open and records the NAS reload time in the
--  nasreload table.
--
--  Where applicable, the onus is on the administator to:
--
--    * Consider the nas reload times when deriving a list of
--      active/inactive sessions, and when determining the duration of sessions
--      interrupted by a NAS reload. (Refer to the view below.)
--
--    * Close the affected sessions out of band. (Refer to the SP below.)
--
--
--  The radacct_with_reloads view presents the radacct table with two additional
--  columns: acctstoptime_with_reloads and acctsessiontime_with_reloads
--
--  Where the session isn't closed (acctstoptime IS NULL), yet it started before
--  the last reload of the NAS (radacct.acctstarttime < nasreload.reloadtime),
--  the derived columns are set based on the reload time of the NAS (effectively
--  the point in time that the session was interrupted.)
--
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


--
--  It may be desirable to periodically "close" radacct sessions belonging to a
--  reloaded NAS, replicating the "bulk close" Accounting-On/Off behaviour,
--  just not in real time.
--
--  The fr_radacct_close_after_reload SP will set radacct.acctstoptime to
--  nasreload.reloadtime, calculate the corresponding radacct.acctsessiontime,
--  and set acctterminatecause to "NAS reboot" for interrupted sessions. It
--  does so in batches, which avoids long-lived locks on the affected rows.
--
--  It can be invoked as follows:
--
--      CALL fr_radacct_close_after_reload();
--
--  Note: This SP walks radacct in strides of v_batch_size. It will typically
--  skip closed and ongoing sessions at a rate significantly faster than
--  100,000 rows per second and process batched updates faster than 20,000
--  orphaned sessions per second. If this isn't fast enough then you should
--  really consider using a custom schema that includes partitioning by
--  nasipaddress or acct{start,stop}time.
--
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

    --
    --  This works for many circumstances
    --
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

        --
        --  Periodically report how far we've got
        --
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
