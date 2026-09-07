FROM node:20-bookworm-slim

# Устанавливаем git и необходимые утилиты для работы со скриптами Proxmox
RUN apt-get update && \
    apt-get install -y git openssh-client sshpass rsync && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонируем актуальную версию репозитория
RUN git clone https://github.com/community-scripts/ProxmoxVE-Local.git .

# Устанавливаем зависимости Node.js
RUN npm install

# Копируем конфиг окружения по умолчанию
RUN cp .env.example .env

# Собираем приложение
RUN npm run build

# Создаем директории для базы данных (SQLite) и локальных скриптов
RUN mkdir -p data scripts && chmod 755 data scripts

EXPOSE 3000

# Запускаем приложение
CMD ["npm", "start"]
