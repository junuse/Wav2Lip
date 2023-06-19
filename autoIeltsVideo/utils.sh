#!/bin/bash


function getSplitTime() {
  filename=$1
  #filename类似 audio-001-11.mp3形式，把11s提取出来
  splitTime=`echo ${filename##*-} | cut -d '.' -f 1`
  #如果变量$splitTime非空并且为数字，返回true
  if [ ! -z $splitTime ] && [ $splitTime -eq $splitTime ] 2>/dev/null; then
    echo $splitTime
  else
    echo 0
  fi
}

function replaceStrInFilename() {
  #将当前目录下文件名包含$1字符串的文件名替换为$2
  for filename in *$1*; do
    newfilename=`echo $filename | sed "s/$1/$2/"`
    mv $filename $newfilename
  done
}

function getFileListInDirWhichHasPrefix() {
  path=$1
  #获取当前目录下所有文件名以$1开头的文件名
  prefix=$2
  fileList=`ls $path | grep "^$prefix"`
  echo $fileList
}

function isFilePathExist() {
  #判断$1路径是否存在
  if [ -e $1 ]; then
    echo true
  else
    echo false
  fi
}
function isFileExist() {
  #判断$1文件是否存在
  if [ -f $1 ]; then
    echo true
  else
    echo false
  fi
}
function getFileExt() {
  #获取文件名后缀
  filename=$1
  fileExt=`echo ${filename##*.}`
  echo $fileExt
}
function getFileNameNoPath() {
  #获取文件名，不包含路径
  filename=$1
  fileNameNoPath=`echo ${filename##*/}`
  echo $fileNameNoPath
}

function getFileNameNoPathNoExt() {
  #获取文件名，不包含路径和后缀
  filename=$1
  fileNameNoPathNoExt=`echo ${filename##*/}`
  fileNameNoPathNoExt=`echo ${fileNameNoPathNoExt%%.*}`
  echo $fileNameNoPathNoExt
}

isResultFileExistByMaterials() {
#  scriptDir=$(dirname $0)
#  cwd=$(pwd)
#  cd $scriptDir
  examName=$(getFileNameNoPathNoExt $1)
  canName=$(getFileNameNoPathNoExt $2)
  qnaName=$(getFileNameNoPathNoExt $3)
  resultName=${examName}_${canName}_${qnaName}.mp4
  if [ -f "result/"$resultName ]; then
    echo true
  else
    echo false
  fi
}
isReasonableMaterialsCombination() {
  examName=${1%%.*}
  canName=${2%%.*}
  qnaName=${3%%.*}
  if [[ $qnaName =~ -${examName##*-}${canName##*-}- ]]; then
    echo true
  else
    echo false
  fi
}