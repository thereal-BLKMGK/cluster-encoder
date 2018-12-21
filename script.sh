#!/bin/bash


## input 1 is the file we're operating on
## input 2 could be number of desired jobs instead of counter?


## USER CONFIG VARS ##

# parse mediainfo output for frame count, select number field, and 
# strip whitespace
#frameCount=`mediainfo --fullscan $1 | \
#  grep -m 1 'Frame count' | \
#  cut -d ':' -f 2 | \
#  sed "s/ //"`

#new framecount code

frameCount=`mediainfo --fullscan --Output=JSON incred2.mkv | jq '.media.track[0].FrameCount''

echo $framecount

# jobnum controls how many jobs we're making
jobnum=60

## USER CONFIG VARS ##


# jobsize is number of frames per job
jobsize=$(( frameCount / jobnum ))
startframe=0
endframe=$jobsize
counter=0

while [ $counter -lt $jobnum ]; do
  echo "ffmpeg -hide_banner -i "$1" -strict -1 -f yuv4mpegpipe - | x265 - --no-open-gop --chunk-start " $startframe" --colorprim bt709 --transfer bt709 --colormatrix bt709 --crf=20 --fps 24000/1001 --min-keyint 24 --keyint 240 --chunk-end " $endframe " --sar 1:1 --preset slow --ctu 16 --y4m --pools "+" -o chunky"$counter".265"
  
  # calc next frame batch; truncate batch size if it exceeds
  # total frame count on last batch
  startframe=$(( startframe + jobsize ))
  endframe=$(( endframe + jobsize ))
  if [ $endframe -ge $frameCount ]; then
    endframe=$frameCount
  fi

  ((counter++))

  echo $startframe
  echo $endframe
done