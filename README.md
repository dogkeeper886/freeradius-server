# freeradius-server
This is a repository which contain kubernetes yaml files to bring up freeradius server, include deployment, service, secret and configmap yaml file. Current setting provide service via node port with UDP, you can modify service file to fix your need. Check secret file to modify clients.conf and authorize settings, check config map file for radiusd.conf.
