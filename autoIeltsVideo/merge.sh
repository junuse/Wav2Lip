#!/bin/bash

function main() {
  #打印帮助提示信息，第一个参数是左视频，第二个参数是右视频，第三个是audio

  if [ $1 = "help" ]; then
    echo "Usage: $0 SUBCMD [args]"
    #说明后面的参数
    echo "SUBCMD:"
    echo "  help:                     print help info"
    echo "  main:                     leftVideo rightVideo audio"
    echo "  fakeVideo/fake:           srcVideo audio"
    echo "  mergeVideos/merge:        leftVideo rightVideo"
    echo "  mergeFinalVideo/final:    video"
    echo "  info:                     mediaFile"
    return
  elif [ $1 = "info" ]; then
    mediaInfo $2
    return
  fi

  #设置工作目录为脚本目录
  cd "$(dirname "$0")"

  CURRENT_DIR=`pwd`
  MERGE_DIR="merge/"
  IMAGE_DIR="image/"
  VIDEO_DIR="video/"
  AUDIO_DIR="audio/"
  FAKED_DIR="faked/"

  APP_IMAGE=$IMAGE_DIR"ielts-app.jpg"
  RESULT_VIDEO="result.mp4"

  if [ $1 = "main" ]; then
    # main: leftVideo rightVideo audio"
    if [ $# -ne 4 ]; then
      echo "main: leftVideo rightVideo audio"
      main "help"
      return
    fi
    #步骤
    # 1.对口型，按照时间点，分别对左右视频的口型
    # 2.合并左右视频
    # 3.将合并后的视频嵌入到图片中

    # main: leftVideo rightVideo audio"
    LEFT_VIDEO=$VIDEO_DIR$2
    RIGHT_VIDEO=$VIDEO_DIR$3
    AUDIO=$AUDIO_DIR"$4"

    #working file
    FAKED_LEFT_VIDEO=$FAKED_DIR$4$2
    FAKED_RIGHT_VIDEO=$FAKED_DIR$4$3
    LRMERGE_VIDEO=$MERGE_DIR"$2$3"

    #TODO, 将AUDIO按照时间点分为left right 口型audio
    fakeVideo $LEFT_VIDEO $AUDIO $FAKED_LEFT_VIDEO
    #判断返回结果
    if [ ! -f $FAKED_LEFT_VIDEO ]; then
      echo "failed to create $FAKED_LEFT_VIDEO"
      return
    fi
    fakeVideo $RIGHT_VIDEO $AUDIO $FAKED_RIGHT_VIDEO
    if [ ! -f $FAKED_RIGHT_VIDEO ]; then
      echo "failed to create $FAKED_RIGHT_VIDEO"
      return
    fi
    mergeVideos $FAKED_LEFT_VIDEO $FAKED_RIGHT_VIDEO $LRMERGE_VIDEO
    if [ ! -f $LRMERGE_VIDEO ]; then
      echo "failed to create $LRMERGE_VIDEO"
      return
    fi
    mergeFinalVideo $APP_IMAGE $LRMERGE_VIDEO $RESULT_VIDEO
    if [ ! -f $RESULT_VIDEO ]; then
      echo "failed to create $RESULT_VIDEO"
      return
    fi
  elif [ $1 = "fakeVideo" ] || [ $1 = "fake" ]; then
    # fakeVideo: srcVideo audio
    if [ $# -ne 3 ]; then
      echo "fakeVideo: srcVideo audio"
      main "help"
      return
    fi
    FAKED=$FAKED_DIR$3$2
    fakeVideo $VIDEO_DIR"$2" $AUDIO_DIR"$3" $FAKED
  elif [ $1 = "mergeVideos" ] || [ $1 = "merge" ]; then
    # mergeVideos: leftVideo rightVideo
    if [ $# -ne 3 ]; then
      echo "mergeVideos: leftVideo rightVideo"
      main "help"
      return
    fi
    MERGED=$MERGE_DIR"$2$3"
    mergeVideos $VIDEO_DIR"$2" $VIDEO_DIR"$3" $MERGED
  elif [ $1 = "mergeFinalVideo" ] || [ $1 = "final" ]; then
    # mergeFinalVideo: video
    if [ $# -ne 2 ]; then
      echo "mergeFinalVideo: video"
      main "help"
      return
    fi
    MERGED=$CURRENT_DIR"/result.mp4"
    mergeFinalVideo $APP_IMAGE $FAKED_DIR"$2" $MERGED
  else
    echo "unknown subcmd: $1"
    main "help"
  fi
}

fakeVideo() {
  iVIDEO=$1
  iAUDIO=$2
  iFAKED_VIDEO=$3

  echo "fakeVideo $iVIDEO $iAUDIO $iFAKED_VIDEO"
  #判断是否存在该文件
  if [ ! -f $iVIDEO ]; then
    echo "file $iVIDEO not exists"
    return
  fi
  if [ ! -f $iAUDIO ]; then
    echo "file $iAUDIO not exists"
    return
  fi
  if [ -f $iFAKED_VIDEO ]; then
    #询问是否删除该文件，等待3秒，若未输入，缺省为不删除
    read -t 3 -p "file $iFAKED_VIDEO exists, delete it? [y/N]" DEL
    #如果DEL为空或者不是y，则缺省为不删除
    if [ -z $DEL ] || [ $DEL != "y" ]; then
      echo "file $iFAKED_VIDEO exists, skip"
      return
    else
      rm -f $iFAKED_VIDEO
    fi
  fi
  CURRENT_DIR=`pwd`
  cd ../
  CMD="python inference.py --checkpoint_path wav2lip_gan.pth --face $CURRENT_DIR"/"$iVIDEO --audio $CURRENT_DIR"/"$iAUDIO --nosmooth"
  echo "-------------------"
  echo $CMD
  echo "-------------------"
  eval $CMD

  #判断是否生成了结果文件
  if [ ! -f results/result_voice.mp4 ]; then
    echo "failed to create results/result_voice.mp4"
    return
  fi
  mv results/result_voice.mp4 $CURRENT_DIR"/"$iFAKED_VIDEO
  echo "faked video: $iFAKED_VIDEO created"
  cd $CURRENT_DIR
}

mergeVideos() {
  iLEFT_VIDEO=$1
  iRIGHT_VIDEO=$2
  iRESULT_VIDEO=$3
  if [ -f $iRESULT_VIDEO ]; then
    read -t 3 -p "file $iRESULT_VIDEO exists, delete it? [y/N]" DEL
    if [ -z $DEL ] || [ $DEL != "y" ]; then
      echo "file $iRESULT_VIDEO exists, skip"
      return
    else
      rm -f $iRESULT_VIDEO
    fi
  fi

  echo "mergeVideos $iLEFT_VIDEO $iRIGHT_VIDEO $iRESULT_VIDEO"
  #ffmpeg将两个视频合并为一个视频，左视频宽度为640，右视频宽度为368，视频高度为640，视频时长以左视频为准
  CMD="ffmpeg -i $iLEFT_VIDEO -i $iRIGHT_VIDEO -filter_complex \"[0:v]scale=512:640,setsar=1[0v];[1:v]scale=512:640,setsar=1[1v];[0v][1v]hstack=inputs=2[v]\" -map \"[v]\" -map 0:a -c:a copy -c:v libx264 -crf 23 -preset veryfast -t $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $iLEFT_VIDEO) $iRESULT_VIDEO"
  echo "-------------------"
  echo $CMD
  echo "-------------------"
  eval $CMD

  if [ $? -ne 0 ]; then
    echo "mergeVideos failed"
    return
  fi
  echo "merged video: $iRESULT_VIDEO created"
}
mergeFinalVideo() {
  iAPP_IMAGE=$1
  iVIDEO=$2
  iRESULT_VIDEO=$3
  if [ -f $iRESULT_VIDEO ]; then
    rm -f $iRESULT_VIDEO
  fi
  echo "mergeFinalVideo $iAPP_IMAGE $iVIDEO $iRESULT_VIDEO"
  #ffmpeg将视频output.mp4嵌入到图片ielts-app.jpg中，调整视频的宽度为图片宽度，调整视频高度为182，视频在图片的位置为248，视频时长以图片为准
#  ffmpeg -i $iAPP_IMAGE -i $VIDEO -filter_complex "[1:v]scale=288:182[1v];[0:v][1v]overlay=0:66[outv]" -map "[outv]" -map 1:a -c:a copy -c:v libx264 -crf 23 -preset veryfast $iRESULT_VIDEO
  #将上面的命令放到CMD，并执行
  CMD="ffmpeg -i $iAPP_IMAGE -i $iVIDEO -filter_complex \"[1:v]scale=288:182[1v];[0:v][1v]overlay=0:66[outv]\" -map \"[outv]\" -map 1:a -c:a copy -c:v libx264 -crf 23 -preset veryfast $iRESULT_VIDEO"
  echo "-------------------"
  echo $CMD
  echo "-------------------"
  eval $CMD

  if [ $? -ne 0 ]; then
    echo "mergeFinalVideo failed"
    return
  fi
  echo "merged final video: $iRESULT_VIDEO created"
}

mediaInfo() {
  iMEDIA=$1
  CMD="ffmpeg -i $iMEDIA"
  eval $CMD
}

#如果没有参数，则打印帮助信息
if [ $# -eq 0 ]; then
  main "help"
else
  #如果有参数，则执行main函数
  main "$@"
fi