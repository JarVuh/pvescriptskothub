#!/bin/sh
set -e

# 1. Накатываем миграции на SQLite (если файла базы данных нет в Volume, он создастся)
echo "Инициализация и проверка структуры базы данных..."
npx prisma migrate deploy

# 2. Передаем управление основному процессу (Next.js)
echo "Запуск PVE Scripts Local..."
exec "$@"
