# Настройка шардирования, репликации и кеширования MongoDB

Этот проект демонстрирует как настроить MongoDB в режиме шардирования с репликацией и кешированием с использованием Docker Compose. Данный README предоставляет пошаговые инструкции для инициализации шардированного кластера.

## Предварительные требования

- Установленные **Docker** и **Docker Compose**
- Директория проекта содержит:
  - `docker-compose.yaml` (с сервисами: `configSrv`, `shard1`, `shard2`, `mongos_router`)
  - Файлы приложения (`Dockerfile`, `app.py`)
- Установлены переменные окружения для:
  - `MONGODB_URL`
  - `MONGODB_DATABASE_NAME`
  - `REDIS_URL` (при использовании кеширования)

## Шаг 1: Запуск контейнеров

Выполните следующую команду в директории вашего проекта:

```bash
docker compose up -d
```

После выполнения команды убедитесь, что все контейнеры (configSrv, shard1, shard2 и mongos_router) запущены.

## Шаг 2: Инициализация сервера конфигурации

Подключитесь к серверу конфигурации и инициализируйте набор реплик в режиме сервера конфигурации:

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

## Шаг 3: Инициализация Шарда 1

Настройте Шард 1 как набор реплик (изначально с одним участником):

```bash
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
  _id : "shard1",
  members: [
    { _id : 0, host : "shard1:27018" }
  ]
});
EOF
```

## Шаг 4: Инициализация Шарда 2

Настройте Шард 2 как набор реплик (изначально с одним участником):

```bash
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({
  _id : "shard2",
  members: [
    { _id : 0, host : "shard2:27019" }
  ]
});
EOF
```

## Шаг 5: Настройка маршрутизатора Mongos

Подключитесь к маршрутизатору mongos, добавьте шарды, включите шардирование базы данных и шардируйте коллекцию:

```bash
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
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
db.helloDoc.countDocuments();
EOF
```

## Шаг 7: Проверка распределения данных

Проверьте, что данные были правильно распределены между шардами.

### Проверка Шарда 1

```bash
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF
```

### Проверка Шарда 2

```bash
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF
```

Общее количество документов из Шарда 1 и Шарда 2 должно в сумме составлять 1000, что свидетельствует о правильной работе шардирования.