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
COPY freeradius/certs/client.cnf /etc/freeradius/certs/client.cnf
COPY freeradius/certs/inner-server.cnf /etc/freeradius/certs/inner-server.cnf

RUN cd /etc/freeradius/certs && make destroycerts && ./bootstrap

RUN chown -R freerad /etc/freeradius/certs
RUN chgrp -R freerad /etc/freeradius/certs

COPY freeradius/radiusd.conf /etc/freeradius/radiusd.conf
RUN chown -R freerad /etc/freeradius/radiusd.conf
RUN chgrp -R freerad /etc/freeradius/radiusd.conf

COPY freeradius/mods-available/eap /etc/freeradius/mods-available/eap
RUN chown -R freerad /etc/freeradius/mods-available/eap
RUN chgrp -R freerad /etc/freeradius/mods-available/eap
