FROM dogkeeper886/freeradius-server:v3.2.x

#
#  Copy certificate and key
#
COPY certs /etc/raddb/certs
RUN chgrp -R radiusd /etc/raddb/certs

#
# Conf
#
COPY radiusd.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/radiusd.conf

COPY clients.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/clients.conf

#
# SQL
#
COPY sql /etc/raddb/mods-available/
RUN chgrp radiusd /etc/raddb/mods-available/sql

RUN ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql

#
# Default
#
COPY default /etc/raddb/sites-available/
RUN chgrp radiusd /etc/raddb/sites-available/default


