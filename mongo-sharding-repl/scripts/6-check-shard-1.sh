#!/bin/bash

docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
use somedb;
print("Shard1:", db.helloDoc.countDocuments());
EOF