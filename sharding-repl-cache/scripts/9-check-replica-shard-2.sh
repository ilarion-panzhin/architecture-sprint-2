#!/bin/bash

docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
rs.status();
EOF