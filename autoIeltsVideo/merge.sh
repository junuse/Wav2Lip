#!/bin/bash

function main() {
  #打印帮助提示信息，第一个参数是左视频，第二个参数是右视频，第三个是audio

  if [ $1 = "help" ]; then
    echo "Usage: $0 SUBCMD [args]"
    #说明后面的参数
    echo "SUBCMD:"
    echo "  help:                     print help info"
    echo "  main:                     leftVideo rightVideo audio splitTime"
    echo "  fakeVideo/fake:           srcVideo audio"
    echo "  merge2Videos/merge2:      leftVideo rightVideo"
    echo "  mergeFinalVideo/final:    video"
    echo "  mergeAllVideos/merge:     leftVideo rightVideo"
    echo "  info:                     mediaFile"
    echo "  splitAudio/split:         audioFile time"
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
  RESULT_DIR="result/"

  APP_IMAGE=$IMAGE_DIR"ielts-app.jpg"
  RESULT_VIDEO="result.mp4"

  if [ $1 = "main" ]; then
    # main: leftVideo rightVideo audio"
    if [ $# -ne 5 ]; then
      echo "main: leftVideo rightVideo audio splitTime"
      main "help"
      return
    fi
    #步骤
    # 1.对口型，按照时间点，分别对左右视频的口型
    # 2.合并左右视频
    # 3.将合并后的视频嵌入到图片中

    # main: leftVideo rightVideo audio splitTime"
    # PATH, directory, file
    # FILE, filename.extension
    # NAME, filename,no extension
    LEFT_VIDEO_SRC_PATH=$2
    RIGHT_VIDEO_SRC_PATH=$3
    AUDIO_SRC_PATH="$4"
    SPLIT_TIME=$5

    AUDIO_SRC_FILE=${AUDIO_SRC_PATH##*/}
    AUDIO_SRC_FILENAME=${AUDIO_SRC_FILE%.*}
    AUDIO_SRC_FILE_EXT=${AUDIO_SRC_FILE##*.}

    #TODO, 将AUDIO按照时间点分为left right 口型audio
    #将audio文件名的扩展名之前加上数字1，作为左视频的audio文件名
    LEFT_AUDIO_PATH=$AUDIO_DIR$AUDIO_SRC_FILENAME"_${SPLIT_TIME}s_1."$AUDIO_SRC_FILE_EXT
    #将audio文件名的扩展名之前加上数字2，作为右视频的audio文件名
    RIGHT_AUDIO_PATH=$AUDIO_DIR$AUDIO_SRC_FILENAME"_${SPLIT_TIME}s_2."$AUDIO_SRC_FILE_EXT

    splitAudio $AUDIO_SRC_PATH $SPLIT_TIME $LEFT_AUDIO_PATH $RIGHT_AUDIO_PATH

    #对左右视频的口型
    LEFT_VIDEO_SRC_FILE=${LEFT_VIDEO_SRC_PATH##*/}
    RIGHT_VIDEO_SRC_FILE=${RIGHT_VIDEO_SRC_PATH##*/}
    LEFT_VIDEO_SRC_FILENAME=${LEFT_VIDEO_SRC_FILE%.*}
    RIGHT_VIDEO_SRC_FILENAME=${RIGHT_VIDEO_SRC_FILE%.*}
    FAKED_LEFT_VIDEO=$FAKED_DIR$AUDIO_SRC_FILENAME"_${SPLIT_TIME}s_1_"$LEFT_VIDEO_SRC_FILE
    FAKED_RIGHT_VIDEO=$FAKED_DIR$AUDIO_SRC_FILENAME"_${SPLIT_TIME}s_2_"$RIGHT_VIDEO_SRC_FILE
    LRMERGE_VIDEO=$MERGE_DIR$LEFT_VIDEO_SRC_FILENAME"_"$RIGHT_VIDEO_SRC_FILENAME"_"$AUDIO_SRC_FILENAME"_"$SPLIT_TIME"s.mp4"

    fakeVideo $LEFT_VIDEO_SRC_PATH $LEFT_AUDIO_PATH $FAKED_LEFT_VIDEO
    #判断返回结果
    if [ ! -f $FAKED_LEFT_VIDEO ]; then
      echo "failed to create $FAKED_LEFT_VIDEO"
      return
    fi
    fakeVideo $RIGHT_VIDEO_SRC_PATH $RIGHT_AUDIO_PATH $FAKED_RIGHT_VIDEO
    if [ ! -f $FAKED_RIGHT_VIDEO ]; then
      echo "failed to create $FAKED_RIGHT_VIDEO"
      return
    fi

    #合并左右视频
    merge2Videos $FAKED_LEFT_VIDEO $FAKED_RIGHT_VIDEO $LRMERGE_VIDEO
    if [ ! -f $LRMERGE_VIDEO ]; then
      echo "failed to create $LRMERGE_VIDEO"
      return
    fi

    #将合并后的视频嵌入到图片中
    FINAL_SPEC_NAME=$RESULT_DIR$LEFT_VIDEO_SRC_FILENAME"_"$RIGHT_VIDEO_SRC_FILENAME"_"$AUDIO_SRC_FILENAME"_"$SPLIT_TIME"s.mp4"
    mergeFinalVideo $APP_IMAGE $LRMERGE_VIDEO $FINAL_SPEC_NAME
    if [ ! -f $RESULT_VIDEO ]; then
      echo "failed to create $RESULT_VIDEO"
      return
    fi
  elif [ $1 = "splitAudio" ] || [ $1 = "split" ]; then
    # splitAudio: audioFile time
    if [ $# -ne 3 ]; then
      echo "splitAudio: audioFile time"
      main "help"
      return
    fi

    AUDIO_NAME=${2%.*}
    AUDIO=$2
    SPLIT_TIME=$3
    #将audio文件名的扩展名之前加上数字1，作为左视频的audio文件名
    LEFT_AUDIO=$AUDIO_NAME"_${SPLIT_TIME}s_1."${2##*.}
    #将audio文件名的扩展名之前加上数字2，作为右视频的audio文件名
    RIGHT_AUDIO=$AUDIO_NAME"_${SPLIT_TIME}s_2."${2##*.}

    splitAudio $2 $SPLIT_TIME $LEFT_AUDIO $RIGHT_AUDIO
  elif [ $1 = "fakeVideo" ] || [ $1 = "fake" ]; then
    # fakeVideo: srcVideo audio
    if [ $# -ne 3 ]; then
      echo "fakeVideo: srcVideo audio"
      main "help"
      return
    fi
    #本地变量，去掉$2中的路径，只保留文件名
    VIDEO_FILE=${2##*/}
    #去掉$3中的路径，只保留文件名，去掉扩展名
    AUDIO=${3##*/}
    AUDIO_NAME=${AUDIO%.*}

    FAKED=$FAKED_DIR$AUDIO_NAME"_"$VIDEO_FILE
    fakeVideo "$2" "$3" $FAKED
  elif [ $1 = "merge2Videos" ] || [ $1 = "merge2" ]; then
    # mergeVideos: leftVideo rightVideo
    if [ $# -ne 3 ]; then
      echo "merge2Videos: leftVideo rightVideo"
      main "help"
      return
    fi
    #去掉$2中的路径，只保留文件名
    LEFT_VIDEO=${2##*/}
    LEFT_VIDEO_NAME=${LEFT_VIDEO%.*}
    #去掉$3中的路径，只保留文件名
    RIGHT_VIDEO=${3##*/}
    MERGED=$MERGE_DIR$LEFT_VIDEO_NAME"_"$RIGHT_VIDEO
    merge2Videos "$2" "$3" $MERGED
  elif [ $1 = "mergeFinalVideo" ] || [ $1 = "final" ]; then
    # mergeFinalVideo: video
    if [ $# -ne 2 ]; then
      echo "mergeFinalVideo: video"
      main "help"
      return
    fi
    MERGED=$CURRENT_DIR"/result.mp4"
    mergeFinalVideo $APP_IMAGE "$2" $MERGED
  elif [ $1 = "mergeAllVideos" ] || [ $1 = "merge" ]; then
    # mergeAllVideos: leftVideo rightVideo
    if [ $# -ne 3 ]; then
      echo "mergeAllVideos: leftVideo rightVideo"
      main "help"
      return
    fi
    #去掉$2中的路径，只保留文件名
    LEFT_VIDEO=${2##*/}
    #去掉$3中的路径，只保留文件名
    RIGHT_VIDEO=${3##*/}
    MERGED1=$MERGE_DIR"$LEFT_VIDEO$RIGHT_VIDEO"
    merge2Videos "$2" "$3" $MERGED1
    MERGED2=$CURRENT_DIR"/result.mp4"
    mergeFinalVideo $APP_IMAGE $MERGED1 $MERGED2
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
    read -t 6 -p "file $iFAKED_VIDEO exists, delete it? [y/N]" DEL
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

merge2Videos() {
  iLEFT_VIDEO=$1
  iRIGHT_VIDEO=$2
  iRESULT_VIDEO=$3
  if [ -f $iRESULT_VIDEO ]; then
    read -t 6 -p "file $iRESULT_VIDEO exists, delete it? [y/N]" DEL
    if [ -z $DEL ] || [ $DEL != "y" ]; then
      echo "file $iRESULT_VIDEO exists, skip"
      return
    else
      rm -f $iRESULT_VIDEO
    fi
  fi

  echo "merge2Videos $iLEFT_VIDEO $iRIGHT_VIDEO $iRESULT_VIDEO"
  #ffmpeg将两个视频合并为一个视频，左视频宽度为640，右视频宽度为368，视频高度为640，视频时长以左视频为准
  CMD="ffmpeg -i $iLEFT_VIDEO -i $iRIGHT_VIDEO -filter_complex \"[0:v]scale=512:640,setsar=1[0v];[1:v]scale=512:640,setsar=1[1v];[0v][1v]hstack=inputs=2[v];[0:a][1:a]amix=inputs=2[a]\" -map \"[v]\" -map \"[a]\" -c:a aac -c:v libx264 -crf 23 -preset veryfast -t $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $iLEFT_VIDEO) $iRESULT_VIDEO"
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

splitAudio() {
  iAudio=$1
  iSplitPoint=$2
  iSubAudio1=$3
  iSubAudio2=$4
  #删除文件iSubAudio1和iSubAudio2，如果存在
  if [ -f $iSubAudio1 ]; then
    #询问是否删除，等待3s，默认不删除
    read -t 6 -p "file $iSubAudio1 exists, delete it? [y/N]" DEL
    #如果DEL为空或者不是y，则缺省为不删除
    if [ -z $DEL ] || [ $DEL != "y" ]; then
      echo "file $iSubAudio1 exists, skip"
      return
    else
      rm -f $iSubAudio1 $iSubAudio2
    fi
  fi
  #将音频iAudio的时间点iSplitPoint之后静音，维持音频长度，生成音频iSubAudio1
  CMD1="ffmpeg -i $iAudio -af \"volume=enable='between(t,$iSplitPoint,100000)':volume=0\" $iSubAudio1"
  echo $CMD1
  eval $CMD1
  #检查是否生成了音频iSubAudio1
  if [ ! -f $iSubAudio1 ]; then
    echo "failed to create $iSubAudio1"
    return
  fi
  #将音频iAudio的时间点iSplitPoint之前静音，维持音频长度，生成音频iSubAudio2
  CMD2="ffmpeg -i $iAudio -af \"volume=enable='between(t,0,$iSplitPoint)':volume=0\" $iSubAudio2"
  echo $CMD2
  eval $CMD2
  #检查是否生成了音频iSubAudio2
  if [ ! -f $iSubAudio2 ]; then
    echo "failed to create $iSubAudio2"
    return
  fi
  echo "splitAudio $iAudio $iSplitPoint $iSubAudio1 $iSubAudio2"" created"
}

#如果没有参数，则打印帮助信息
if [ $# -eq 0 ]; then
  main "help"
else
  #如果有参数，则执行main函数
  main "$@"
fi