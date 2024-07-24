# Initialize
FROM python:3

# Install
RUN apt-get update
RUN git clone https://github.com/EnriqueMoran/remoteDiscordShell.git /app
WORKDIR /app
#RUN apt-get install --yes \
#		net-tools 
RUN pip install --no-cache-dir \ 
		discord \
		requests==2.31.0

WORKDIR /app/data
ENTRYPOINT [ "python3", "/app/pyDiscordShellBot.py" ]