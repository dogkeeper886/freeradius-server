FROM freeradius/freeradius-server:3.2.3
COPY freeradius/clients.conf /etc/freeradius/clients.conf
RUN chown -R freerad /etc/freeradius/clients.conf
RUN chgrp -R freerad /etc/freeradius/clients.conf
RUN command
COPY freeradius/certs /etc/freeradius/certs
RUN chown -R freerad /etc/freeradius/certs
RUN chgrp -R freerad /etc/freeradius/certs