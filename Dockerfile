FROM debian:sid AS base
ARG USER=abc
ARG CAGE=1

LABEL maintainer="LesVu"

ENV CAGE=${CAGE}
ENV USER=${USER}
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
  apt-transport-https ca-certificates sudo gpg-agent software-properties-common python3-numpy zlib1g-dev \
  zstd gettext libcurl4-openssl-dev inetutils-ping jq wget dirmngr locales git

apt-get install -q -y --no-install-recommends xterm zenity pulseaudio fonts-noto-cjk nodejs npm

if [ -n "$CAGE" ]; then
  apt-get install -q -y cage
else 
  apt-get install -q -y wayfire 
fi

apt-get install -q -y --no-install-suggests lutris wayvnc xwayland socat gstreamer1.0-tools \
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad websockify

rm -rf /var/lib/apt/lists/*
EOF

RUN useradd -m -s /bin/bash -u 1000 -G sudo,video,audio ${USER} \
  && echo "${USER}:${USER}" | chpasswd \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY files/start.sh /start.sh
COPY files/wayfire.ini /home/${USER}/.config/wayfire.ini
COPY files/novnc_audio/* /home/${USER}/novnc_audio/

RUN sed -i "s/# \(en_US\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && sed -i "s/# \(ja_JP\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && locale-gen

RUN mkdir -p /Games \
  && echo "load-module module-native-protocol-tcp auth-anonymous=1" >> /etc/pulse/default.pa \
  && find /home/${USER} -not -user ${USER} -exec chown ${USER}:${USER} {} \;

USER ${USER}
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
  && cp audio.js ~/noVNC \
  && cd ~/noVNC \
  && git apply ../novnc_audio/ui.patch


WORKDIR /home/${USER}
CMD [ "/start.sh" ]
EXPOSE 4713 5700 5900 6100
VOLUME [ "/Games" ]



FROM base AS boxed

RUN <<EOF
wget -qO- "https://pi-apps-coders.github.io/box86-debs/KEY.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/box86-archive-keyring.gpg
wget -qO- "https://pi-apps-coders.github.io/box64-debs/KEY.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/box64-archive-keyring.gpg

echo "Types: deb
URIs: https://Pi-Apps-Coders.github.io/box86-debs/debian
Suites: ./
Signed-By: /usr/share/keyrings/box86-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/box86.sources >/dev/null
echo "Types: deb
URIs: https://Pi-Apps-Coders.github.io/box64-debs/debian
Suites: ./
Signed-By: /usr/share/keyrings/box64-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/box64.sources >/dev/null

sudo dpkg --add-architecture armhf
sudo apt-get update
sudo apt-get install -y box64-generic-arm box86-generic-arm:armhf binfmt-support
sudo apt-get install -y libc6:armhf libsdl2-2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl2-mixer-2.0-0:armhf \
libsdl2-ttf-2.0-0:armhf libopenal1:armhf libpng16-16:armhf libfontconfig1:armhf libxcomposite1:armhf libbz2-1.0:armhf \
libxtst6:armhf libsm6:armhf libice6:armhf libgl1:armhf libxinerama1:armhf libxdamage1:armhf libibus-1.0-5
sudo apt install -y libgl1-mesa-dri:armhf
sudo rm -rf /var/lib/apt/lists/*
EOF

COPY --chown=root:root files/binfmts/* /usr/share/binfmts
RUN sudo update-binfmts --import


FROM base AS fex

RUN <<EOF
sudo apt-get update
sudo apt-get install -y git cmake ninja-build pkgconf ccache clang llvm lld binfmt-support \
  libsdl2-dev libepoxy-dev libssl-dev python3-setuptools squashfs-tools squashfuse libc-bin
sudo rm -rf /var/lib/apt/lists/*
git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git
cd FEX
mkdir Build
cd Build
CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
ninja
sudo ninja install
sudo ninja binfmt_misc_32
sudo ninja binfmt_misc_64
cd ../../
rm -rf FEX
EOF

RUN sudo update-binfmts --import
