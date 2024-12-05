FROM freeradius-server-freeradius-server:0.01

#
#  Copy certificate, key and conf
#
COPY certs /etc/raddb/certs
RUN chgrp -R radiusd /etc/raddb/certs

COPY clients.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/clients.conf

COPY authorize /etc/raddb/mods-config/files/
RUN chgrp radiusd /etc/raddb/mods-config/files/authorize

COPY radiusd.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/radiusd.conf
