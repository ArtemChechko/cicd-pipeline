FROM node:7.8.0

WORKDIR /opt/app

# 1) Кеш залежностей
COPY package.json package-lock.json* ./
RUN npm install

# 2) Код
COPY . .

EXPOSE 3000

# Важливо: доступ з хоста + порт
ENV HOST=0.0.0.0
ENV PORT=3000
ENV CI=true

CMD ["npm", "start"]