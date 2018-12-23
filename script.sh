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


# jobnum controls how many jobs we're making
jobnum=6

## USER CONFIG VARS ##


# jobsize is number of frames per job
jobsize=$(( frameCount / jobnum )) #Do we need to round this up?

counter=0
seek=(-100)
frames=$(( jobsize + 100 )) #prime frames first stop


#crop detection code cribbed elsewhere
cropdetect="$(ffmpeg -ss 13 -i $1 -t 1 -vf "cropdetect=24:16:0" -preset ultrafast -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1)"


while [ $counter -lt $jobnum ]; do

  echo "ffmpeg -hide_banner -i "$1" -filter:v "$cropdetect" -strict -1 -f yuv4mpegpipe - | x265 - --no-open-gop --seek $seek --frames $frames --chunk-start 100 --chunk-end $jobsize --colorprim bt709 --transfer bt709 --colormatrix bt709 --crf=20 --fps 24000/1001 --min-keyint 24 --keyint 240 --sar 1:1 --preset slow --ctu 16 --y4m --pools "+" -o chunky"$counter".265"
  
  # calc next frame batch; truncate batch size if it exceeds
  # total frame count on last batch
  # seek should be 100 frames less than the last ending frame
  seek=$(( (($seek - 100 )) + $frames ))
  #seek=$(( $jobsize + 200 ))
 endframe=$(( endframe + jobsize ))
  
  # Logic ERROR here - we are missing final frames in the last job. Too tired to fix.
 if [ $endframe -ge $frameCount ]; then
    endframe=$frameCount
  fi

  ((counter++))

# echo startframe $startframe
 #echo endframe $endframe
done

