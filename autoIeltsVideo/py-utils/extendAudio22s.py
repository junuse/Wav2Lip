
#将input.mp3的音频长度延长到22s的倍数
import os
import sys



def extendAudio22s(inputPath, outputPath):
    # 1. ffmpeg获取音频长度
    import subprocess
    command = 'ffprobe -i '+ inputPath + ' -show_entries format=duration -v quiet -of csv="p=0"'
    length = subprocess.check_output(command, shell=True)
    print("length:", length)
    # 2. 将length对22取余
    length = float(length)
    remainder = length % 22
    print("remainder:", remainder)
    # 3. 计算需要延长的长度
    extendLength = 22 - remainder
    print("extendLength:", extendLength)
    # 4. ffmpeg将input.mp3延长extendLength
    command = 'ffmpeg -i ' + inputPath + ' -af apad=pad_dur=' + str(extendLength) + ' ' + outputPath
    subprocess.call(command, shell=True)
    # 5. ffmpeg获取output.mp3的音频长度
    command = 'ffmpeg -i ' + outputPath + ' 2>&1 | grep Duration | cut -d \' \' -f 4 | sed s/,//'
    length = subprocess.check_output(command, shell=True)
    print("length:", length)



#获取当前路径
currentPath = os.getcwd()
#循环处理当前路径下所有mp3文件，调用extendAudio22s
for root, dirs, files in os.walk(currentPath):
    for file in files:
        if file.endswith('.mp3'):
            inputPath = os.path.join(root, file)
            outputPath = os.path.join(root, 'extended_' + file)
            extendAudio22s(inputPath, outputPath)
            # exit(0)
            


