FROM php:5.6-apache
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu>

# Add php extensions
RUN docker-php-ext-install mbstring

# Add project from current repo to enable automated build
ADD . /var/www

# Add custom default apache virutal host with combined error and access
# logging to stdout
ADD docker/apache_default /etc/apache2/apache2.conf
ADD docker/php.ini /usr/local/lib/php.ini

# Add custom entrypoint to inject runtime environment variables into
# beanstalk console config
ADD docker/run.sh /usr/local/bin/run

RUN { \
    echo '<FilesMatch \.php$>'; \
    echo '\tSetHandler application/x-httpd-php'; \
    echo '</FilesMatch>'; \
    echo; \
    echo 'DirectoryIndex disabled'; \
    echo 'DirectoryIndex index.php index.html'; \
    echo; \
    echo '<Directory /var/www/>'; \
    echo '\tOptions -Indexes'; \
    echo '\tAllowOverride All'; \
    echo '\tAllow from all'; \
    echo '</Directory>'; \
  } | tee "$APACHE_CONFDIR/conf-available/docker-php.conf" \
  && a2enconf docker-php

# Change ownership for apache happiness & install Composer
RUN chmod 777 /usr/local/bin/run && \
    chown -R www-data:www-data /var/www && \
    chmod 777 /var/www && \
    echo 'docker-php.conf---' && \
    cat /etc/apache2/conf-available/docker-php.conf && \
    a2enmod rewrite

WORKDIR /var/www

CMD ["/usr/local/bin/run"]
