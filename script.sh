#!/bin/bash


## input 1 is the file we're operating on
## input 2 could be number of desired jobs instead of counter?


## USER CONFIG VARS ##

# parse mediainfo output for frame count, select number field, and 
# strip whitespace
frameCount=`mediainfo --fullscan $1 | \
  grep -m 1 'Frame count' | \
  cut -d ':' -f 2 | \
  sed "s/ //"`

  
#new framecount code - commented out for now

#frameCount=`mediainfo --fullscan --Output=JSON incred2.mkv | jq '.media.track[0].FrameCount''

#echo framecount "$framecount"

# jobnum controls how many jobs we're making
jobnum=6

## USER CONFIG VARS ##

# jobsize is number of frames per job
#jobsize=$(((( frameCount / jobnum )) + 1 )) #adding frames to make sure we run off the end - brute force kludge! If too many jobs are built we may have an issue, I'd prefer a sane rounding

jobsize=1000 #changed for testing
#echo jobsize $jobsize 
counter=0
seek=0
chunkstart=0
frames=$(( jobsize + 100 )) #FIRST job gets an added 100 frames, after this we want 200


#crop detection code cribbed elsewhere
cropdetect="$(ffmpeg -ss 13 -i $1 -t 1 -vf "cropdetect=24:16:0" -preset ultrafast -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1)"

while [ $counter -lt $jobnum ]; do

# chunkstart=$(( $seek + 100 ))
# chunkend=$(( $chunkstart + $jobsize ))
# echo
# echo seek $seek then stream $frames frames
# echo chunk starts $chunkstart and goes $jobsize forward to end $chunkend 

	echo "ffmpeg -hide_banner -i "$1" -filter:v "\""$cropdetect"\"" -strict -1 -f yuv4mpegpipe - | x265 - --no-open-gop --seek $seek --frames $frames --chunk-start $chunkstart --chunk-end $jobsize --colorprim bt709 --transfer bt709 --colormatrix bt709 --crf=20 --fps 24000/1001 --min-keyint 24 --keyint 240 --sar 1:1 --preset slow --ctu 16 --y4m --pools "+" -o chunky"$counter".265"
	
 
  # seek should be 100 frames less than the last ending streamed frame
  seek=$(((( $seek + $frames )) -100 )) 
  chunkstart=100
  frames=$(( jobsize + 100 )) #frames, total frames needs to be 200 over jobsize to allow a 100 frame buffer on either end of chunk except FIRST job. Seek gave us the first 100
  
  
 endframe=$(( endframe + jobsize ))
 
 #echo endframe $endframe
  
   ((counter++))


done

