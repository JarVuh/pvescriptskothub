FROM node:20-bookworm-slim

# 1. Устанавливаем системные зависимости и легковесный init-процесс (tini)
RUN apt-get update && \
    apt-get install -y git openssh-client sshpass rsync python3 build-essential openssl tini && \
    rm -rf /var/lib/apt/lists/*

# 2. Настраиваем SSH-клиент для работы без интерактивных запросов
RUN mkdir -p /root/.ssh && \
    printf "StrictHostKeyChecking no\nUserKnownHostsFile /dev/null\n" > /root/.ssh/config && \
    chmod 700 /root/.ssh

WORKDIR /app

# 3. Клонируем исходный код оригинального приложения
RUN git clone https://github.com .

# 4. Устанавливаем зависимости и копируем дефолтный конфиг окружения
RUN npm install && cp .env.example .env

# 5. Генерируем типы Prisma Client
RUN npx prisma generate

# 6. Задаем переменные окружения для работы в продакшене
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=production

# 7. Собираем Next.js приложение
RUN npm run build

# 8. Объявляем папки как постоянные тома (Volumes)
VOLUME ["/app/data", "/app/scripts"]

# 9. Создаем entrypoint.sh прямо "на лету" внутри Dockerfile
RUN printf '#!/bin/sh\nset -e\necho "Инициализация базы данных SQLite..."\nnpx prisma migrate deploy\necho "Запуск PVE Scripts Local..."\nexec "$@"\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

# Используем tini как PID 1, который корректно пробросит сигналы в entrypoint
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

CMD ["npm", "start"]
