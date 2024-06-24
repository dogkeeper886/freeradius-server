FROM freeradius/freeradius-server:3.2.3

COPY clients.conf /etc/freeradius/clients.conf
COPY certs /etc/freeradius/
COPY radiusd.conf /etc/freeradius/radiusd.conf
COPY users /etc/freeradius/mods-config/files/authorize
RUN chgrp -R freerad /etc/freeradius
#ENTRYPOINT ["tail", "-f", "/dev/null"]
