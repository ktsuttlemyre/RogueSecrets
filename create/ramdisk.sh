#! /bin/sh
#https://gist.github.com/Marc-Bender/08cb9c4393e85f74b124fa5f2c83a9eb
if [ "$#" -gt 2 ]; then
	echo "No more than 2 arguments allowed"
 	exit 1
fi
ramdisk="${2:-/mnt/ramdisk}"
if df | grep "$ramdisk" > /dev/null; then
	echo "$ramdisk already mounted"
 	exit 1
fi
if [ "$(grep 'MemFree' /proc/meminfo | grep -o [0-9]*)" -lt "$(numfmt --from=iec $1 --to-unit=1024)" ]; then
	# /proc/meminfo contains lots of information on your memory including the amount of available free memory
	# this information is put through grep to find that exact line that contains the free memory then grep is used again to 
	# remove everything but the numbers (leading to a number with no whitespaces and no unit). That is then compared with the requested RAM-disksize
	# numfmt is used to convert what ever input format your size has to kB (1024 Bytes) so that the existing free memory is comparable with
	# the requested size. The script errors out when less RAM is free that the RAM-disk should be in size because that would lead to 
	# an impossible combination that is oddly enough still executable. E.g. my system has 16G of RAM and I could create a RAM-disk of 20G 
	# using the command below and it would be created... This should not be possible.
	echo 'Too big of a RAM-disk to fit into your available RAM. No RAM-disk was created.'
	echo "The maximum size of a RAM-disk currently possible is $(grep 'MemFree' /proc/meminfo | cut -d: -f2)"
 	exit 1
fi

if [ "$OSTYPE" == "darwin"* ]; then
	#https://superuser.com/questions/1480144/creating-a-ram-disk-on-macos
	#brew install entr
	diskutil apfs create $(hdiutil attach -nomount ram://8192) RogueOSRam && touch $ramdisk/.metadata_never_index
else
	sudo mount -t tmpfs tmpfs "$ramdisk" -o size=$1 && echo RAM-disk of $1 created
fi
