# Auto generated for rocky8
# from scripts/docker/m4/Dockerfile.rpm.m4
#
# Rebuild this file with `make docker.rocky8.regen`
#
ARG from=rockylinux/rockylinux:8
FROM ${from} as build

#
#  Install yum
#
RUN dnf install -y yum

RUN rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

#
#  Install build tools
#
RUN yum groupinstall -y "Development Tools"

RUN yum install -y rpmdevtools openssl dnf-utils


#
#  Create build directory
#
RUN mkdir -p /usr/local/src/repositories/freeradius-server
WORKDIR /usr/local/src/repositories/freeradius-server/

#
#  Copy the FreeRADIUS directory in
#
COPY . .

#
#  Clean up tree - we want to build from the latest commit, not from
#  any cruft left around on the local system
#
RUN git clean -fdxx \
 && git reset --hard HEAD

ARG release
RUN [ -z "$release" ] || git checkout ${release} ; \
    git status ; \
    git log -1 --oneline

#
#  Other requirements
#

#  Use LTB's openldap packages intead of the distribution version to avoid linking against NSS
RUN echo $'[ltb-project]\n\
name=LTB project packages\n\
baseurl=https://ltb-project.org/rpm/$releasever/$basearch\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-LTB-project'\
> /etc/yum.repos.d/ltb-project.repo
RUN rpm --import https://ltb-project.org/lib/RPM-GPG-KEY-LTB-project

#  Enable EPEL repository for freetds and hiredis
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

#  Enable powertools repo
RUN yum config-manager --enable powertools

#  Enable epel-testing, currently needed for hiredis-devel
RUN yum config-manager --enable epel-testing

#
#  Install build dependencies
#
#  Run twice, it doesn't always get everything with one invocation
#
RUN [ -e redhat/freeradius.spec ] && \
	yum-builddep -y redhat/freeradius.spec && \
	yum-builddep -y redhat/freeradius.spec

#
#  Create RPM build environment
#
ENV BUILDDIR=/root/rpmbuild
RUN rpmdev-setuptree

RUN ./configure
RUN cp VERSION /VERSION
RUN make freeradius-server-$(cat /VERSION).tar.bz2
RUN cp freeradius-server-$(cat /VERSION).tar.bz2 $BUILDDIR/SOURCES/
RUN cp -r redhat/* $BUILDDIR/SOURCES/
RUN sed -i "s/^Version:.*/Version: $(cat /VERSION)/" redhat/freeradius.spec
RUN cp -r redhat/freeradius.spec $BUILDDIR/SPECS/
WORKDIR $BUILDDIR

#
#  Build the server
#
ENV QA_RPATHS=0x0003
RUN rpmbuild -bb --define "_release $(cat /VERSION)" "$BUILDDIR/SPECS/freeradius.spec"

RUN mkdir /root/rpms
RUN mv $BUILDDIR/RPMS/*/*.rpm /root/rpms/

#
#  Clean environment and run the server
#
FROM ${from}

COPY --from=build /root/rpms /tmp/

#
#  Install yum
#
RUN dnf install -y yum

# Use LTB's openldap packages intead of the distribution version to avoid linking against NSS
RUN echo $'[ltb-project]\n\
name=LTB project packages\n\
baseurl=https://ltb-project.org/rpm/$releasever/$basearch\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-LTB-project'\
> /etc/yum.repos.d/ltb-project.repo \
    && rpm --import https://ltb-project.org/lib/RPM-GPG-KEY-LTB-project


#  EPEL repository for freetds and hiredis
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && yum install -y dnf-utils \
    && yum config-manager --enable powertools \
    && yum config-manager --enable epel-testing

ARG radiusd_uid=95
ARG radiusd_gid=95

RUN groupadd -g ${radiusd_gid} -r radiusd \
    && useradd -u ${radiusd_uid} -g radiusd -r -M -d /home/radiusd -s /sbin/nologin radiusd \
    && yum install -y /tmp/*.rpm

WORKDIR /
COPY scripts/docker//etc/docker-entrypoint.sh.rpm docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

# clients.conf
COPY conf/clients.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/clients.conf

# eap
#COPY conf/eap /etc/raddb/mods-available
#RUN chgrp radiusd /etc/raddb/mods-available/eap

# root ca
#COPY conf/Certificates/home_root_ca_crt.pem /etc/raddb/certs/
#RUN chgrp radiusd /etc/raddb/certs/home_root_ca_crt.pem

# intermedia ca
#COPY conf/Certificates/home_intermediate_ca_crt.pem /etc/raddb/certs/
#RUN chgrp radiusd /etc/raddb/certs/home_intermediate_ca_crt.pem

# server cert
#COPY conf/Certificates/home_freeradius-server_crt.pem /etc/raddb/certs/
#RUN chgrp radiusd /etc/raddb/certs/home_freeradius-server_crt.pem

# server private key
#COPY conf/Certificates/home_freeradius-server_prv.pem /etc/raddb/certs/
#RUN chgrp radiusd /etc/raddb/certs/home_freeradius-server_prv.pem

# certs/
COPY conf/certs/ /etc/raddb/certs/
RUN chgrp -R radiusd /etc/raddb/certs

# server radiusd.conf key
COPY conf/radiusd.conf /etc/raddb/
RUN chgrp radiusd /etc/raddb/radiusd.conf

EXPOSE 1812/udp 1813/udp
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["radiusd"]
