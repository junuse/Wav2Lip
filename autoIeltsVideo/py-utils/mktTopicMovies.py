import os
import sys

import subprocess

# 需求
# INPUT
#   1. 一个topic challenge的录屏（包含：多个问答、考官视频可用、全程录音）
#   2. 一个考生（AI）的视频底版

# OUTPUT，options
#   1. 将考生视频刷好，放入final视频
#   2. final视频切分为单个QA


def main():
    pass


def gen(screenFile, canVideoFile, swapPoints):
    print("screenFile:", screenFile)
    print("canVideoFile:", canVideoFile)
    print("swapPoints:", swapPoints)
    swapPoints = eval(swapPoints)
    print("type of swapPoints:", type(swapPoints))
    #用swapPoints（例如 [3,8,13]：考官先问，3s处考生回答，8s处考官发问，13s处考生回答）
    #根据screenFile的音频和swapPoints，给考生视频刷嘴
    #1. 用swapPoints(如[3,8,13,18,19]处理screenFile的音频，将考官部分静音即可，产生新的视频文件screenFileMuteExaminer
    screenFileMuteExaminerMp4 = 'TEMPFILE-screenFileMuteExaminer.mp4'
    #向swapPoints开头插入0
    swapPoints.insert(0, 0)
    #如果swapPoints长度为奇数，向swapPoints末尾插入3600
    if len(swapPoints) % 2 == 1:
        swapPoints.append(3600)
    print("swapPoints:", swapPoints)
    muteOpStr = ''
    for i in range(0, len(swapPoints), 2):
        muteOpStr += 'between(t,' + str(swapPoints[i]) + ',' + str(swapPoints[i+1]) + ')+'
    muteOpStr = muteOpStr[:-1]
    print("muteOpStr:", muteOpStr)
    ffCmd = 'ffmpeg -i ' + screenFile + ' -af "volume=enable=\'' + muteOpStr + '\':volume=0" -y ' + screenFileMuteExaminerMp4
    print("ffCmd:", ffCmd)

    subprocess.call(ffCmd, shell=True)
    #如果执行异常，退出
    if not os.path.isfile(screenFileMuteExaminerMp4):
        print("Error: screenFileMuteExaminerMp4 not exist")
        exit(0)

    #2. 用screenFileMuteExaminerMp4刷嘴canVideoFile，产生新的视频文件canVideoFileMouthed
    fakeCmd = "python ../../inference.py --checkpoint_path ../../wav2lip_gan.pth --face " + canVideoFile + " --audio " + screenFileMuteExaminerMp4 + " --nosmooth"
    print("fakeCmd:", fakeCmd)
    subprocess.call(fakeCmd, shell=True)

    #判断results/result_voice.mp4是否存在
    if not os.path.isfile('results/result_voice.mp4'):
        print("Error: results/result_voice.mp4 not exist")
        exit(0)
    #将results/result_voice.mp4重命名为canVideoFileMouthed
    canVideoFileMouthed = 'TEMPFILE-canVideoFileMouthed.mp4'
    os.rename('results/result_voice.mp4', canVideoFileMouthed)

    #3. 将canVideoFileMouthed和screenFile合并，产生新的视频文件finalVideo（screenFileWithNewCan）
    screenFileWithNewCan = 'NEW_CANDI-of-' + screenFile[:-4] + '.mp4'
    #ffmpeg -i record28b.mp4 -i female1m-head_record28b-noendaudio-swap-4-25-29-53-57s-2.mp4 -filter_complex "[0:v]scale=448:960[0v];[1:v]scale=208:260[1v];[0v][1v]overlay=13:121[outv]" -map "[outv]" -map 0:a -c:a copy -c:v libx264 -crf 23 -preset veryfast result.mp4
    ffCmd = 'ffmpeg -i ' + screenFile + ' -i ' + canVideoFileMouthed + ' -filter_complex "[0:v]scale=448:960[0v];[1:v]scale=208:259[1v];[0v][1v]overlay=13:122[outv]" -map "[outv]" -map 0:a -c:a copy -c:v libx264 -crf 23 -preset veryfast ' + screenFileWithNewCan
    print("ffCmd:", ffCmd)
    subprocess.call(ffCmd, shell=True)
    #check file exist
    if not os.path.isfile(screenFileWithNewCan):
        print("Error: screenFileWithNewCan not exist")
        exit(0)
    #remove temp files
    os.remove(screenFileMuteExaminerMp4)
    os.remove(canVideoFileMouthed)

    pass


def cut(srcVideo, startTime, endTime):
    #将startTime秒数换算为00:00:00格式
    startTime = int(startTime)
    startTimeStr = str(startTime // 3600).zfill(2) + ':' + str(startTime % 3600 // 60).zfill(2) + ':' + str(startTime % 60).zfill(2)
    #将endTime秒数换算为00:00:00格式
    endTime = int(endTime)
    endTimeStr = str(endTime // 3600).zfill(2) + ':' + str(endTime % 3600 // 60).zfill(2) + ':' + str(endTime % 60).zfill(2)
    #ffmpeg -i record28b.mp4 -ss 00:00:00 -to 00:00:10 -c copy -y record28b-0-10s.mp4
    ffCmd = 'ffmpeg -i ' + srcVideo + ' -ss ' + startTimeStr + ' -to ' + endTimeStr + ' -c copy -y ' + srcVideo[:-4] + '-' + str(startTime) + '-' + str(endTime) + 's.mp4'
    print("ffCmd:", ffCmd)
    subprocess.call(ffCmd, shell=True)


if __name__ == '__main__':
    if sys.argv[1] == 'gen':
        if len(sys.argv) < 5:
            print("Usage: python3 mktTopicMovies.py gen screen-record-file candidate-video-file swap-points")
            exit(0)
        gen(sys.argv[2], sys.argv[3], sys.argv[4])
    elif sys.argv[1] == 'cut':
        if len(sys.argv) < 5:
            print("Usage: python3 mktTopicMovies.py cut src-video start-time end-time")
            exit(0)
        cut(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        print("Usage: python3 mktTopicMovies.py [gen screen-record-file candidate-video-file swap-points | cut src-video start-time end-time]")
        exit(0)
