FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./
COPY modules ./modules

ENV PORT=5000
EXPOSE 5000

CMD ["node", "server.js"]
