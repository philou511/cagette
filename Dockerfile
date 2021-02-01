FROM node:15.7-buster-slim

# apache setup copied from https://github.com/codeurs/dockerfiles/blob/master/mod-neko/Dockerfile
RUN apt-get update && apt-get install -y git curl imagemagick apache2 haxe libapache2-mod-neko && apt-get clean

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# redirect all logs to stdtout
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log

RUN a2enmod rewrite
RUN a2enmod neko

RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

COPY apache.conf /etc/apache2/sites-available/cagette.conf

RUN a2ensite cagette

RUN npm install -g lix

COPY . /srv/

COPY config.xml.dist config.xml

RUN npm install -g lix

WORKDIR /srv/backend

RUN lix scope create
RUN lix install haxe 4.0.5
RUN lix use haxe 4.0.5
RUN lix download

RUN haxe cagetteAllPlugins.hxml

RUN haxelib setup /usr/share/haxelib
RUN haxelib install templo
RUN cd /usr/bin && haxelib run templo

EXPOSE 3009

WORKDIR /srv

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
