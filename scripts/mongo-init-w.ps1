﻿$script = @"
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
"@

docker compose exec -T mongodb1 mongosh --eval $script