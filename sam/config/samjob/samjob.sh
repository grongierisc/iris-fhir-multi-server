#!/bin/sh

# Add default K8 cluster
if [ "$(nslookup sam 2>/dev/null | tail -n 2 | grep 'Address')" ]; then
		echo Adding Cluster etab-default
		curl -X POST -H "Content-Type: application/json" -d '{"name":"etab-cluster","description":"etab-cluster"}' http://SuperUser:SYS@nginx:8080/api/sam/admin/cluster
else
	exit 1
fi

# Find all etab node
I=0
while :
do

	if [ "$(nslookup etab${I} 2>/dev/null | tail -n 2 | grep 'Address')" ]; then
			echo Adding "iris-data-${I}"
			curl -X POST -H "Content-Type: application/json" -d '{"name":"etab-cluster","instance": "etab'${I}':52773","cluster":"1","description":"etab'${I}'"}' "http://SuperUser:SYS@nginx:8080/api/sam/admin/target"
	else
		break
	fi

	I=$((I+1))
done

echo Targets Added