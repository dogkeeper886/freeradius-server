FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

#
#  Install build tools
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        devscripts \
        equivs \
        gawk \
        gdb \
        git \
        gnupg \
        less \
        lsb-release \
        make \
        quilt \
        sudo \
        vim \
        wget

#
#  Set up NetworkRADIUS extras repository for libkqueue etc.
#
RUN install -d -o root -g root -m 0755 /etc/apt/keyrings && \
    curl -o /etc/apt/keyrings/packages.networkradius.com.asc \
        "https://packages.inkbridgenetworks.com/pgp/packages%40networkradius.com" && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.networkradius.com.asc] http://packages.networkradius.com/extras/ubuntu/noble noble main" \
        > /etc/apt/sources.list.d/networkradius-extras.list && \
    apt-get update

#
#  Install FreeRADIUS build dependencies from debian/control
#  This is the same method used by the official build Dockerfiles.
#  We copy just the debian dir first to cache this layer.
#
COPY debian /tmp/freeradius-server/debian
WORKDIR /tmp/freeradius-server
RUN if [ -e ./debian/control.in ]; then \
        touch -t 202001010000 debian/control; \
        debian/rules debian/control; \
    fi && \
    echo 'y' | mk-build-deps -irt'apt-get -yV' debian/control && \
    rm -rf /tmp/freeradius-server

#
#  Build libkqueue from source on non-amd64 architectures
#
RUN if [ "$(dpkg --print-architecture)" != "amd64" ]; then \
        apt-get install -y cmake && \
        git clone --depth 1 https://github.com/mheily/libkqueue.git /tmp/libkqueue && \
        cd /tmp/libkqueue && \
        cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib . && \
        make && cpack -G DEB && dpkg -i *.deb && \
        cd / && rm -rf /tmp/libkqueue; \
    fi

#
#  Clean up APT cache
#
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

#
#  Create non-root user for development
#
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN if getent group $USER_GID > /dev/null 2>&1; then \
        groupmod -n $USERNAME $(getent group $USER_GID | cut -d: -f1); \
    else \
        groupadd --gid $USER_GID $USERNAME; \
    fi && \
    if getent passwd $USER_UID > /dev/null 2>&1; then \
        usermod -l $USERNAME -d /home/$USERNAME -m $(getent passwd $USER_UID | cut -d: -f1); \
    else \
        useradd --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME

WORKDIR /workspace
