#
# GitLab CI: Laravel
#
#
FROM php:8.1.1-fpm
LABEL MAINTAINER="Khin Chan Myae Htun <khinchanmyaehtun@gmail.com>"
ENV PHPREDIS_VERSION 5.3.4
RUN apt-get update &&\
    apt-get -y install sudo 

RUN apt-get update && apt-get upgrade -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpq-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libssl-dev \
    libssl-doc \
    libsasl2-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    zip \
    unzip \
    git \
    vim  
RUN apt-get install -y  gnupg zip libzip-dev libz-dev  coreutils libfreetype6-dev libpng-dev libjpeg-dev libltdl-dev libbz2-dev libpcre3-dev nodejs htop calendar exif apt-transport-https\
&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
&& apt-get update && sudo apt-get install -y yarn npm supervisor
 
RUN docker-php-ext-configure gd \
    --with-jpeg \
    --with-freetype && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)

RUN docker-php-ext-install -j$(nproc) gd pdo pdo_mysql opcache zip calendar exif pcntl \
    && pecl install redis apcu \
    && docker-php-ext-enable redis apcu

RUN rm -rf /var/cache/*

ADD ./php.ini /usr/local/etc/php
ADD ./php.conf /usr/local/etc/php-fpm.d/www.conf

ARG ENABLE_XDEBUG=false

RUN if [ $ENABLE_XDEBUG = "true" ] ; then \
    pecl install xdebug; \
    docker-php-ext-enable xdebug; \
    echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
fi ;

WORKDIR /app

RUN useradd -u 1000 -rm -d /home/nexlabs -g root -G www-data non-rootuser 

USER non-rootuser

RUN mkdir -p /home/non-rootuser/.local/bin && curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/non-rootuser/.local/bin --filename=composer

# Add ~/.local/bin to PATH variable
ENV PATH="$PATH:/home/non-rootuser/.local/bin/"

# Install PhpMetric
RUN composer global require 'phpmetrics/phpmetrics'

