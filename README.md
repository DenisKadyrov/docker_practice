# docker_practice

Практическая работа по контейнеризации и базовым DevSecOps-практикам.

В репозитории собраны решения для двух уровней задания:

- Level 1: базовая докеризация Nginx, ограничения ресурсов, `read-only` и логи через volume
- Level 2: сканирование образа, работа с секретами, стек через Compose и запуск Nginx без `root`

## Состав репозитория

- `Dockerfile` - базовый образ Nginx для заданий 1.2-1.4
- `Dockerfile.nonroot` - non-root вариант для задания 2.4
- `Dockerfile.secret` - образ Python-приложения для задания 2.2
- `index.html` - кастомная страница практики
- `nginx.nonroot.conf` - конфиг Nginx для non-root запуска
- `docker-compose.yml` - стек `web + db` для задания 2.3
- `.env.example` - шаблон переменных окружения для PostgreSQL
- `scripts/run_read_only.sh` - пример безопасного запуска для задания 1.3-1.4
- `scripts/run_secret_app.sh` - запуск приложения с передачей секрета для задания 2.2
- `server.py` - простой HTTP-сервер, который читает `APP_API_TOKEN`
- `security_scan.txt` - отчёт по Trivy для задания 2.1

## Уровень 1

### 1.1 Докеризация веб-сервера

Сборка образа:

```bash
docker build -t my-nginx-practice:v1 .
```

Запуск базовой версии:

```bash
docker run --name my-nginx-basic -p 8080:80 my-nginx-practice:v1
```

Проверка:

```bash
curl http://localhost:8080
```

Остановка:

```bash
docker rm -f my-nginx-basic
```

### 1.3 Безопасный запуск

Для задания с ограничениями ресурсов и `read-only` используется скрипт:

```bash
./scripts/run_read_only.sh
```

Что делает скрипт:

- запускает контейнер в фоне
- ограничивает память до `50m`
- ограничивает CPU до `0.5`
- включает `--read-only`
- добавляет `tmpfs` для временных директорий
- монтирует папку `nginx_logs` в `/var/log/nginx`

### 1.4 Работа с логами

Для сохранения логов на хосте используется директория `nginx_logs`.

Если директории ещё нет, её можно создать вручную:

```bash
mkdir -p nginx_logs
```

После запуска контейнера нужно сделать несколько запросов:

```bash
curl http://localhost:8080
curl http://localhost:8080
```

После этого в `nginx_logs` должны появиться файлы:

- `access.log`
- `error.log`

Проверки:

```bash
docker inspect my-nginx-practice
docker stats --no-stream my-nginx-practice
curl http://localhost:8080
ls -l nginx_logs
```

Остановка:

```bash
docker rm -f my-nginx-practice
```

## Уровень 2

### 2.1 Анализ безопасности образа

Сканирование выполнялось командой:

```bash
trivy image nginx:alpine
```

Результат и рекомендации сохранены в файле [security_scan.txt](./security_scan.txt).

### 2.2 Работа с секретами

Для демонстрации передачи секрета используется `Python`-приложение из `Dockerfile.secret`.

Запуск:

```bash
./scripts/run_secret_app.sh my-super-secret-key
```

Что делает скрипт:

- собирает образ `secret-app:v1`
- запускает контейнер `secret-app`
- передаёт секрет через переменную окружения `APP_API_TOKEN`
- проверяет наличие переменной через `docker exec printenv`

Проверки:

```bash
docker exec secret-app printenv APP_API_TOKEN
curl http://localhost:8080
```

Примечание:

- перед запуском задания 2.2 нужно остановить другие контейнеры, занявшие `localhost:8080`

Остановка:

```bash
docker rm -f secret-app
```

### 2.3 Подъём стека через Compose

Файл [docker-compose.yml](./docker-compose.yml) поднимает два сервиса:

- `web` - Nginx с кастомной страницей
- `db` - PostgreSQL 15

Что реализовано:

- БД не пробрасывает порт на хост
- пароль БД берётся из `.env`
- данные БД хранятся в named volume `postgres_data`
- `web` работает в изолированной внутренней сети `backend`
- `web` использует hardened non-root образ из `Dockerfile.nonroot`

Перед запуском нужно создать локальный файл `.env` по шаблону:

```bash
cp .env.example .env
```

Запуск стека:

```bash
docker compose up -d --build
```

Проверки:

```bash
curl http://localhost:8080
docker ps
docker volume ls
docker exec my-postgres-db pg_isready -U practice_user -d practice_db
```

Подключение к PostgreSQL через `psql`:

```bash
docker exec -it my-postgres-db sh -lc 'export PGPASSWORD="$POSTGRES_PASSWORD"; psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Остановка стека:

```bash
docker compose down
```

### 2.4 Принцип наименьших привилегий

Для задания используется [Dockerfile.nonroot](./Dockerfile.nonroot).

Что реализовано:

- создаётся непривилегированный пользователь `appuser`
- Nginx запускается от `appuser`
- Nginx слушает порт `8080` внутри контейнера
- используется отдельный конфиг `nginx.nonroot.conf`
- логи направляются в `stdout/stderr`
- временные файлы и `pid` размещаются в `/tmp`

Сборка:

```bash
docker build -f Dockerfile.nonroot -t my-nginx-practice:nonroot .
```

Запуск:

```bash
docker run -d \
  --name my-nginx-nonroot \
  -p 8080:8080 \
  --read-only \
  --tmpfs /tmp \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  my-nginx-practice:nonroot
```

Проверки:

```bash
curl http://localhost:8080
docker exec my-nginx-nonroot ps aux
docker logs my-nginx-nonroot
```

Остановка:

```bash
docker rm -f my-nginx-nonroot
```

