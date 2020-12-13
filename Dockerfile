FROM centos:7
LABEL maintainer="azucena.rosales@gmail.com"

####################
# Systemd cleanup
####################
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

#######################
# Instalación paquetes
#######################
RUN yum install -y bind bind-utils
RUN yum -y install wget
RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN rpm -ivh epel-release-latest-7.noarch.rpm
RUN yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN yum-config-manager --enable remi-php72
RUN yum -y install nano \
	php \
	php-fpm \
	php-common \
	php-mcrypt \
	php-cli  \
	php-curl \
	php-mysql \
	php-xml \
	php-redis \
	php-json \
	php-mbstring \
	php-zip \
	php-devel \
	php-pear \
	php-soap\
	php-tidy \
	php-apcu \
	gcc \
	gcc-c++ \
	autoconf \
	automake \
	git
######################
# Configuracion XDEBUG
######################
#RUN yes | pecl install xdebug \
#    && echo "[xdebug]" > /etc/php.d/20-xdebug.ini \
#    && echo "zend_extension=$(find /usr/lib64/php -name xdebug.so)" >> /etc/php.d/20-xdebug.ini \
#    && echo "xdebug.remote_enable=on" >> /etc/php.d/20-xdebug.ini \
#    && echo "xdebug.remote_autostart=on" >> /etc/php.d/20-xdebug.ini \
#    && echo "xdebug.remote_host=${REMOTE_HOST}" >> /etc/php.d/20-xdebug.ini \
#    && echo "xdebug.idekey = PHPSTORM" >> /etc/php.d/20-xdebug.ini \
#    && echo "xdebug.remote_port = 9000" >> /etc/php.d/20-xdebug.ini

################################
# Directorios web
################################
RUN mkdir -p /var/www/sites
WORKDIR /var/www/sites
RUN useradd -s /bin/bash sites
ADD setup.sh /
RUN echo 'echo ' ${NGINX_HOST} ' nginx >> /etc/hosts' >> /setup.sh
#################
# Config php-fpm
#################
RUN vi -esnc '%s/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/g|:wq' /etc/php-fpm.d/www.conf; \
	vi -esnc '%s/listen.allowed_clients = 127.0.0.1/;listen.allowed_clients = 127.0.0.1/g|:wq' /etc/php-fpm.d/www.conf;  \ 
	echo 'listen.allowed_clients =' ${NGINX_HOST} >> /etc/php-fpm.d/www.conf

###############
# Logs de php
###############
ADD php-fpm/www-error.log /var/log/php-fpm/www-error.log
#RUN chown nginx:nginx /var/log/php-fpm/www-error.log
RUN chmod 777 -R /var/log
RUN echo "php_flag[display_errors] = on" >> /etc/php-fpm.d/www.conf
#RUN echo "php_admin_value[error_log] = /var/log/php-fpm/www-error.log" >> /etc/php-fpm.d/www.conf 
#RUN echo "php_admin_flag[log_errors] = on" >> /etc/php-fpm.d/www.conf 
################
# CURL
################
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

CMD ["/usr/sbin/init"]
