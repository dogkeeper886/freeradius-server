#### Create firewall rule
gcloud compute firewall-rules create test-node-port --allow tcp:NODE_PORT --network NETWORK
gcloud compute firewall-rules create dev-aaa-node-port --allow udp:30223 --network gke-test-network
gcloud compute firewall-rules create dev-acct-node-port --allow udp:31381 --network gke-test-network
30788
gcloud compute firewall-rules create dev-adminer-node-port --allow tcp:30788 --network gke-test-network
