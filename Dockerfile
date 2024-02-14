# Use Debian and set noninteractive
FROM debian:bookworm
ENV DEBIAN_FRONTEND noninteractive

# Set TurboVNC version
ENV TURBO 3.1.1

# Get needed packages (+ probably useless ones)
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

# SSL for self-signed HTTPS
RUN openssl genpkey -algorithm RSA -out /bad/p.key \
    && openssl req -new -key /bad/p.key -out /bad/csr.pem -subj "/C=US/ST=New York/L=New York/O=auto-mcs/CN=https:\/\/auto-mcs.com/OU=yesBad's Docker" \
    && openssl x509 -req -days 365 -in /bad/csr.pem -signkey /bad/p.key -out /bad/c.crt

# TurboVNC
RUN wget https://github.com/TurboVNC/turbovnc/releases/latest/download/turbovnc_${TURBO}_amd64.deb \
    && dpkg -i turbovnc*.deb \
    && apt install -f

# Add a non-root user for auto-mcs
RUN adduser --disabled-password --gecos "" bad

# Add it to sudo (temporarily)
RUN echo 'bad ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Remove cache, tmp etc :)
RUN rm -rf /tmp/* /var/cache/apt/ /var/lib/apt/lists/* \
    && apt autoclean -y \
    && apt autoremove -y

# Set the user and workdir
USER bad
WORKDIR /bad

# Modify Fluxbox to our liking (or well mine :])
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
    && echo 'session.screen0.defaultDeco: NONE' >> ~/.fluxbox/init \
    && echo 'session.screen0.workspaces: 1' >> ~/.fluxbox/init 

# Copy all the fancy stuff we need
COPY . .

# Make workdir accessable for user 'bad' and make starter & auto-mcs executable
RUN sudo chown -R bad:bad /bad
RUN chmod +x /bad/auto-mcs \
    && chmod +x starter.sh

USER root

# Remove 'bad' from sudo
RUN echo '' > /etc/sudoers

USER bad

# Run TurboVNC and Supervisord with 'apps' folder confs.
ENTRYPOINT [ "bash", "-c", "/opt/TurboVNC/bin/vncserver :0 -fg -noxstartup -securitytypes None -geometry 1280x720 -depth 24 & supervisord -c /bad/supervisord.conf" ]
