> Find more examples and short videos on development & deployments with docker, aws etc on [devteds.com](https://devteds.com)

# Consul Cluster on Docker Swarm Cluster

Run consul cluster as containers on swarm cluster. This is an example code created while testing consul on docker swarm and it is very basic.

*Tested on docker version Docker version 17.12.0-ce, build c97c6d6*

## Swarm Cluster
Spin up 3 nodes (droplets) on DigitalOcean and create a swarm cluster of those 3 nodes

Optionally, edit `swarm.sh` to change DigitalOcean droplet configs.

```
export DO_TOKEN=<DigitalOcean API Access Token>
./swarm.sh
```

## Consul Cluster 

Create a consul cluster of 5 nodes/agents (containers),

- Two consul client nodes
- Two consul server nodes
- One consul server node as bootstrap

```
eval $(docker-machine env node-1)
docker stack deploy -c consul.yml kv
```

Verify the stack & agents/containers. There may be some errors before all the nodes in the consul cluster start up and complete leader election. Give it about 30 seconds to gossip and complete leader election.

```
docker stack ps -f "desired-state=running" kv
docker service logs kv_server-bootstrap
docker service logs kv_server
docker service logs kv_client

docker service inspect kv_server-bootstrap
```

## Consul UI

```
open http://$(docker-machine ip node-1):8500/ui
```

## Test Consul CLI

Login to server-bootstrap's container shell

```
# On Swarm Manager Node
eval $(docker-machine env node-1)

# Switch to Consul Server (bootstrap)
consul_node=$(docker stack ps kv | grep server-bootstrap | awk '{print $4}' | head -1)
eval $(docker-machine env "$consul_node")

# Exec into Consul Bootstrap Container
consul_container_id=$(docker ps | grep server-bootstrap | awk '{print $1}' | head -1)
docker exec -ti $consul_container_id /bin/sh
```

Test a few consul commands on server-bootstrap's container shell,

```
consul agent --help
consul info
consul catalog nodes
consul catalog datacenters
consul members
```

Find more commands at https://www.consul.io/docs/commands/index.html


## Clean up

```
docker-machine rm -f node-1 node-2 node-3
```

# More

Visit https://devteds.com for short videos on development / deployment with docker and cloud
