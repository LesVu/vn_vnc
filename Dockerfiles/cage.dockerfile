FROM debian:sid
ARG user=abc

LABEL maintainer="LesVu"

ENV CAGE=1
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
ENV WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128

RUN <<EOF
echo "Types: deb
URIs: http://mirror.sg.gs/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" > /etc/apt/sources.list.d/debian.sources
apt-get update 
apt-get full-upgrade -y -q 

apt-get install -q -y --no-install-recommends \
  gnupg lsb-release curl tar unzip zip xz-utils \
  apt-transport-https ca-certificates sudo gpg-agent software-properties-common zlib1g-dev \
  zstd gettext libcurl4-openssl-dev inetutils-ping jq wget dirmngr locales libibus-1.0-5

apt-get install -q -y lutris git binfmt-support wayvnc cage xwayland \
  zenity pulseaudio nodejs npm fonts-noto-cjk mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0
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

apt-get update
apt-get install box64-generic-arm box86-generic-arm:armhf -y
rm -rf /var/lib/apt/lists/*
EOF

COPY files/binfmts/* /usr/share/binfmts
RUN update-binfmts --import

RUN useradd -m -s /bin/bash -u 1000 -G sudo,video,audio ${user} \
  && echo "${user}:${user}" | chpasswd \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY files/cage /usr/bin/cage
COPY files/start.sh /start.sh
COPY files/novnc_audio/* /home/${user}/novnc_audio/

RUN sed -i "s/# \(en_US\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && sed -i "s/# \(ja_JP\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && locale-gen

RUN mkdir -p /home/${user}/.local/share/lutris/runners/wine/ \
  && cd /home/${user}/.local/share/lutris/runners/wine/ \
  && curl -L https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-26/wine-lutris-GE-Proton8-26-x86_64.tar.xz -o wine.tar.xz \
  && tar -xf wine.tar.xz \
  && rm wine.tar.xz

RUN mkdir -p /Games \
  && echo "load-module module-native-protocol-tcp auth-anonymous=1" >> /etc/pulse/default.pa \
  && find /home/${user} -not -user ${user} -exec chown ${user}:${user} {} \;

USER ${user}
RUN <<EOF
dpkg --add-architecture armhf
sudo apt-get update 
sudo apt-get install -y -q libc6:armhf libsdl2-2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl2-mixer-2.0-0:armhf \
libsdl2-ttf-2.0-0:armhf libopenal1:armhf libpng16-16:armhf libfontconfig1:armhf libxcomposite1:armhf libbz2-1.0:armhf \
libxtst6:armhf libsm6:armhf libice6:armhf libgl1:armhf libxinerama1:armhf libxdamage1:armhf 
sudo apt install libgl1-mesa-dri:armhf -y -q
sudo rm -rf /var/lib/apt/lists/*
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
