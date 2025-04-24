#!/bin/bash

docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
rs.status();
EOF