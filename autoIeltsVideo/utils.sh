#!/bin/bash


function cropFinalVideo() {
  # $1: 带app屏视频文件
  # $2: 抠对话窗
  vWithApp=$1
  vDialog=$2
  #判断vDialog是否存在
  if [ -f $vDialog ]; then
    echo "$vDialog already exists"
    return 1
  fi
  #获取vWithApp分辨率
  vWithAppWidth=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 $vWithApp)
  vWithAppHeight=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 $vWithApp)
  echo "vWithAppWidth: $vWithAppWidth, vWithAppHeight: $vWithAppHeight"
  #根据高度提供对话框尺寸与位置
  if [ $vWithAppHeight -eq 1280 ]; then
    dialogWidth=545
    dialogHeight=334
    startX=15
    startY=180
  else
    echo "Unknown app video height"
    return 2
  fi
  echo "dialogWidth: $dialogWidth, dialogHeight: $dialogHeight, startX: $startX, startY: $startY"
  #根据对话框坐标，计算出对话框的区域
  dialogArea="${dialogWidth}:${dialogHeight}:${startX}:${startY}"
  echo "dialogArea: $dialogArea"
  #根据对话框区域，抠出对话框
  CMD="ffmpeg -i $vWithApp -filter:v \"crop=$dialogArea\" $vDialog"
  echo $CMD
  eval $CMD
  if [ $? -ne 0 ]; then
    echo "Failed to crop dialog from $vWithApp"
    rm -f $vDialog
    return 2
  else
    return 0
  fi
}

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
    newfilename=`echo "$filename" | sed "s/$1/$2/"`
    echo "mv $filename $newfilename"
    mv "$filename" "$newfilename"
  done
}

function blankInFilename() {
  #将当前目录下文件名包含$1字符串的文件名替换为$2
  for filename in *$1*; do
    newfilename=`echo "$filename" | sed "s/ //g"`
    echo "mv $filename $newfilename"
    mv "$filename" "$newfilename"
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

function cropFinalVideo() {
  # $1: 带app屏视频文件
  # $2: 抠对话窗
  vWithApp=$1
  vDialog=$2
  #判断vDialog是否存在
  if [ -f $vDialog ]; then
    echo "$vDialog already exists"
    return 1
  fi
  #获取vWithApp分辨率
  vWithAppWidth=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 $vWithApp)
  vWithAppHeight=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 $vWithApp)
  echo "vWithAppWidth: $vWithAppWidth, vWithAppHeight: $vWithAppHeight"
  #根据高度提供对话框尺寸与位置
  if [ $vWithAppHeight -eq 1280 ]; then
    dialogWidth=545
    dialogHeight=334
    startX=15
    startY=180
  else
    echo "Unknown app video height"
    return 2
  fi
  echo "dialogWidth: $dialogWidth, dialogHeight: $dialogHeight, startX: $startX, startY: $startY"
  #根据对话框坐标，计算出对话框的区域
  dialogArea="${dialogWidth}:${dialogHeight}:${startX}:${startY}"
  echo "dialogArea: $dialogArea"
  #根据对话框区域，抠出对话框
  CMD="ffmpeg -i $vWithApp -filter:v \"crop=$dialogArea\" $vDialog"
  #ffmpeg -i src.mp4 -filter:v "crop=270:368:185:0" dst.mp4
  echo $CMD
  eval $CMD
  if [ $? -ne 0 ]; then
    echo "Failed to crop dialog from $vWithApp"
    rm -f $vDialog
    return 2
  else
    return 0
  fi
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

isMaterialSeqLaterThan() {
  #判断文件前7个字符是否大于$2
  leftFileNameNoPathNoExt=$(getFileNameNoPathNoExt $1)
  rightFileNameNoPathNoExt=$(getFileNameNoPathNoExt $2)
  if [[ ${leftFileNameNoPathNoExt:0:7} > $rightFileNameNoPathNoExt ]]; then
    echo true
  else
    echo false
  fi
}
setInRegression() {
  export IELTS_IN_REGRESSION=true
}
unsetInRegression() {
  #删除环境变量IELTS_IN_REGRESSION
  unset IELTS_IN_REGRESSION
}
isInRegression() {
  if [ -v IELTS_IN_REGRESSION ] && [ $IELTS_IN_REGRESSION == "true" ]; then
    echo true
  else
    echo false
  fi
}

