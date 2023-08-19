FROM ubuntu:22.04

RUN apt-get update \
  && apt-get -y install \
    curl \
    npm \
    python3-pip \
    sudo
RUN type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y) \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
RUN npm install -g nushell
RUN pip install cargo-zigbuild

RUN useradd -m build
USER build

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

SHELL [ "/usr/local/bin/nu", "-c" ]

COPY targets.txt /targets.txt

COPY entrypoint.nu /entrypoint.nu

WORKDIR /work
ENTRYPOINT [ "/entrypoint.nu" ]
