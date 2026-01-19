FROM wordpress:latest

# Copy custom PHP configuration
COPY <<EOF /usr/local/etc/php/conf.d/custom.ini
upload_max_filesize = 128M
post_max_size = 128M
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
max_input_vars = 3000
EOF

# Ensure Apache can read the files
RUN chown -R www-data:www-data /var/www/html
