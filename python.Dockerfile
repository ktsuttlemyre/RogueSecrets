FROM ubuntu:22.04

RUN apt-get update -y \
	&& apt-get install -y python3-pip python3-dev \
	&& apt-get install -y build-essential libssl-dev libffi-dev python-dev \
	&& apt-get install -y python3-venv \
	&& pip install --upgrade pip \
	&& apt-get install -y nodejs
RUN npm install -g @bitwarden/cli

WORKDIR /app

COPY requirements.txt .

RUN python -m venv venv \
    && source venv/bin/activate \
    && pip install -r requirements.txt

COPY . .

CMD [ "/bin/sh", "-c", "BW_SESSION=$(bw login --raw) && " ]
