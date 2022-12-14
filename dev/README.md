#### Create mariadb config file
kubectl create configmap mariadb --from-file mariadb/freeradius-server.sql
#### Create mariadb secret file
kubectl create secret generic mariadb --from-literal=MARIADB_ROOT_PASSWORD=YOUR_PASSWORD
#### Create freeradius-server config file
kubectl create configmap freeradius-server --from-file raddb/radiusd.conf --from-file raddb/sites-available/default --from-file raddb/sites-available/inner-tunnel --from-file raddb/mods-available/sql
### Create freeradius-server secret file
kubectl create secret generic freeradius-server --from-file raddb/clients.conf
