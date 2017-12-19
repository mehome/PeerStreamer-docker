# http://phusion.github.io/baseimage-docker/
FROM phusion/baseimage:0.9.22

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Set /peerstreamer as working directory
WORKDIR /peerstreamer

# Create environment variable used to configure peerstreamer-ng binding iface
ENV PSNGIFACE eth0

# Copy required files into the container at /peerstreamer
ADD requirements.txt /peerstreamer/

RUN mkdir /peerstreamer/serf-python
ADD serf-python.tar.gz /peerstreamer/serf-python/

# Install required packages
RUN apt update && apt install -y python2.7 python-pip git

# Install python requirements
RUN pip install -r requirements.txt

# Install serf-python: the local archive have beeb checked out from github.
# Don't use the package provided with pip because it doesn't work.
RUN cd /peerstreamer/serf-python && \
        python setup.py install
RUN rm -rf /peerstreamer/serf-python

# Build peerstreamer
RUN git clone -b netcommons-demo \
        https://ans.disi.unitn.it/redmine/peerstreamer-src.git \
            peerstreamer
RUN cd /peerstreamer/peerstreamer && make

# Clone psng-pyserf
RUN git clone \
        https://ans.disi.unitn.it/redmine/psng-pyserf.git \
            psng-pyserf

RUN apt remove -y git && apt autoremove -y

# Create script for running psng-pyserf service
RUN mkdir /etc/service/psng-pyserf
ADD psng-pyserf.sh /etc/service/psng-pyserf/run

# Create script for running peerstreamer
RUN mkdir /etc/service/peerstreamer
ADD peerstreamer.sh /etc/service/peerstreamer/run

# Clean up APT when done.
RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*