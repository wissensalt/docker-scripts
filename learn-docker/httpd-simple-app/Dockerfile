FROM php:7.2-apache

LABEL "Maintainer"="wissensalt"

RUN mkdir -p /etc/httpd/conf/custom

COPY ./preferredserver_name.conf /etc/httpd/conf/custom/

COPY ./simple-app/* /usr/local/apache2/htdocs/apps/simple-app

COPY ./httpd.conf /usr/local/apache2/conf
