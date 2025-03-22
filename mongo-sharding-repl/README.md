# Настройка шардирования, репликации и кеширования MongoDB

Этот проект демонстрирует, как настроить MongoDB в режиме шардирования с репликацией и кешированием с использованием Docker Compose. Данный README предоставляет пошаговые инструкции для инициализации шардированного кластера с двумя шардовыми репликационными наборами (каждый по 3 узла) и проверки работы приложения.

## Предварительные требования

- Установлены **Docker** и **Docker Compose**
- Директория проекта содержит:
  - `docker-compose.yaml` (с сервисами: `configSrv`, репликационными наборами для `shard1` и `shard2`, а также `mongos_router`)
  - Файлы приложения (`Dockerfile`, `app.py`)
- Установлены переменные окружения для:
  - `MONGODB_URL`
  - `MONGODB_DATABASE_NAME`

> **Примечание:** В данном проекте для каждого шарда настроено 3 реплики:
> - **Shard1:** `shard1-1`, `shard1-2`, `shard1-3`
> - **Shard2:** `shard2-1`, `shard2-2`, `shard2-3`

## Шаг 1: Запуск контейнеров

Поднимите все сервисы с помощью команды:

```bash
docker compose up -d
```

## Шаг 2: Инициализация сервера конфигурации

Подключитесь к серверу конфигурации и инициализируйте набор реплик в режиме конфигурационного сервера:

```bash
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({
  _id : "config_server",
  configsvr: true,
  members: [
    { _id : 0, host : "configSrv:27017" }
  ]
});
EOF
```

## Шаг 3: Инициализация репликационного набора для Shard1

Настройте репликационный набор для Shard1 с тремя участниками. Выполните на первом узле:

```bash
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
```

## Шаг 4: Инициализация репликационного набора для Shard2

Настройте репликационный набор для Shard2 с тремя участниками. Выполните на первом узле:

```bash
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
rs.initiate({
  _id : "shard2",
  members: [
    { _id : 0, host : "shard2-1:27019" },
    { _id : 1, host : "shard2-2:27022" },
    { _id : 2, host : "shard2-3:27023" }
  ]
});
EOF
```

## Шаг 5: Настройка маршрутизатора Mongos

Подключитесь к маршрутизатору mongos_router и добавьте шарды в кластер, затем включите шардирование базы данных и шардируйте коллекцию:

```bash
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1-1:27018,shard1-2:27020,shard1-3:27021");
sh.addShard("shard2/shard2-1:27019,shard2-2:27022,shard2-3:27023");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });
EOF
```

## Шаг 6: Наполнение тестовыми данными

Вставьте 1000 документов в коллекцию helloDoc базы данных somedb:

```bash
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
use somedb;
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}
print("Общее количество документов:", db.helloDoc.countDocuments());
EOF
```

После выполнения скрипта в выводе должна отображаться строка, подтверждающая, что в базе не менее 1000 документов.

## Шаг 7: Проверка распределения данных по шардам

### Проверка Шарда 1

Подключитесь к первому узлу Shard1 и выполните:

```bash
docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
use somedb;
print("Shard1:", db.helloDoc.countDocuments());
EOF
```

### Проверка Шарда 2

Подключитесь к первому узлу Shard2 и выполните:

```bash
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
use somedb;
print("Shard2:", db.helloDoc.countDocuments());
EOF
```

Общее количество документов на шардах (сумма выводов для Shard1 и Shard2) должно составлять 1000.

## Шаг 8: Проверка статуса репликационных наборов

Для проверки, что в каждом наборе по 3 реплики, выполните на одном из узлов каждого репликационного набора:

### Репликационный набор Shard1

```bash
docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
rs.status();
EOF
```

В выводе должно быть видно 3 участника в наборе shard1.

### Репликационный набор Shard2

```bash
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
rs.status();
EOF
```

В выводе должно быть видно 3 участника в наборе shard2.