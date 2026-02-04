FROM php:8.2-apache

# 1. Dependencias PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Apache en puerto 8080 (Fly.io)
RUN sed -i 's/Listen 80/Listen 8080/' \
    /etc/apache2/ports.conf \
    /etc/apache2/sites-available/000-default.conf

# 3. Habilitar mod_rewrite
RUN a2enmod rewrite

# 4. Copiar index.php
COPY src/index.php /var/www/html/index.php

# 5. Copiar init.sql
COPY sql/init.sql /sql/init.sql

# 6. Permisos
RUN chown -R www-data:www-data /var/www/html

# 7. Entrypoint que limpia módulos MPM, inicializa la BD y arranca Apache
RUN printf '%s\n' \
'#!/bin/bash' \
'set -e' \
'' \
'# Solución al error de MPM en Railway' \
'a2dismod mpm_event || true' \
'a2enmod mpm_prefork || true' \
'' \
'if [ -n "$DATABASE_URL" ] && [ -f /sql/init.sql ]; then' \
'  echo "Inicializando base de datos..."' \
'  psql "$DATABASE_URL" -f /sql/init.sql || true' \
'fi' \
'' \
'exec apache2-foreground' \
> /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

# Usamos CMD en lugar de ENTRYPOINT para mayor compatibilidad en Railway
CMD ["/usr/local/bin/docker-entrypoint.sh"]
