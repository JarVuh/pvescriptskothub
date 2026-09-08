FROM node:20-bookworm-slim

# 1. Устанавливаем системные зависимости
RUN apt-get update && \
    apt-get install -y git openssh-client sshpass rsync python3 build-essential openssl tini && \
    rm -rf /var/lib/apt/lists/*

# 2. Настраиваем SSH-клиент
RUN mkdir -p /root/.ssh && \
    printf "StrictHostKeyChecking no\nUserKnownHostsFile /dev/null\n" > /root/.ssh/config && \
    chmod 700 /root/.ssh

WORKDIR /app

# 3. Клонируем исходный код оригинального приложения
RUN git clone https://github.com/community-scripts/ProxmoxVE-Local.git .

# --- НОВЫЙ БЛОК: Патчим чужой код на лету ---
# Записываем твой IP в next.config.js, чтобы убрать ошибку allowedDevOrigins
RUN if [ -f next.config.mjs ]; then \
      sed -i "s/const config = {/const config = {\n  allowedDevOrigins: ['192.168.2.51'],/g" next.config.mjs; \
    elif [ -f next.config.js ]; then \
      sed -i "s/module.exports = {/module.exports = {\n  allowedDevOrigins: ['192.168.2.51'],/g" next.config.js; \
    fi
# -------------------------------------------

# 4. Устанавливаем зависимости и копируем дефолтный конфиг окружения
RUN npm install && cp .env.example .env

# --- НОВЫЙ БЛОК: Жестко задаем путь к базе данных ---
ENV DATABASE_URL="file:/app/data/database.sqlite"
# ----------------------------------------------------

# 5. Генерируем типы Prisma Client
RUN npx prisma generate

# 6. Задаем переменные окружения для работы
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=production

# 7. Собираем Next.js приложение
RUN npm run build

# 8. Объявляем папки как постоянные тома
VOLUME ["/app/data", "/app/scripts"]

# 9. Создаем entrypoint.sh прямо "на лету" (внешний файл entrypoint.sh тебе в репозитории не нужен, так как он создается тут)
RUN printf '#!/bin/sh\nset -e\necho "Инициализация базы данных SQLite..."\nnpx prisma migrate deploy\necho "Запуск PVE Scripts Local..."\nexec "$@"\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

CMD ["npm", "start"]
