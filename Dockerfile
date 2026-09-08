FROM node:20-bookworm-slim

# Устанавливаем системные зависимости и легковесный init-процесс (tini)
RUN apt-get update && \
    apt-get install -y git openssh-client sshpass rsync python3 build-essential openssl tini && \
    rm -rf /var/lib/apt/lists/*

# Настраиваем SSH-клиент (используем printf, так как echo в sh не понимает \n)
RUN mkdir -p /root/.ssh && \
    printf "StrictHostKeyChecking no\nUserKnownHostsFile /dev/null\n" > /root/.ssh/config && \
    chmod 700 /root/.ssh

WORKDIR /app

# Клонируем репозиторий 
RUN git clone https://github.com .

# Устанавливаем зависимости и копируем дефолтный конфиг
RUN npm install && cp .env.example .env

# Генерируем типы Prisma Client
RUN npx prisma generate

# Задаем окружение
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=production

# Собираем Next.js приложение
RUN npm run build

# Объявляем папки как постоянные тома (Volumes)
VOLUME ["/app/data", "/app/scripts"]

# Копируем наш скрипт запуска
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

# Используем tini как PID 1, который запускает entrypoint
ENTRYPOINT ["/usr/bin/tini", "--", "entrypoint.sh"]

# Команда по умолчанию, которая передастся в entrypoint.sh как параметр "$@"
CMD ["npm", "start"]
