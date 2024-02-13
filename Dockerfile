# Use Debian and set noninteractive
FROM debian:bookworm
ENV DEBIAN_FRONTEND noninteractive

# Set TurboVNC version
ENV TURBO 3.1.1

# Get needed packages
RUN apt update -y
RUN apt install -y \
    wget \
    git \
    ratpoison \
    websockify \
    supervisor \
    sudo \
    procps \
    x11-xserver-utils \
    dbus-x11 \
    x11-xkb-utils \
    xkb-data \
    libasound2

# noVNC
RUN git clone https://github.com/novnc/noVNC -b master /bad/novnc
RUN sed -i "s/UI.initSetting('resize', 'off');/UI.initSetting('resize', 'remote');/g" /bad/novnc/app/ui.js
RUN mv /bad/novnc/vnc.html /bad/novnc/index.html

# TurboVNC
RUN wget https://github.com/TurboVNC/turbovnc/releases/latest/download/turbovnc_${TURBO}_amd64.deb \
    && dpkg -i turbovnc*.deb \
    && apt install -f

# add non root user
RUN adduser --disabled-password --gecos "" bad

# add to sudo
RUN echo 'bad ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# remove tmp & cache
RUN rm -rf /tmp/* /var/cache/apt/ /var/lib/apt/lists/* \
    && apt autoclean -y \
    && apt autoremove -y

# set user & workdir
USER bad
WORKDIR /bad

RUN mkdir -p ~ \
    && echo "set border 1" >> ~/.ratpoisonrc

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
ENTRYPOINT [ "bash", "-c", "/opt/TurboVNC/bin/vncserver :0 -fg -noxstartup -securitytypes None -geometry 1280x720 -depth 24 & supervisord -c /bad/supervisord.conf" ]
