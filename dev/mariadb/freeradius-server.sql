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