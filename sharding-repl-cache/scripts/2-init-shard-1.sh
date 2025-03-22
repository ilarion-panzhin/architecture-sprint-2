#!/bin/bash

docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
  _id : "shard1",
  members: [
    { _id : 0, host : "shard1-1:27018" },
    { _id : 1, host : "shard1-2:27020" },
    { _id : 2, host : "shard1-3:27021" }
  ]
});
EOF