#! /bin/sh
#https://gist.github.com/Marc-Bender/08cb9c4393e85f74b124fa5f2c83a9eb
if [ "$#" -ne 1 ]
then
	echo Exactly one argument must be given
else
	if df | grep '/mnt/ramdisk' > /dev/null
	then
		echo Already mounted a RAM-disk...
	elif [ `grep 'MemFree' /proc/meminfo | grep -o [0-9]*` -lt `numfmt --from=iec $1 --to-unit=1024` ] 
	# /proc/meminfo contains lots of information on your memory including the amount of available free memory
	# this information is put through grep to find that exact line that contains the free memory then grep is used again to 
	# remove everything but the numbers (leading to a number with no whitespaces and no unit). That is then compared with the requested RAM-disksize
	# numfmt is used to convert what ever input format your size has to kB (1024 Bytes) so that the existing free memory is comparable with
	# the requested size. The script errors out when less RAM is free that the RAM-disk should be in size because that would lead to 
	# an impossible combination that is oddly enough still executable. E.g. my system has 16G of RAM and I could create a RAM-disk of 20G 
	# using the command below and it would be created... This should not be possible.
	then 
		echo Too big of a RAM-disk to fit into your available RAM. No RAM-disk was created.
		echo The maximum size of a RAM-disk currently possible is `grep 'MemFree' /proc/meminfo | cut -d: -f2`
	else
		sudo mount -t tmpfs tmpfs /mnt/ramdisk/ -o size=$1 && echo RAM-disk of $1 created
	fi
fi
