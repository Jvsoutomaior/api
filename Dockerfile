# Estágio 1: Build
FROM node:18 AS build
# Installing libvips-dev for sharp Compatibility
RUN apt-get update && apt-get install -y build-essential gcc autoconf automake zlib1g-dev libpng-dev nasm bash libvips-dev
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /opt/
COPY package.json package-lock.json* yarn.lock* ./
RUN npm ci

WORKDIR /opt/app
COPY . .
RUN npm run build

# Estágio 2: Produção
FROM node:18-alpine3.18 AS production
# Installing libvips-dev for sharp Compatibility on Alpine
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /opt/
COPY --from=build /opt/package.json ./
COPY --from=build /opt/package-lock.json* ./
COPY --from=build /opt/yarn.lock* ./
RUN npm ci --only=production

WORKDIR /opt/app
COPY --from=build /opt/app/build ./build
COPY --from=build /opt/app/config ./config
COPY --from=build /opt/app/src ./src
COPY --from=build /opt/app/public ./public
RUN mkdir -p /opt/app/public/uploads
COPY --from=build /opt/app/package.json ./package.json

ENV PATH=/opt/node_modules/.bin:$PATH

EXPOSE 1337
CMD ["npm", "run", "start"]
