######################################################################
# Dockerfile to build base ubuntu container with corp proxy settings
# Based on Ubuntu Utopic
######################################################################

# Set the base image to Ubuntu utopic
FROM ubuntu:utopic

# File Author / Maintainer
MAINTAINER Aaron Nicoli <aaronnicoli@gmail.com>


################## BEGIN INSTALLATION ######################

# Change these lines to specify your proxy location(s) [C...C]
ENV __HTTP_PROXY_HOST CproxyhostC
ENV __HTTP_PROXY_PORT CproxyportC
ENV __HTTPS_PROXY_HOST CproxyhostC
ENV __HTTPS_PROXY_PORT CproxyportC
ENV __MAVEN_NO_PROXY CmavennoproxyC

# Lets make the frontend non interactive
ENV DEBIAN_FRONTEND noninteractive

# Setup the http/https proxy environment vars
ENV HTTP_PROXY http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
ENV HTTPS_PROXY http://${HTTPS_PROXY_HOST}:${HTTPS_PROXY_PORT}
ENV http_proxy http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
ENV https_proxy http://${HTTPS_PROXY_HOST}:${HTTPS_PROXY_PORT}

# Config the datetime
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/Australia/Canberra /etc/localtime

# Add apply-config script
ADD ./apply-config.sh /usr/local/bin/apply-config.sh
RUN chmod 755 /usr/local/bin/apply-config.sh

# Set apt proxy location to aptproxy.ris.environment.gov.au
ADD ./95proxies /etc/apt/apt.conf.d/95proxies
RUN /usr/local/bin/apply-config.sh /etc/apt/apt.conf.d/95proxies

# Setup curl proxy settings for root build
ADD ./curlrc /root/.curlrc
RUN /usr/local/bin/apply-config.sh /root/.curlrc

# Now for the gem proxy sexy time
ADD ./gemrc /root/.gemrc
RUN /usr/local/bin/apply-config.sh /root/.gemrc

# Add maven settings.xml for proxy
RUN mkdir /root/.m2
ADD ./settings.xml /root/.m2/settings.xml
RUN chmod 0600 /root/.m2/settings.xml
RUN /usr/local/bin/apply-config.sh /root/.m2/settings.xml

# Pip proxy duffz
RUN mkdir /root/pip
ADD ./pip.conf /root/pip/pip.conf
RUN /usr/local/bin/apply-config.sh /root/pip/pip.conf

# Setup alias for gpg with proxy
RUN mv /usr/bin/gpg /usr/bin/gpg.cont
ADD ./gpg-replacement /usr/bin/gpg
RUN /usr/local/bin/apply-config.sh /usr/bin/gpg

# Setup alias for apt-key with proxy
RUN mv /usr/bin/apt-key /usr/bin/apt-key.cont
ADD ./apt-key-replacement /usr/bin/apt-key
RUN /usr/local/bin/apply-config.sh /usr/bin/apt-key

# Setup the GlusterFS repo bits (if you want to use glusterfs client in your machines)
#RUN echo "deb http://ppa.launchpad.net/gluster/glusterfs-3.6/ubuntu utopic main" >> /etc/apt/sources.list.d/glusterfs-3.6.list
#RUN gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FE869A9 && \
#    gpg --armor --export 3FE869A9 | apt-key add -

# Perform a full apt update and then install the latest bash/wget/curl
RUN apt-get update && apt-get install -yq bash wget curl git-core

# Install GlusterFS (as per above)
#RUN apt-get install -yq glusterfs-server

# Git proxy config
RUN git config --system http.proxy http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
RUN git config --system https.proxy http://${HTTPS_PROXY_HOST}:${HTTPS_PROXY_PORT}

# Start services
CMD ["/bin/bash"]