makeRoleAudio() {
  audioPath=$1
  examAudioPath=$2
  candidateAudioPath=$3

  if [ -f $examAudioPath ]; then
    if [ $(isInRegression) == "true" ]; then
      echo "In regression, file $examAudioPath exists, skip"
      return
    fi
    #询问是否删除，等待3s，默认不删除
    read -t 3 -p "file $examAudioPath exists, delete it? [y/N]" DEL
    #如果DEL为空或者不是y，则缺省为不删除
    if [ -z $DEL ] || [ $DEL != "y" ]; then
      echo "file $examAudioPath exists, skip"
      return
    else
      rm -f $examAudioPath $candidateAudioPath
    fi
  fi

  audioNameNoExt=$(getFileNameNoPathNoExt $audioPath)
  audioExt=$(getFileExt $audioPath)

  #从名字part1audio001-1-s0t15-turn-3-7-9中分离出swap后面的数字列表，这个数字列表是变长的，将这些数字分离出来，用于后面的循环
  swapTimeSecs=`echo $audioNameNoExt | sed 's/.*swap-\([0-9]\+\(-[0-9]\+\)*\).*/\1/'`
  #考官音频filter
  examinerFilter=$(makeAudioFilter $swapTimeSecs"-100000")
  CMD="ffmpeg -i $audioPath -af \"$examinerFilter\" -y $examAudioPath"
  echo $CMD
  eval $CMD
  if [ ! -f $examAudioPath ]; then
    echo "failed to create $examAudioPath"
    exit 1
  fi
  #考生音频filter
  candidateFilter=$(makeAudioFilter "0-"$swapTimeSecs)
#  ffmpeg -i $audioPath -af "$candidateFilter" -y $candidateAudioPath
  CMD="ffmpeg -i $audioPath -af \"$candidateFilter\" -y $candidateAudioPath"
  echo $CMD
  eval $CMD

  if [ ! -f $candidateAudioPath ]; then
    echo "failed to create $candidateAudioPath"
    exit 1
  fi
  echo "makeRoleAudio $audioPath $examAudioPath $candidateAudioPath"" created"

}

makeAudioFilter() {
  #3-5-9-10
  swaps=$1

  #将类似3-7-9的数字列表转换为数字列表
  swapTimeSecs=`echo $swaps | sed 's/-/ /g'`

  started=false
  newStart=true
  filterStr=""
  buffer=""
  for s in $swapTimeSecs
  do
    if [ $started == "false" ]; then
      if [ $newStart == "true" ]; then
        buffer="volume=enable='between(t,$s,"
        newStart=false
      else
        buffer="+between(t,$s,"
      fi
      started=true
      continue
    else
      buffer=$buffer"$s)"
      started=false
    fi
    if [ $started == "false" ]; then
      filterStr=$filterStr$buffer
    fi
  done
  filterStr=$filterStr"':volume=0'"
  echo $filterStr
}

cropVideoWindow() {
  width=$1
  hight=$2
  startX=$3
  startY=$4
  inputFile=$5
  outputFile=$6
  CMD="ffmpeg -i $inputFile -filter:v \"crop=$width:$hight:$startX:$startY\" $outputFile"
  echo $CMD
  eval $CMD
}

ffmpegSnapshotVideo() {
  inputFile=$1
  outputFile=$(getFileNameNoPathNoExt $inputFile)".jpg"
  CMD="ffmpeg -i $inputFile -y -f image2 -ss 00:00:01 -vframes 1 $outputFile"
  echo $CMD
  eval $CMD
}

ffmpegDelogo() {
  W=$1
  H=$2
  X=$3
  Y=$4
  inputFile=$5
  outputFile=$(getFileNameNoPathNoExt $inputFile)_delogo.mp4
  #ffmpeg将一个视频中间的区域水印去除
  cmd="ffmpeg -i $inputFile -vf delogo=x=$X:y=$Y:w=$W:h=$H $outputFile"
  echo $cmd
  eval $cmd
}

ffmpegCropVideoWindowAutoCropName() {
  width=$1
  hight=$2
  startX=$3
  startY=$4
  inputFile=$5
  outputFile=$(getFileNameNoPathNoExt $inputFile)"-"$width"-"$hight"-"$startX"-"$startY".mp4"
  cropVideoWindow $width $hight $startX $startY $inputFile $outputFile
}

