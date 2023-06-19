#!/bin/bash


function getSplitTime() {
  filename=$1
  #filename类似 audio-001-11s.mp3形式，把11s提取出来
  splitTime=`echo ${filename##*-} | cut -d '.' -f 1`
  #如果变量$splitTime非空并且为数字，返回true
  if [ ! -z $splitTime ] && [ $splitTime -eq $splitTime ] 2>/dev/null; then
    echo $splitTime
  else
    echo 0
  fi
}
