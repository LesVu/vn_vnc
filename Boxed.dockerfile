FROM debian:sid
ARG user=abc

LABEL maintainer="LesVu"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

RUN <<EOF
dpkg --add-architecture armhf
echo "Types: deb
URIs: http://deb.debian.org/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" > /etc/apt/sources.list.d/debian.sources
apt-get update 
apt-get full-upgrade -y -q 
apt-get install libc6:armhf -y -q

apt-get install -q -y --no-install-recommends \
  gnupg lsb-release curl tar unzip zip \
  apt-transport-https ca-certificates sudo gpg-agent software-properties-common zlib1g-dev \
  zstd gettext libcurl4-openssl-dev inetutils-ping jq wget dirmngr openssh-client locales

apt-get install -q -y lutris git cmake binfmt-support wayvnc wf-shell wayfire xwayland \
  kanshi xterm dbus-x11 vim zenity pulseaudio bemenu nodejs npm 7zip-rar fonts-noto-cjk
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
wget -qO- "https://pi-apps-coders.github.io/box86-debs/KEY.gpg" | gpg --dearmor -o /usr/share/keyrings/box86-archive-keyring.gpg
wget -qO- "https://pi-apps-coders.github.io/box64-debs/KEY.gpg" | gpg --dearmor -o /usr/share/keyrings/box64-archive-keyring.gpg

echo "Types: deb
URIs: https://Pi-Apps-Coders.github.io/box86-debs/debian
Suites: ./
Signed-By: /usr/share/keyrings/box86-archive-keyring.gpg" | tee /etc/apt/sources.list.d/box86.sources >/dev/null
echo "Types: deb
URIs: https://Pi-Apps-Coders.github.io/box64-debs/debian
Suites: ./
Signed-By: /usr/share/keyrings/box64-archive-keyring.gpg" | tee /etc/apt/sources.list.d/box64.sources >/dev/null

apt update
apt install box64-generic-arm box86-generic-arm:armhf -y
rm -rf /var/lib/apt/lists/*
EOF

COPY files/binfmts/* /usr/share/binfmts
RUN update-binfmts --import

RUN useradd -m -s /bin/bash -G sudo,video,input,audio,render ${user} \
  && echo "${user}:${user}" | chpasswd \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY files/start.sh /start.sh
COPY files/wayfire.ini /home/${user}/.config/wayfire.ini
COPY files/novnc_audio/* /home/${user}/novnc_audio/

RUN sed -i "s/# \(en_US\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && sed -i "s/# \(ja_JP\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && locale-gen

RUN mkdir -p /home/${user}/.local/share/lutris/runners/wine/ \
  && cd /home/${user}/.local/share/lutris/runners/wine/ \
  && wget -q https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-26/wine-lutris-GE-Proton8-26-x86_64.tar.xz -O wine.tar.xz \
  && tar -xvf wine.tar.xz \
  && rm wine.tar.xz

RUN mkdir -p /Games \
  && echo "load-module module-native-protocol-tcp auth-anonymous=1" >> /etc/pulse/default.pa \
  && find /home/${user} -not -user ${user} -exec chown ${user}:${user} {} \;

USER ${user}
RUN <<EOF
cd 
mkdir -p ~/steam/tmp 
cd ~/steam/tmp 
wget -q https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb
ar x steam.deb
tar xf data.tar.xz
rm ./*.tar.xz ./steam.deb
mv ./usr/* ../
cd ../
rm -rf ./tmp/
echo "#!/bin/bash
export STEAMOS=1
export STEAM_RUNTIME=1
export DBUS_FATAL_WARNINGS=0
~/steam/bin/steam $@" > steam
chmod +x steam
sudo mv steam /usr/local/bin/
sudo apt-get update 
sudo apt-get install -y -q  libc6:armhf libsdl2-2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl2-mixer-2.0-0:armhf \
libsdl2-ttf-2.0-0:armhf libopenal1:armhf libpng16-16:armhf libfontconfig1:armhf libxcomposite1:armhf libbz2-1.0:armhf \
libxtst6:armhf libsm6:armhf libice6:armhf libgl1:armhf libxinerama1:armhf libxdamage1:armhf libibus-1.0-5
sudo apt install libgl1-mesa-dri:armhf -y -q
EOF

RUN cd ~ \
  && git clone https://github.com/novnc/noVNC \
  && cd novnc_audio \
  && npm i \
  && cp audio.js pcm-player.js ~/noVNC \
  && cd ~/noVNC \
  && git apply ../novnc_audio/ui.patch


WORKDIR /home/${user}
CMD [ "/start.sh" ]
EXPOSE 4713 5700 5900 6080
VOLUME [ "/Games" ]
