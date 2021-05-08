pod_name=$(kubectl get pods | awk '/freeradius-server/{print $1}')

if [ "$pod_name" != "" ]
then
  kubectl exec $pod_name -it -- bash
fi
