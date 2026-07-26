FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ═══════════════════════════════════════════════
# Layer 1  BASE + CORE PACKAGES
# ═══════════════════════════════════════════════
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dialog locales ca-certificates sudo \
        curl wget zip unzip jq tree less && \
    apt-get upgrade -y -o Dpkg::Options::='--force-confold' && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════════
# Layer 2  XFCE + GUI + BROWSER + THEMES
# ═══════════════════════════════════════════════
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus-x11 xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar xfdesktop4 libgl1 librsvg2-common \
        pulseaudio-utils netcat-openbsd x11-xserver-utils \
        xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-genmon-plugin \
        mousepad ristretto tumbler adwaita-icon-theme \
        orchis-gtk-theme elementary-xfce-icon-theme \
        firefox-esr \
        mesa-utils glmark2 \
        xdotool \
        gnupg \
        yad && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════════
# Layer 3  DEV TOOLS + SYSTEM + NODE.JS
# ═══════════════════════════════════════════════
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git python3-pip python3-venv python3-dev \
        build-essential cmake pkg-config \
        htop tmux openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════════
# Layer 4  CONFIGS + USER + CLEANUP
# ═══════════════════════════════════════════════
RUN printf '#!/bin/sh\nexit 1\n' > /usr/bin/pm-is-supported && chmod +x /usr/bin/pm-is-supported && \
    dpkg --purge libupower-glib3 2>/dev/null || true && \
    useradd -m -s /bin/bash admin && \
    echo "admin:admin" | chpasswd && \
    echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin && \
    chmod 0440 /etc/sudoers.d/admin

COPY configs-target/home/ /home/

RUN chown -R admin:admin /home/admin && \
    chmod +x /home/admin/.arinanox/tools/*.sh && \
    sed -i 's|.droiddesk/|.arinanox/|g' /home/admin/.bashrc && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

CMD ["/bin/bash"]
