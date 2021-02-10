FROM node:15.7-buster-slim

# apache setup copied from https://github.com/codeurs/dockerfiles/blob/master/mod-neko/Dockerfile
RUN apt-get update && apt-get install -y git curl imagemagick apache2 haxe libapache2-mod-neko \
    libxml-twig-perl libutf8-all-perl && apt-get clean

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

RUN chown www-data:www-data /srv /var/www

# WHY: src/App.hx:20: characters 58-84 : Cannot execute `git log -1 --format=%h`. fatal: not a git repository (or any of the parent directories): .git
# TODO: remove
COPY --chown=www-data:www-data .git /srv/.git

COPY --chown=www-data:www-data index.html /srv/
COPY --chown=www-data:www-data common/ /srv/common/
COPY --chown=www-data:www-data data/ /srv/data/
COPY --chown=www-data:www-data devLibs/ /srv/devLibs/
COPY --chown=www-data:www-data js/ /srv/js/
COPY --chown=www-data:www-data lang/ /srv/lang/
COPY --chown=www-data:www-data src/ /srv/src/
COPY --chown=www-data:www-data www/ /srv/www/

USER www-data

COPY --chown=www-data:www-data backend/ /srv/backend/
WORKDIR /srv/backend

RUN lix scope create
RUN lix install haxe 4.0.5
RUN lix use haxe 4.0.5
RUN lix download

COPY --chown=www-data:www-data frontend/ /srv/frontend/

WORKDIR /srv/frontend

RUN lix scope create
RUN lix use haxe 4.0.5
RUN lix download
RUN npm install

WORKDIR /srv/backend

RUN haxe cagetteAllPlugins.hxml

WORKDIR /srv/frontend
RUN haxe cagetteJs.hxml

USER root

#RUN haxelib setup /usr/share/haxelib
#RUN haxelib install templo
#RUN cd /usr/bin && haxelib run templo

EXPOSE 3009

WORKDIR /srv

# holds connexion config
COPY --chown=www-data:www-data scripts/ /srv/scripts/
COPY config.xml.dist config-raw.xml

CMD ["bash", "scripts/start.sh", "config-raw.xml", "config.xml" ]
