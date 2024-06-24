FROM rockylinux:8
ENV TZ=Asia/Taipei
#ENV DEBIAN_FRONTEND=noninteractive
#RUN apt update
#RUN apt install -y tzdata
RUN dnf -y install freeradius
COPY clients.conf /etc/raddb/clients.conf
COPY certs/ /etc/raddb/certs/
COPY radiusd.conf /etc/raddb/radiusd.conf
COPY users /etc/raddb/mods-config/files/authorize
RUN chgrp -R radiusd /etc/raddb
#RUN chown -R freerad /etc/raddb
#ENTRYPOINT ["tail", "-f", "/dev/null"]
ENTRYPOINT ["radiusd", "-X"]
