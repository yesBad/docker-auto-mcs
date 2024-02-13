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
    fluxbox \
    websockify \
    supervisor \
    sudo \
    procps \
    xclip \
    xdotool \
    xsel \
    x11-xserver-utils \
    dbus-x11 \
    x11-xkb-utils \
    xkb-data \
    libgl1-mesa-glx \
    x11-utils \
    wmctrl \
    libasound2

# noVNC
RUN git clone https://github.com/yesBad/yesVNC -b master /bad/novnc

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

# fluxbox'd, a wonderful product
RUN mkdir -p ~/.fluxbox \
    && echo '[begin] (Fluxbox)\n[nop] (a yesBad time-waster)\n[exec] (Restart auto-mcs) {pkill auto-mcs}\n[end]' >> ~/.fluxbox/menu \
    && echo 'session.styleFile: /usr/share/fluxbox/styles/debian-dark' >> ~/.fluxbox/init \
    && echo 'session.screen0.window.unfocus.alpha: 255' >> ~/.fluxbox/init \
    && echo 'session.screen0.allowRemoteActions: true' >> ~/.fluxbox/init \
    && echo 'session.screen0.window.active.alpha: 255' >> ~/.fluxbox/init \
    && echo 'session.screen0.window.active.alpha: 255' >> ~/.fluxbox/init \
    && echo 'session.screen0.window.focus.alpha: 255' >> ~/.fluxbox/init \
    && echo 'session.screen0.toolbar.visible: false' >> ~/.fluxbox/init \
    && echo 'session.screen0.tabs.usePixmap: false' >> ~/.fluxbox/init \
    && echo '[begin]\n  [maximize]\n[end]' >> ~/.fluxbox/windowmenu \
    && echo 'session.screen0.defaultDeco: NONE' >> ~/.fluxbox/init

# copy configs & auto-mcs
COPY . .

# make home accessable for user :)
RUN sudo chown -R bad:bad /bad
RUN chmod +x /bad/auto-mcs \
    && chmod +x starter.sh

USER root
# remove from sudo
RUN echo '' > /etc/sudoers

USER bad

# run supervisord with our configs
ENTRYPOINT [ "bash", "-c", "/opt/TurboVNC/bin/vncserver :0 -fg -noxstartup -securitytypes None -geometry 1280x720 -depth 24 & supervisord -c /bad/supervisord.conf" ]
