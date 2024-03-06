FROM freeradius/freeradius-server:3.2.3

ENV TZ=Asia/Taipei
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y tzdata

COPY freeradius/clients.conf /etc/freeradius/clients.conf
RUN chown -R freerad /etc/freeradius/clients.conf
RUN chgrp -R freerad /etc/freeradius/clients.conf

COPY freeradius/certs/ca.cnf /etc/freeradius/certs/ca.cnf
COPY freeradius/certs/server.cnf /etc/freeradius/certs/server.cnf
COPY freeradius/certs/clients.cnf /etc/freeradius/certs/clients.cnf
COPY freeradius/certs/inner-server.cnf /etc/freeradius/certs/inner-server.cnf

RUN cd /etc/freeradius/certs && ./bootstrap

RUN chown -R freerad /etc/freeradius/certs
RUN chgrp -R freerad /etc/freeradius/certs