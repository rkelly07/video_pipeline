ffmpeg -i input.mp4 -filter:v "setpts=0.1*PTS" output.mp4
ffmpeg -i input.mp4 -filter:v "setpts=(1/30)*PTS" -q:v 1 -an -strict -2 output.mp4