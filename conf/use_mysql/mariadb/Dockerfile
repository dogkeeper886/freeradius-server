# MariaDB Dockerfile

FROM mariadb:lts-ubi9

# Copy init SQL script
COPY ./initfile.sql /docker-entrypoint-initdb.d/

# Expose the default MariaDB port
EXPOSE 3306
