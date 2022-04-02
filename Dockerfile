# -------------------
# Build Stage 1 (npm)
# -------------------
FROM node:12-alpine AS appbuild

ENV PYTHONBUFFERED=1
RUN apk add --update --no-cache p7zip chromium python2 make g++ && ln -sf python2 /usr/bin/python
WORKDIR /usr/src/app


COPY . .
RUN npm install
RUN npm run build:prod
# RUN npm run build


# ------------------------
# Build Stage 2 (composer)
# ------------------------
FROM composer:1.9 AS apibuild

WORKDIR /app

COPY ./src/api ./
RUN composer install


# --------------------------
# Build Stage 3 (php-apache)
# This build takes the production build from staging builds
# --------------------------
FROM php:7.3-apache

ENV PROJECT /var/www/html

RUN apt-get update && apt-get install -y sqlite3
RUN a2enmod rewrite expires
# RUN docker-php-ext-install pdo_mysql

# RUN pecl install xdebug && docker-php-ext-enable xdebug
# COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

WORKDIR $PROJECT
COPY --from=appbuild /usr/src/app/dist ./
RUN rm -rf ./api/*
COPY --from=apibuild /app ./api/
RUN chmod 777 ./api
EXPOSE 80
