#!/bin/bash

export DIGITALOCEAN_ACCESS_TOKEN=$DO_TOKEN
export DIGITALOCEAN_SIZE=2gb
export DIGITALOCEAN_PRIVATE_NETWORKING=true

function run_or_exit {
	MSG=$1; CMD=$2;
	echo $MSG;
	echo "$CMD";
	$CMD
	if [ $? -ne 0 ]; then
		echo "Failed with exit status: $?"
		exit 1
	fi
	echo "----"
}

for i in 1 2 3; do 
    run_or_exit "Creating node-$i" "docker-machine create -d digitalocean node-$i"
done

manager_ip=$(docker-machine ssh node-1 ifconfig eth1 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
echo "Manager private ip: $manager_ip"

run_or_exit "Make node-1 the manager/leader" "docker-machine ssh node-1 docker swarm init --advertise-addr ${manager_ip}"

worker_token=$(docker-machine ssh node-1 docker swarm join-token worker -q)
echo "Worker token: $worker_token"

for i in 2 3; do 
    run_or_exit "Join node-$i as worker" "docker-machine ssh node-$i docker swarm join --token ${worker_token} ${manager_ip}:2377"
done

run_or_exit "List swarm nodes" "docker-machine ssh node-1 docker node ls"

eval $(docker-machine env node-1)
run_or_exit "Creating attachable overlay network" "docker network create -d overlay --attachable core-infra"

echo "Done"
