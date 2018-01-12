# Dependency for php7: libwebp library doesn't work correctly with alpine:v3.3 so we are using alpine:edge
FROM alpine:edge
MAINTAINER tonyisworking

# Install dependencies and small amount of devtools
RUN apk add --update curl bash git openssh-client nano nginx ca-certificates \
    # Libs for php
    libssh2 libpng freetype libjpeg-turbo libgcc libxml2 libstdc++ icu-libs libltdl libmcrypt \
    ncurses \
    # For mail
    msmtp \
    # Install gettext
    gettext \
    # Set timezone according your location
    tzdata && \
    # Upgrade musl
    apk add -u musl && \

    ##
    # Install php7
    # Let's go with the community package
    ##
    apk upgrade -U \
    && apk add --update-cache --repository=http://dl-4.alpinelinux.org/alpine/edge/testing/ \
    php7 php7-fpm php7-json php7-zlib php7-opcache php7-mbstring php7-yaml \
    php7-pdo_mysql php7-mysqli php7-mysqlnd php7-pdo php7-pdo_sqlite php7-sqlite3 \
    php7-gd php7-session php7-curl php7-ctype php7-soap \
    php7-xml php7-simplexml php7-xmlwriter php7-mcrypt php7-tokenizer \
    php7-intl php7-bcmath php7-dom php7-xmlreader php7-openssl php7-phar php7-zip && \

    # Small fixes to php & nginx

    ln -s /etc/php7 /etc/php && \
 #   ln -s /usr/bin/php7 /usr/bin/php && \
    ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
    ln -s /usr/lib/php7 /usr/lib/php && \
    rm -rf /var/log/php7 && \
    mkdir -p /var/log/php/ && \

    # No need for the default configs
    rm -f /etc/php/php-fpm.d/www.conf && \

    # Remove nginx user because we will create a user with correct permissions dynamically
    deluser nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /tmp/nginx/body && \

    # Remove default localhost folder
    rm -rf /var/www/localhost && \

    # Create Folders
    mkdir -p /var/www/picocms && \ 
    mkdir -p /var/www/nginx && \
    mkdir -p /var/www/nginx/server && \
    mkdir -p /var/www/nginx/http && \

    # Remove default crontab
    rm /var/spool/cron/crontabs/root && \

    ##
    # Add S6-overlay to use S6 process manager
    # source: https://github.com/just-containers/s6-overlay/#the-docker-way
    ##
    curl -L https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
    | tar -xvzC /  && \


    ##
    # Install cronlock for running cron correctly with mulitple container setups
    # https://github.com/kvz/cronlock
    ##
    curl -L https://raw.githubusercontent.com/kvz/cronlock/master/cronlock -o /usr/local/bin/cronlock && \
    chmod +rx /usr/local/bin/cronlock && \

    ##
    # Install Composer
    ##
    curl -L -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/local/bin --filename=composer && \
    chmod +rx /usr/local/bin/composer && \
    composer global require hirak/prestissimo && \

    # Remove cache and tmp files
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*


##
# Add Project files like nginx and php-fpm processes and configs
# Also custom scripts and bashrc
##
COPY rootfs/ /

ENV TERM="xterm" \
    PORT="80" \
    CRONLOCK_HOST="" \
    WEB_ROOT="/var/www/picocms/" \
    NGINX_INCLUDE_DIR="/var/www/nginx" \
    NGINX_MAX_BODY_SIZE="64M" \
    NGINX_FASTCGI_TIMEOUT="30" \
    PHP_MEMORY_LIMIT="256M" \
    SMTP_HOST="127.0.0.1" \
    TZ="UTC"


WORKDIR ${WEB_ROOT}
EXPOSE ${PORT}
ENTRYPOINT ["/init"]
