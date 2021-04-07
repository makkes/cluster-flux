FROM nginx:1.19.7

RUN apt-get update && \
    apt-get install git fcgiwrap apache2-utils -y

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY htpasswd /etc/nginx
COPY fcgiwrap-entrypoint.sh /docker-entrypoint.d/
COPY fcgiwrap.defaults /etc/default/fcgiwrap
COPY repo.tar.gz /tmp
RUN mkdir -p srv/git && tar -xf /tmp/repo.tar.gz -C /srv/git/ && rm /tmp/repo.tar.gz
RUN chown -R www-data.www-data /srv/git