getCombinations() {
  combinationCount=$1
  #后续所有参数的列表
  inputList=${@:2}
  #后续所有参数的个数减一
  inputListCount=$(($# - 1))
  echo "inputList($inputListCount) is: $inputList"
  #向inputList增加"a"
  inputList=$inputList" a"
  #inputList增加"a"后的个数
  inputListCount=$(($inputListCount + 1))
  echo "inputList$inputListCount is: $inputList"
  #产生所有的组合
#  combinations=$(getCombinations $combinationCount $inputList)
#  echo "combinations is: $combinations"
}

getPythonResult() {

  # 调用Python脚本并获取结果
  result=$(python py-utils/getCombinationsOfList.py 3 1 1 2 3 4)

  # 打印结果
  echo "结果是：$result"

}

medias2mp3() {
  #将当前目录所有不是mp3的文件转为mp3
  for file in `ls`
  do
    if [ -f $file ]; then
      if [ $(getFileExt $file) != "mp3" ]; then
        ffmpeg -i $file -f mp3 -vn $file".mp3"
      fi
    fi
  done
}


function extendAudioTo22s() {
  #获取input.mp3的长度
  duration=$(ffprobe -i input.mp3 -show_entries format=duration -v quiet -of csv="p=0")
  #获取duration对22取余
  remainder=$(echo "$duration%22" | bc)
  echo "duration: $duration, remainder: $remainder"
  #22减去reminder即为需要静音的时间
  pad=$(echo "22-$remainder" | bc)
  echo "pad: $pad"

  cmd="ffmpeg -i input.mp3 -af apad=pad_dur=$pad output.mp3"
  echo $cmd
  eval $cmd
}


function concatVideo() {
  #concat 2 video to one
  ffmpeg -i $1 -i $2 -filter_complex "[0:v] [0:a] [1:v] [1:a] concat=n=2:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" output.mp4
}

function concatMp3() {
  ffmpeg -i $1 -i $2 -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1[outa]" -map "[outa]" concat.mp3
}

function coverVideo() {
  srcVideo=$1
  coverVideo=$2
  outputVideo=$(getFileNameNoPathNoExt $srcVideo)"_"$(getFileNameNoPathNoExt $coverVideo)".mp4"
  #ffmpeg -i src.mp4 -i cover.mp4 -filter_complex "[0:v] [0:a] [1:v] [1:a] concat=n=2:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" dst.mp4
  cmd="ffmpeg -i $srcVideo -i $coverVideo -filter_complex \"[0:v]scale=544:334[0v];[1:v]scale=270:334[1v];[0v][1v]overlay=0:0[outv]\" -map \"[outv]\" -map 0:a -c:a copy -c:v libx264 -crf 23 -preset veryfast $outputVideo"
  echo $cmd
  eval $cmd
}

#splitMp3ByTime 184_we.mp3 lsnjy15t4p 07:54 14:15 21:14
function splitMp3ByTime() {
  sourceAudio=$1
  paperId=$2
  testId=$3
  shift 3
  #将剩余参数转换为数组
  timeArray=($@)
  #数组前面加一个元素00:00
  timeArray=("00:00" "${timeArray[@]}")
  echo $timeArray
  #数组长度
  timeArrayLength=${#timeArray[@]}
  echo ${#timeArray[@]}
  #数组长度减一
  timeArrayLengthMinusOne=$(($timeArrayLength - 1))
  #遍历数组
  for i in $(seq 0 $timeArrayLengthMinusOne)
  do
    #如果是最后一个元素
    if [ $i -eq $timeArrayLengthMinusOne ]; then
      #从最后一个元素开始到最后
      startTime=${timeArray[$i]}
      endTime="59:59"
    else
      #从当前元素开始到下一个元素
      startTime=${timeArray[$i]}
      endTime=${timeArray[$(($i + 1))]}
    fi
    #输出文件名
    outputAudio="lsnjy"$paperId"t"$testId"p"$(($i + 1))".mp3"
    #ffmpeg -i input.mp3 -ss 00:00:00 -to 00:00:10 -c copy output.mp3
    cmd="ffmpeg -i $sourceAudio -ss $startTime -to $endTime -c copy $outputAudio"
    echo $cmd
    eval $cmd
  done
}