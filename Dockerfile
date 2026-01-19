FROM php:8.3-apache

# Install required PHP extensions for WordPress
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    curl \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    zip \
    exif \
    opcache \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set PHP configuration with increased limits
RUN echo "upload_max_filesize = 128M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_input_vars = 3000" >> /usr/local/etc/php/conf.d/uploads.ini

# Enable Apache mod_rewrite for pretty permalinks
RUN a2enmod rewrite

# Set recommended PHP.ini settings for WordPress
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Download and install WordPress
RUN curl -o wordpress.tar.gz -fSL https://wordpress.org/latest.tar.gz \
    && tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Create wp-config.php from environment variables
COPY <<EOF /var/www/html/wp-config.php
<?php
define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
define('DB_USER', getenv('WORDPRESS_DB_USER'));
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD'));
define('DB_HOST', getenv('WORDPRESS_DB_HOST'));
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

\$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_';

define('AUTH_KEY',         getenv('AUTH_KEY') ?: 'changeme-auth-key-' . md5(getenv('WORDPRESS_DB_NAME')));
define('SECURE_AUTH_KEY',  getenv('SECURE_AUTH_KEY') ?: 'changeme-secure-auth-' . md5(getenv('WORDPRESS_DB_USER')));
define('LOGGED_IN_KEY',    getenv('LOGGED_IN_KEY') ?: 'changeme-logged-in-' . md5(getenv('WORDPRESS_DB_HOST')));
define('NONCE_KEY',        getenv('NONCE_KEY') ?: 'changeme-nonce-' . md5(getenv('WORDPRESS_DB_PASSWORD')));
define('AUTH_SALT',        getenv('AUTH_SALT') ?: 'changeme-auth-salt-' . md5(getenv('WORDPRESS_DB_NAME') . '1'));
define('SECURE_AUTH_SALT', getenv('SECURE_AUTH_SALT') ?: 'changeme-secure-salt-' . md5(getenv('WORDPRESS_DB_USER') . '2'));
define('LOGGED_IN_SALT',   getenv('LOGGED_IN_SALT') ?: 'changeme-logged-salt-' . md5(getenv('WORDPRESS_DB_HOST') . '3'));
define('NONCE_SALT',       getenv('NONCE_SALT') ?: 'changeme-nonce-salt-' . md5(getenv('WORDPRESS_DB_PASSWORD') . '4'));

define('WP_DEBUG', filter_var(getenv('WP_DEBUG'), FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_LOG', filter_var(getenv('WP_DEBUG'), FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_DISPLAY', false);
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

if (getenv('WP_HOME')) {
    define('WP_HOME', getenv('WP_HOME'));
}
if (getenv('WP_SITEURL')) {
    define('WP_SITEURL', getenv('WP_SITEURL'));
}

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

# Set proper permissions
RUN chown www-data:www-data /var/www/html/wp-config.php

WORKDIR /var/www/html

EXPOSE 80
