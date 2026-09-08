# 1. Используем Node.js 22+, как требуется в системных требованиях проекта
FROM node:22-bookworm-slim

# 2. Устанавливаем системные зависимости
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    sshpass \
    rsync \
    python3 \
    build-essential \
    openssl && \
    rm -rf /var/lib/apt/lists/*

# 3. Настраиваем SSH для автоматизации (без интерактива)
RUN mkdir -p /root/.ssh && \
    echo "StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" > /root/.ssh/config && \
    chmod 700 /root/.ssh

WORKDIR /app

# 4. Рекомендуемый подход: сначала копируем файлы манифестов для кеширования слоев
COPY package*.json ./

# Устанавливаем зависимости (включая devDependencies для сборки Next.js)
RUN npm install

# 5. Копируем остальной исходный код приложения
COPY . .

# Копируем дефолтный .env, если его нет
RUN cp -n .env.example .env || true

# 6. ВАЖНО: Генерируем Prisma Client перед сборкой приложения
RUN npx prisma generate

# Настройки окружения
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=production

# 7. Собираем Next.js / tRPC приложение
RUN npm run build

# 8. Создаем директории для данных и скриптов
RUN mkdir -p data scripts && chmod 755 data scripts

# Объявляем тома, чтобы SQLite БД и скачанные скрипты не стирались при перезапуске
VOLUME ["/app/data", "/app/scripts"]

EXPOSE 3000

CMD ["npm", "start"]
