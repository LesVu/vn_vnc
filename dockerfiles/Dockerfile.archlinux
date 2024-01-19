FROM archlinux:latest

RUN pacman -Syu --noconfirm && pacman -S --noconfirm mesa lutris moreutils git base-devel tigervnc openbox && tac /etc/pacman.conf | sed -i '0,/#Include/{s/#Include/Include/}' | tac | sponge /etc/pacman.conf

# RUN pacman -Syu --noconfirm && sudo pacman -S --noconfirm --needed wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
# mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
# lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
# sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
# ncurses lib32-ncurses ocl-icd lib32-ocl-icd libxslt lib32-libxslt libva lib32-libva gtk3 \
# lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader

RUN useradd --no-create-home --shell=/bin/false build && usermod -L build && echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER build
RUN git clone https://aur.archlinux.org/box86-git.git && cd box86-git && makepkg -s
RUN git clone https://aur.archlinux.org/box64-git.git && cd box64-git && makepkg -s

USER root
RUN pacman -U *.pkg.tar.xz


