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
  && apt-get install -q -y lutris git cmake binfmt-support wayvnc wayfire xwayland kitty kanshi && rm -rf /var/lib/apt/lists/*

RUN wget https://itai-nelken.github.io/weekly-box86-debs/debian/box86.list -O /etc/apt/sources.list.d/box86.list && wget -qO- https://itai-nelken.github.io/weekly-box86-debs/debian/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg && apt-get update && apt-get install box86:armhf -y -q && rm -rf /var/lib/apt/lists/*

RUN wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg && apt-get update && apt-get install box64-arm64 -y -q && rm -rf /var/lib/apt/lists/*

COPY files/binfmts/* /usr/share/binfmts
RUN update-binfmts --import
RUN mkdir -p $HOME/.local/share/lutris/runners/wine/ && cd $HOME/.local/share/lutris/runners/wine/ && wget -q https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-25/wine-lutris-GE-Proton8-25-x86_64.tar.xz -O wine.tar.xz && tar -xvf wine.tar.xz && rm wine.tar.xz

RUN useradd -m -s /bin/bash -G sudo,video,input,audio,render ${user} && echo "${user}:${user}" | chpasswd && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY files/start.sh /start.sh
COPY files/wayfire.ini /home/${user}/.config/wayfire.ini
RUN chown -R ${user}:${user} /home/${user}

USER ${user}
WORKDIR /home/${user}
CMD [ "/start.sh" ]
