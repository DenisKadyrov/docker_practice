#!/bin/bash
# Проверка, передан ли API-ключ
if [ -z "$1" ]; then
  echo "Использование: $0 <API_KEY>"
  exit 1
fi

API_KEY=$1
CONTAINER_NAME="secret-nginx"

# Удаляем контейнер, если он уже существует
docker rm -f $CONTAINER_NAME 2>/dev/null

# Запускаем контейнер nginx с передачей переменной окружения
docker run -d \
  --name $CONTAINER_NAME \
  -e APP_API_TOKEN="$API_KEY" \
  -p 8080:80 \
  nginx

# Ждём немного, чтобы контейнер точно запустился
sleep 2

echo "Контейнер запущен. Проверяем переменную окружения внутри контейнера..."

# Проверка переменной внутри контейнера
docker exec $CONTAINER_NAME printenv APP_API_TOKEN

echo "Готово. Открой http://localhost:8080"
