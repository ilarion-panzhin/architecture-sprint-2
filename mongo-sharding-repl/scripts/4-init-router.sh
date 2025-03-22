#!/bin/bash

docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1-1:27018,shard1-2:27020,shard1-3:27021");
sh.addShard("shard2/shard2-1:27019,shard2-2:27022,shard2-3:27023");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });
EOF