# freeradius-server
This is a repository which contain kubernetes yaml files to bring up freeradius server, include deployment, service, secret and configmap yaml file. There are two choice whether document user information in a file or database.
## service
Current setting provide service via node port with UDP, you can modify service file to fix your need.
## secret
Check secret file to modify clients.conf and authorize settings
## config
Check config map file for radiusd.conf.
