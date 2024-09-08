# original
# https://www.reddit.com/r/Bitwarden/comments/xhir0q/how_to_install_bw_cli_in_docker/
# ideas from
# https://github.com/sudo-bmitch/docker-base/blob/main/Dockerfile.debian

LABEL \
    org.label-schema.docker.cmd="docker run -it --rm ${REGISTRY}/${PROJECT}:latest" \
    org.label-schema.description="Base image for debian" \
    org.label-schema.name="${REGISTRY}/${PROJECT}:debian" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/ktsuttlemyre/RogueCLI" \
    org.label-schema.vendor="Ktsuttlemyre" \
    org.label-schema.version="${IMAGE_VER}"
    
FROM debian:12-slim

COPY functions /usr/bin/

RUN rPM-install \
      #ca-certificates \
      #curl \
      npm \
      jq \
      git

WORKDIR /rogue/libs
RUN git clone https://github.com/fredpalmer/log4bash.git 

WORKDIR /rogue
COPY . ./

RUN find . -type f -iname "*.sh" -exec chmod +x {} \;
RUN chmod +x ./rogue ./roguerun
RUN chmod -R 777 /home

ENTRYPOINT ["./rogue"]
