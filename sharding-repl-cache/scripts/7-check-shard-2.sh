#!/bin/bash

docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
use somedb;
print("Shard2:", db.helloDoc.countDocuments());
EOF