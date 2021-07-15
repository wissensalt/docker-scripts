FROM php:7.2-apache

LABEL "Maintainer"="wissensalt"

COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./start-apache /usr/local/bin

RUN chmod 755 /usr/local/bin/start-apache
RUN chmod -R 765 /var/www

RUN a2enmod rewrite

# Copy application source
COPY ./simple-app /var/www/
RUN chown -R www-data:www-data /var/www

CMD ["start-apache"]
