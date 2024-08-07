FROM debian:sid
ARG user=abc

LABEL maintainer="LesVu"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

RUN <<EOF
echo "Types: deb
URIs: http://deb.debian.org/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" > /etc/apt/sources.list.d/debian.sources
apt-get update 
apt-get full-upgrade -y -q 

apt-get install -q -y --no-install-recommends \
  gnupg lsb-release curl tar unzip zip \
  apt-transport-https ca-certificates sudo gpg-agent software-properties-common zlib1g-dev \
  zstd gettext libcurl4-openssl-dev inetutils-ping jq wget dirmngr openssh-client locales

apt-get install -q -y lutris git cmake binfmt-support wayvnc wf-shell wayfire xwayland \
  kanshi xterm dbus-x11 vim zenity pulseaudio bemenu nodejs npm 7zip-rar fonts-noto-cjk
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
apt-get update
apt-get install -y -q git cmake ninja-build pkgconf ccache clang llvm lld binfmt-support \
  libsdl2-dev libepoxy-dev libssl-dev python3-setuptools squashfs-tools squashfuse libc-bin
rm -rf /var/lib/apt/lists/*
git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git
cd FEX
mkdir Build
cd Build
CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
ninja
ls -lah
ninja install
ninja binfmt_misc_32
ninja binfmt_misc_64
cd ../../
rm -rf FEX
EOF

RUN update-binfmts --import

RUN useradd -m -s /bin/bash -G sudo,video,input,audio,render ${user} \
  && echo "${user}:${user}" | chpasswd \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY files/start_fex.sh /start.sh
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
