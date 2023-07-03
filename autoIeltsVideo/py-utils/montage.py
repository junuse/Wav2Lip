import random
from getCombinationsOfList import *

def getAllVideos():
    # Get all videos in the directory:../result/dialog
    videos = []
    for file in os.listdir():
        import re
        #按文件名正则匹配*sound3*.mp4
        if re.match(r'.*'+soundId+'.*\.mp4', file):
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
        # #如果candidate不包含103 104
        # if candidate.find('013') == -1 \
        #     and candidate.find('103') == -1 and candidate.find('104') == -1 \
        #     and candidate.find('105') == -1 and candidate.find('111') == -1 \
        #     and candidate.find('112') == -1:
        candidates.append(candidate)
    candidates = list(set(candidates))
    print("candidates:", candidates, len(candidates))
    return candidates
def getExaminerName():
    return 'exam-001-m'

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

    qnas = "_" + soundId
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

########################################################
soundId='sound5'
numOfCandidates = 8
numOfCombsForOneCan = 4
numOfCombinationItems = 2
repetationTolerance = 1
########################################################

#设置当前工作目录为脚本目录
os.chdir(os.path.split(os.path.realpath(__file__))[0])
#切换工作目录到../result/dialog
os.chdir('../result/dialog')

allAudioCombins = getAllAudioCominations(numOfCombinationItems, repetationTolerance)
print("allAudioCombins:", allAudioCombins, len(allAudioCombins))

reference = getCombinationsOfNumOfItemsBelowRepetationTolerance([1,2,3,4,5,6,7,8], numOfCombinationItems, repetationTolerance)
print("reference:", reference, len(reference))
# exit(0)
for can in getCandidateNamesFromVideos()[:numOfCandidates]:
    #将allAudioCombins随机排序
    random.shuffle(allAudioCombins)
    mySelectedCombs = []
    tries = 0
    #遍历allAudioCombins前6个
    unwishedCombs = []
    while len(mySelectedCombs) < numOfCombsForOneCan and ++tries < len(allAudioCombins):
        #从allAudioCombins中随机取一个组合
        oneComb = allAudioCombins.pop()

        # 方式1：排列的顺序随机，任一个元素都可以放到首位，以满足首元素不重复
        # #从oneComb中找到一个元素，这个元素与mySelectedCombs中所有元素的首元素都不重复
        # noRepeatedHead = None
        #
        # for audio in oneComb:
        #     if audio not in [comb[0] for comb in mySelectedCombs]:
        #         noRepeatedHead = audio
        #         break
        # if noRepeatedHead is None:
        #     #放回allAudioCombins,重新取一个组合
        #     unwishedCombs.append(oneComb)
        #     print("unwishedCombs:", unwishedCombs)
        #     continue
        #
        # #将noRepeatedHead放到oneComb的首位
        # oneComb.remove(noRepeatedHead)
        # oneComb.insert(0, noRepeatedHead)
        # # 将noRepeatedHead放到oneComb的首位
        # oneComb.remove(noRepeatedHead)
        # oneComb.insert(0, noRepeatedHead)

        # 方式2：不改动排列的顺序
        # 从oneComb中找到一个元素，这个元素与mySelectedCombs中所有元素的首元素都不重复
        noRepeatedHead = None
        if oneComb[0] in [comb[0] for comb in mySelectedCombs]:
            # 放回allAudioCombins,重新取一个组合
            unwishedCombs.append(oneComb)
            print("unwishedCombs:", unwishedCombs)
            continue


        mySelectedCombs.append(oneComb)
        montageCombinAudios(oneComb, getExaminerName(), can)
    if len(mySelectedCombs) < numOfCombsForOneCan:
        raise Exception("select enough combs for can ", can," failed: mySelectedCombs: ", len(mySelectedCombs),
                        " rest of allAudioCombins: ", len(allAudioCombins))
    #将unwishedCombs放回allAudioCombins
    allAudioCombins.extend(unwishedCombs)
