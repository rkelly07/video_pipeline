#!/bin/bash
       find /media/My\ Passport/MyRecord/ -name '*.AVI' -print0 | while read -d $'\0' -r file ; do
#		file1=`echo $file | cut -d'.' -f1`.mp4
		file1=`echo $file | cut -d'.' -f1`.avi
		printf 'File found: %s\n' "$file1"
#		rm "$file1"
if [ ! -f "$file1"  ]  ; then 
#		ffmpeg  -i "$file" -r 25 -vcodec libtheora  -acodec libvorbis -ab 96k -vb 3000k "$file1" -r 24 -s 1280x960
		ffmpeg  -i "$file" -r 25 -vcodec libtheora  -acodec libvorbis -ab 96k -vb 3000k "$file1" -r 24 -s 1280x960
#		ffmpeg  -i "$file" "$file1" -s 1280x960
 fi
        done

