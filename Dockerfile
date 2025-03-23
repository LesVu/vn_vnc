FROM rust:latest AS builder
WORKDIR /usr/src/audio_feed
RUN apt-get update && apt-get install -y -q cmake pkg-config libasound2-dev libpulse-dev
COPY files/audio_feed .
RUN cargo install --path .


FROM debian:sid AS base
ARG USER=abc

LABEL maintainer="LesVu"

ENV USER=${USER}
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
ENV WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128

# RUN echo "Types: deb \nURIs: http://mirror.sg.gs/debian \nSuites: sid \nComponents: main contrib non-free non-free-firmware \nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg" > /etc/apt/sources.list.d/debian.sources \

RUN apt-get update \
  && apt-get full-upgrade -y -q \
  && apt-get install -q -y --no-install-recommends --no-install-suggests \
  gnupg lsb-release curl tar unzip zip xz-utils \
  apt-transport-https ca-certificates sudo gpg-agent software-properties-common python3-numpy zlib1g-dev \
  zstd gettext libcurl4-openssl-dev inetutils-ping jq wget dirmngr locales git unzip \
  alacritty zenity pulseaudio fonts-noto-cjk pcmanfm chromium pavucontrol wofi dbus-x11 nodejs npm \
  && apt-get install -q -y --no-install-suggests wayvnc xwayland labwc waybar swaybg mesa-vulkan-drivers \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash -u 1000 -G sudo,video,audio ${USER} \
  && echo "${USER}:${USER}" | chpasswd \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN sed -i "s/# \(en_US\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && sed -i "s/# \(ja_JP\.UTF-8 .*\)/\1/" /etc/locale.gen \
  && locale-gen \
  && mkdir -p /Games \
  && echo "load-module module-native-protocol-tcp auth-anonymous=1" >> /etc/pulse/default.pa

RUN wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip -O Hack.zip \
  && unzip Hack.zip -d /usr/local/share/fonts \
  && git clone https://github.com/yeyushengfan258/Reversal-icon-theme icon-theme \
  && cd icon-theme \
  && bash install.sh -purple \
  && cd .. \
  && rm -rf icon-theme Hack.zip \
  && fc-cache -fv

COPY files/start.sh /start.sh
COPY files/config /home/${USER}/.config/
COPY files/novnc_audio/* /home/${USER}/novnc_audio/
COPY --from=builder /usr/local/cargo/bin/audio_feed /usr/local/bin/audio_feed

RUN cd /home/${USER} \
  && git clone https://github.com/novnc/noVNC \
  && cd novnc_audio \
  && cp audio.js /home/${USER}/noVNC \
  && cd /home/${USER}/noVNC \
  && git apply /home/${USER}/novnc_audio/ui.patch

RUN find /home/${USER} -not -user ${USER} -exec chown ${USER}:${USER} {} \;

USER ${USER}
WORKDIR /home/${USER}
CMD [ "/start.sh" ]
EXPOSE 4713 5700 5900 6100
VOLUME [ "/Games" ]


FROM base AS hangover
ARG HANGOVER_VERSION=10.2

RUN cd \
  && wget -q https://github.com/AndreRH/hangover/releases/download/hangover-${HANGOVER_VERSION}/hangover_${HANGOVER_VERSION}_debian13_trixie_arm64.tar -O hangover.tar \
  && tar xf hangover.tar \
  && sudo apt-get update \
  && sudo apt-get install -q -y --no-install-suggests ./*.deb \
  && rm -rf hangover.tar *.deb \
  && sudo rm -rf /var/lib/apt/lists/*


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
