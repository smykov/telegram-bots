# Базовый образ
FROM node:18

# Рабочая директория
WORKDIR /app

# Копирование файлов
COPY package*.json ./
COPY bot.js ./
COPY .env ./

# Установка зависимостей
RUN npm install

# Запуск приложения
CMD ["node", "bot.js"]
