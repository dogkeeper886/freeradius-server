#### Create mariadb config file
kubectl create configmap mariadb --from-file mariadb/0-start.sql
#### Create freeradius-server config file
kubectl create configmap freeradius-server --from-file raddb/radiusd.conf --from-file raddb/sites-available/default --from-file raddb/sites-available/inner-tunnel --from-file raddb/mods-available/sql
