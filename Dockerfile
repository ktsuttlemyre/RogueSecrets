#TODO change to alpine
# original
# https://www.reddit.com/r/Bitwarden/comments/xhir0q/how_to_install_bw_cli_in_docker/
FROM debian:12-slim
#FROM alpine:latest

RUN apt-get update && apt-get install -y npm jq bash git && rm -rf /var/lib/apt/lists/*
#RUN apk update && apk add --no-cache curl --update npm jq bash git && rm -rf /var/cache/apk/*

WORKDIR /rogue/libs
RUN git clone https://github.com/fredpalmer/log4bash.git 

WORKDIR /rogue
COPY . ./

RUN find . -type f -iname "*.sh" -exec chmod +x {} \;
RUN chmod +x ./rogue ./roguerun

ENTRYPOINT ["./rogue"]
