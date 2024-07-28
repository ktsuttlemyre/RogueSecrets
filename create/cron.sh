#!/bin/bash

cronaction="$1"
cronschedule="$2"
cronuser="$3" #TODO"${3:-rogueos}"
cronscript="$4"
cronjob="$cronschedule $cronuser $cronscript"
(grep "$cronscript" /etc/crontab && grep "$cronschedule") || echo "$cronjob" >> /etc/crontab
