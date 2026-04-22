#!/bin/bash
# Проверка, передан ли API-ключ
if [ -z "$1" ]; then
  echo "Использование: $0 <API_KEY>"
  exit 1
fi

API_KEY=$1
CONTAINER_NAME="secret-app"
IMAGE_NAME="secret-app:v1"

docker build -t $IMAGE_NAME -f Dockerfile.secret .

# Удаляем контейнер, если он уже существует
docker rm -f $CONTAINER_NAME 2>/dev/null

# Запускаем python server с передачей переменной окружения
docker run -d \
  --name $CONTAINER_NAME \
  -e APP_API_TOKEN="$API_KEY" \
  --memory=64m \
  --cpus=0.5 \
  --read-only \
  --tmpfs /tmp \
  -p 8080:8000 \
  $IMAGE_NAME

# Ждём немного, чтобы контейнер точно запустился
sleep 2

echo "Контейнер запущен. Проверяем переменную окружения внутри контейнера..."

# Проверка переменной внутри контейнера
docker exec $CONTAINER_NAME printenv APP_API_TOKEN

echo "Готово. Открой http://localhost:8080"
