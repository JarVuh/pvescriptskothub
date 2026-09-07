FROM node:20-bookworm-slim

# 1. Устанавливаем все нужные утилиты, инструменты сборки (python/make) и openssl (для БД/Prisma)
RUN apt-get update && \
    apt-get install -y git openssh-client sshpass rsync python3 build-essential openssl && \
    rm -rf /var/lib/apt/lists/*

# 2. Отключаем интерактивный запрос SSH (чтобы rsync/ssh не зависали с вопросом yes/no)
RUN mkdir -p /root/.ssh && \
    echo "StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" > /root/.ssh/config

WORKDIR /app

# Клонируем код
RUN git clone https://github.com/community-scripts/ProxmoxVE-Local.git .

# Устанавливаем зависимости
RUN npm install

# Копируем базовый конфиг
RUN cp .env.example .env

# 3. Принудительно заставляем сервер слушать все интерфейсы, а не только внутренний
ENV HOST=0.0.0.0
ENV PORT=3000

# Собираем проект
RUN npm run build

# Создаем папки для маппинга томов
RUN mkdir -p data scripts && chmod 755 data scripts

EXPOSE 3000

CMD ["npm", "start"]
