FROM freeradius-server-freeradius-server:0.01

#
#  Copy certificate, key and conf
#
COPY certs/rsa/ca.pem /etc/raddb/certs/rsa/
RUN chgrp radiusd /etc/raddb/certs/rsa/ca.pem

COPY certs/rsa/server.pem /etc/raddb/certs/rsa/
RUN chgrp radiusd /etc/raddb/certs/rsa/server.pem

COPY certs/rsa/server.key /etc/raddb/certs/rsa/
RUN chgrp radiusd /etc/raddb/certs/rsa/server.key

COPY clients.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/clients.conf

COPY authorize /etc/raddb/mods-config/files/
RUN chgrp radiusd /etc/raddb/mods-config/files/authorize

COPY radiusd.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/radiusd.conf
