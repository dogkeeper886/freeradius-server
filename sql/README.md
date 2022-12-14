# document user information in database
This is a repository which contain kubernetes yaml files to bring up freeradius server, include deployment, service, secret and configmap yaml file.
## adminer
For checking mariadb in WEB GUI
## mariadb
For store user information. Run sql file in docker-entrypoint-initdb.d folder to create database, table, and radius user.
### create mariadb config file
kubectl create configmap mariadb --from-file mariadb/freeradius-server.sql
### create mariadb secret file
kubectl create secret generic mariadb --from-literal=MARIADB_ROOT_PASSWORD=YOUR_PASSWORD
### create user and password
USE radius;
INSERT INTO `radcheck` (`username`, `attribute`, `op`, `value`)
VALUES ('USER_NAME', 'NT-Password', ':=', 'NTLM_HASH_PASSWORD');
## freeradius-server
Connect to database which specify in sql file.
### Create freeradius-server config file
kubectl create configmap freeradius-server --from-file raddb/radiusd.conf --from-file raddb/sites-available/default --from-file raddb/sites-available/inner-tunnel --from-file raddb/mods-available/sql
### Create freeradius-server secret file
kubectl create secret generic freeradius-server --from-file raddb/clients.conf
## Create firewall rule
gcloud compute firewall-rules create test-node-port --allow tcp:NODE_PORT --network NETWORK
