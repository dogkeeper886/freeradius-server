FROM freeradius/freeradius-server:3.2.3
ENV TZ=Asia/Taipei
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y tzdata
COPY freeradius/clients.conf /etc/freeradius/clients.conf
RUN chown -R freerad /etc/freeradius/clients.conf
RUN chgrp -R freerad /etc/freeradius/clients.conf
COPY freeradius/certs /etc/freeradius/certs
RUN chown -R freerad /etc/freeradius/certs
RUN chgrp -R freerad /etc/freeradius/certs