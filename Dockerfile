FROM php:8.2-apache

# 1. Dependencias para PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Apache en puerto 8080 (Fly.io)
RUN sed -i 's/Listen 80/Listen 8080/' \
    /etc/apache2/ports.conf \
    /etc/apache2/sites-available/000-default.conf

# 3. DocumentRoot -> /var/www/html/src
ENV APACHE_DOCUMENT_ROOT /var/www/html/src
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf

# 4. Habilitar rewrite (muy común)
RUN a2enmod rewrite

# 5. Copiar proyecto
COPY . /var/www/html/

# 6. Permisos correctos
RUN chown -R www-data:www-data /var/www/html

# 7. Entrypoint seguro (sin errores de Dockerfile)
RUN cat << 'EOF' > /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
set -e

if [ -n "$DATABASE_URL" ]; then
  echo "Verificando base de datos..."
  psql "$DATABASE_URL" -tc "SELECT 1 FROM information_schema.tables LIMIT 1" | grep -q 1 \
    || psql "$DATABASE_URL" -f /var/www/html/sql/init.sql
fi

exec apache2-foreground
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 8. Puerto Fly.io
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
