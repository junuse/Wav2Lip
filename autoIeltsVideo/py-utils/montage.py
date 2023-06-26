import random
from getCombinationsOfList import *

def getAllVideos():
    # Get all videos in the directory:../result/dialog
    videos = []
    for file in os.listdir():
        import re
        #按文件名正则匹配*sound3*.mp4
        if re.match(r'.*sound3.*\.mp4', file):
            videos.append(file)
    print(videos)
    return videos

def getAudioNamesFromVideos():
    # Get all audio names from videos
    videos = getAllVideos()
    audios = []
    for video in videos:
        #截取文件名中qna开头，.mp4之前的部分
        audio = video[video.find('qna'):video.find('.mp4')]
        audios.append(audio)
    #将audios去重
    audios = list(set(audios))
    print(audios)
    return audios

def getCandidateNamesFromVideos():
    # Get all Candidate names from videos
    videos = getAllVideos()
    candidates = []
    for video in videos:
        removeExaminerName = video[video.find('m') + 1:]
        candidate = removeExaminerName[removeExaminerName.find('can'):removeExaminerName.find('_qna')]
        candidates.append(candidate)
    candidates = list(set(candidates))
    print("candidates:", candidates, len(candidates))
    return candidates
def getExaminerName():
    return 'can-005-m'

def getAllAudioCominations(numOfItems, repetationTolerance):
    audios = getAudioNamesFromVideos()
    # audios = [1,2,3,4,5,6,7,8]
    combs = getCombinationsOfNumOfItemsBelowRepetationTolerance(audios, numOfItems, repetationTolerance)
    import random
    random.shuffle(combs)
    return combs

def montageCombinAudios(audios, examinerName, candidateName):
    print("montageCombinAudios:", audios, examinerName, candidateName)
    # montage audios
    import subprocess
    examPlusCan = examinerName + "_" + candidateName
    inputFile = "temp_montage_" + examPlusCan + ".txt"

    qnas = "_comb"
    with open(inputFile, 'w') as f:
        #清空文件内容
        f.truncate()
        for audio in audios:
            #追加写入文件内容
            f.write("file '" + examPlusCan + "_" + audio + ".mp4'\n")
            #获取qna-sound3-mf-qno8-swap-6中的qno8，返回qno8
            qno = audio[audio.find('qno') + 3:audio.find('-swap')]
            qnas += "-" + qno

        f.flush()
        f.close()

    cmd = 'ffmpeg -f concat -safe 0 -i ' + inputFile + ' -c copy -y montage/' + examPlusCan + qnas + '.mp4'
    subprocess.call(cmd, shell=True)
    os.remove(inputFile)


#设置当前工作目录为脚本目录
os.chdir(os.path.split(os.path.realpath(__file__))[0])
#切换工作目录到../result/dialog
os.chdir('../result/dialog')

allAudioCombins = getAllAudioCominations(4, 3)
print("allAudioCombins:", allAudioCombins, len(allAudioCombins))

reference = getCombinationsOfNumOfItemsBelowRepetationTolerance([1,2,3,4,5,6,7,8], 4, 2)
print("reference:", reference, len(reference))


numOfCombsForOneCan = 6
for can in getCandidateNamesFromVideos()[:10]:
    #将allAudioCombins随机排序
    random.shuffle(allAudioCombins)
    mySelectedCombs = []
    tries = 0
    #遍历allAudioCombins前6个
    unwishedCombs = []
    while len(mySelectedCombs) < numOfCombsForOneCan and ++tries < len(allAudioCombins):
        #从allAudioCombins中随机取一个组合
        oneComb = allAudioCombins.pop()
        #从oneComb中找到一个元素，这个元素与mySelectedCombs中所有元素的首元素都不重复
        noRepeatedHead = None
        for audio in oneComb:
            if audio not in [comb[0] for comb in mySelectedCombs]:
                noRepeatedHead = audio
                break
        if noRepeatedHead is None:
            #放回allAudioCombins,重新取一个组合
            unwishedCombs.append(oneComb)
            print("unwishedCombs:", unwishedCombs)
            continue
        #将noRepeatedHead放到oneComb的首位
        oneComb.remove(noRepeatedHead)
        oneComb.insert(0, noRepeatedHead)
        mySelectedCombs.append(oneComb)
        montageCombinAudios(oneComb, getExaminerName(), can)
    if len(mySelectedCombs) < numOfCombsForOneCan:
        raise Exception("select enough combs for can ", can," failed: mySelectedCombs: ", len(mySelectedCombs),
                        " rest of allAudioCombins: ", len(allAudioCombins))
    #将unwishedCombs放回allAudioCombins
    allAudioCombins.extend(unwishedCombs)
