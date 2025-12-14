FROM php:5.6-apache

# Enable Apache rewrite module (optional)
RUN a2enmod rewrite

# Set ownership and permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html
