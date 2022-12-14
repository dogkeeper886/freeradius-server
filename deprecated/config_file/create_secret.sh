kubectl create secret generic --from-file certs/server.crt --from-file certs/server.pem --from-file clients.conf --from-file authorize server-secret
