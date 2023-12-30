# Use Debian as it works:tm:
FROM debian:bookworm

# Get needed packages
RUN apt update -y
RUN apt install -y \
    git \
    xvfb \
    supervisor \
    novnc \
    x11vnc \
    xterm \
    sudo \
    procps \
    x11-xserver-utils \
    libasound2

# fluxbox for dev
RUN apt install -y fluxbox

# add non root user
RUN adduser --disabled-password --gecos "" bad

# add to sudo
RUN echo 'bad ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# remove tmp & cache
RUN rm  -rf /tmp/* /var/cache/apt/

# set user & workdir
USER bad
WORKDIR /bad

# copy configs & auto-mcs
COPY . .

# make home accessable for user :)
RUN sudo chown -R bad:bad /bad
RUN chmod +x /bad/auto-mcs

USER root
# remove from sudo
RUN echo '' > /etc/sudoers

USER bad

# ENV DISPLAY
ENV DISPLAY=:0.0

# run supervisord with our configs
ENTRYPOINT [ "bash", "-c", "supervisord -c /bad/supervisord.conf" ]
