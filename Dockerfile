# https://registry.hub.docker.com/u/phusion/baseimage/
FROM phusion/baseimage:latest
MAINTAINER launchbadge <contact@launchbadge.com>

# Install base system requirements
RUN apt-get update && \
    apt-get install -q -y \
      git libtcnative-1 \
      curl \
      software-properties-common \
      python-software-properties

# Install Java 8
RUN apt-add-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install oracle-java8-installer -y

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
ENV RUN_USER            daemon
ENV RUN_GROUP           daemon

# https://confluence.atlassian.com/display/BitbucketServer/Bitbucket+Server+home+directory
ENV BITBUCKET_HOME          /data

# Install Atlassian Bitbucket Server to the following location
ENV BITBUCKET_INSTALL_DIR   /srv

ENV BITBUCKET_VERSION 4.3.2
ENV DOWNLOAD_URL https://downloads.atlassian.com/software/stash/downloads/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz

RUN mkdir -p ${BITBUCKET_HOME} \
    && chmod -R 700 ${BITBUCKET_HOME} \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_HOME}

RUN mkdir -p                             ${BITBUCKET_INSTALL_DIR} \
    && curl -L --silent                  ${DOWNLOAD_URL} | tar -xz --strip=1 -C "$BITBUCKET_INSTALL_DIR" \
    && mkdir -p                          ${BITBUCKET_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/logs               \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/temp               \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR}/                   \
    && ln --symbolic                     "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BITBUCKET_INSTALL_DIR}/lib/native/libtcnative-1.so"

USER ${RUN_USER}:${RUN_GROUP}

VOLUME ["${BITBUCKET_HOME}"]

# HTTP Port
EXPOSE 7990

# SSH Port
EXPOSE 7999

WORKDIR $BITBUCKET_INSTALL_DIR

# Run in foreground
CMD ["./bin/start-bitbucket.sh", "-fg"]
