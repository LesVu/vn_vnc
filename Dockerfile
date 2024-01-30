FROM debian:sid

ARG user=char
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

RUN dpkg --add-architecture armhf && echo 'deb http://deb.debian.org/debian sid contrib' > /etc/apt/sources.list && apt-get update \
  && apt-get full-upgrade -y -q \
  && apt-get install libc6:armhf -y -q \
  && apt-get install -q -y --no-install-recommends \
  gnupg lsb-release curl tar unzip zip \
  apt-transport-https ca-certificates sudo gpg-agent software-properties-common zlib1g-dev \
  zstd gettext libcurl4-openssl-dev inetutils-ping jq wget dirmngr openssh-client locales \
  && apt-get install -q -y lutris git cmake binfmt-support wayvnc wayfire xwayland kanshi xterm dbus-x11 vim zenity pulseaudio && rm -rf /var/lib/apt/lists/*

RUN wget https://itai-nelken.github.io/weekly-box86-debs/debian/box86.list -O /etc/apt/sources.list.d/box86.list && wget -qO- https://itai-nelken.github.io/weekly-box86-debs/debian/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg && apt-get update && apt-get install box86:armhf -y -q && rm -rf /var/lib/apt/lists/*

RUN wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg && apt-get update && apt-get install box64-arm64 -y -q && rm -rf /var/lib/apt/lists/*

COPY files/binfmts/* /usr/share/binfmts
RUN update-binfmts --import

RUN useradd -m -s /bin/bash -G sudo,video,input,audio,render ${user} && echo "${user}:${user}" | chpasswd && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY files/start.sh /start.sh
COPY files/wayfire.ini /home/${user}/.config/wayfire.ini

RUN sed -i "s/# \(en_US\.UTF-8 .*\)/\1/" /etc/locale.gen && sed -i "s/# \(ja_JP\.UTF-8 .*\)/\1/" /etc/locale.gen && locale-gen

RUN mkdir -p /home/${user}/.local/share/lutris/runners/wine/ && cd /home/${user}/.local/share/lutris/runners/wine/ && wget -q https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-25/wine-lutris-GE-Proton8-25-x86_64.tar.xz -O wine.tar.xz && tar -xvf wine.tar.xz && rm wine.tar.xz

RUN mkdir -p /Games && echo "load-module module-native-protocol-tcp auth-anonymous=1" >> /etc/pulse/default.pa && chown -R ${user}:${user} /home/${user}

USER ${user}
RUN cd && wget -q https://raw.githubusercontent.com/ptitSeb/box86/master/install_steam.sh && sh install_steam.sh && rm install_steam.sh

WORKDIR /home/${user}
CMD [ "/start.sh" ]
EXPOSE 5900
VOLUME [ "/Games" ]
