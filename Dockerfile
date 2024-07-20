#TODO change to alpine
# original
# https://www.reddit.com/r/Bitwarden/comments/xhir0q/how_to_install_bw_cli_in_docker/
FROM alpine:latest

WORKDIR /rogue

RUN apk update && apk add --no-cache curl --update npm jq bash git && rm -rf /var/cache/apk/*

COPY . ./

WORKDIR /rogue/libs
RUN git clone https://github.com/fredpalmer/log4bash.git 
WORKDIR /rogue

RUN find . -type f -iname "*.sh" -exec chmod +x {} \;

RUN npm install -g @bitwarden/cli
#  export url=$(curl -H "Accept: application/vnd.github+json" https://api.github.com/repos/bitwarden/cli/releas>
#  && curl -LO "$url" \
#  && unzip *.zip \
#  && chmod +x ./bw \
#  && rm bw-linux-*.zip

Run bw --version

ENTRYPOINT ["./rogue"]
