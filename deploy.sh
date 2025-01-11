#!/bin/bash

# Параметры для деплоя с дефолтными значениями
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
APP_NAME="${APP_NAME:-telegram-bot}"
WORK_DIR="${WORK_DIR:-$(pwd)}"

# Функция для вывода сообщений
log() {
    echo "[INFO] $1"
}

# 1. Проверка на обязательной переменной: WORK_DIR
if [ -z "$WORK_DIR" ]; then
    echo "[ERROR] Ошибка: WORK_DIR не задан."
    exit 1
fi

# 2. Переход в рабочую директорию
cd "$WORK_DIR" || exit 1

# 3. Обновление репозитория
log "Обновление репозитория..."
git pull origin master

# 4. Проверка наличия файла .env и загрузка переменных
if [ ! -f ".env" ]; then
    log "Файл .env не найден! Создайте файл .env и добавьте BOT_TOKEN и CHAT_ID"
    exit 1
fi

log "Загружаем переменные из .env..."
# 5. Подгружаем переменные окружения из .env
export $(cat .env | grep -v '#' | xargs)

# 6. Проверка на обязательные переменные: BOT_TOKEN и CHAT_ID
if [ -z "$BOT_TOKEN" ]; then
    echo "[ERROR] Ошибка: BOT_TOKEN не задан."
    exit 1
fi

if [ -z "$CHAT_ID" ]; then
    echo "[ERROR] Ошибка: CHAT_ID не задан."
    exit 1
fi

log "Переменные окружения загружены успешно."

# 7. Остановка и удаление старых контейнеров (если они есть)
log "Остановка и удаление старых контейнеров..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down

# 8. Строим и запускаем контейнеры с новым образом
log "Строим и запускаем контейнеры..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up --build -d
if [ $? -ne 0 ]; then
    echo "[ERROR] Ошибка запуска контейнеров! Проверьте лог сборки."
    exit 1
fi

# 9. Ожидание, чтобы контейнеры инициализировались
log "Ожидание инициализации контейнера..."
sleep 5  # Ожидание 5 секунд

# 10. Проверяем логи контейнера на ошибки
log "Проверка логов контейнера..."
CONTAINER_LOGS=$(docker logs "$APP_NAME" 2>&1)

if echo "$CONTAINER_LOGS" | grep -i -q "error"; then
    log "[ERROR] Обнаружена ошибка в логах контейнера."
    log "$CONTAINER_LOGS";
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    echo "[ERROR] Ошибка в логах контейнера. Проверьте их для диагностики."
    exit 1
fi

# 11. Проверка статуса контейнера
for i in {1..5}; do
    container_status=$(docker inspect -f '{{.State.Status}}' "$APP_NAME")
    log "Проверка состояния контейнера: $container_status"

    if [ "$container_status" = "running" ]; then
        log "Контейнер $APP_NAME запущен успешно."
        break
    fi

    log "Контейнер $APP_NAME еще не запущен. Ожидаем..."
    sleep 5  # Задержка перед следующей проверкой
done

if [ "$container_status" != "running" ]; then
    echo "[ERROR] Контейнер $APP_NAME не был запущен."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    exit 1
fi

log "Деплой успешен! Контейнер $APP_NAME работает."
