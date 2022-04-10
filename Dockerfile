From ubuntu:trusty
MAINTAINER Elliott Ye

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update

# Start editing
# Install package here for cache
RUN apt-get -y install python3.4-dev python3.4 supervisor postfix sasl2-bin opendkim opendkim-tools

# Add files
ADD assets/parse_resty_auto_ssl.py /opt/parse_resty_auto_ssl.py
ADD assets/install.sh /opt/install.sh

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
