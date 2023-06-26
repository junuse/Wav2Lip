import os

def get_file_path(file_name):
    return os.path.join(os.path.dirname(__file__), file_name)

# def get_file_path_from_root(file_name):
#     return os.path.join(os.path.dirname(os.path.dirname(__file__)), file_name)

def pickRandomItemFromList(allItems, hasPickedItems, satiCombs, repetationTolerance):
    import random
    #inputList去掉hasPickedItems中的元素
    pickableItems = [item for item in allItems if item not in hasPickedItems]
    pickedItem = random.choice(pickableItems)
    # if pickedItem in hasPickedItems:
    #     return None
    # if pickedItem in satiCombs:
    #     if repetationTolerance == 0:
    #         return None
    #     else:
    #         repetationTolerance -= 1
    return pickedItem

getAllCombinations = lambda items: [[items[i] for i in range(len(items)) if (j & (1 << i))] for j in range(1 << len(items))]
getAllCombinationsOfNumOfItems = lambda items, numOfItems: [comb for comb in getAllCombinations(items) if len(comb) == numOfItems]



def getSatisfiedCombinations(outCombinationNum, repetationTolerance, inputList):
    satiCombs = []
    while True:
        newComb = []
        for i in range(outCombinationNum):
            if i < repetationTolerance:
                pickedItem = pickRandomItemFromList(inputList, newComb, satiCombs, repetationTolerance)
            else:
                #get all cominations in satiCombs which includes items in newComb
                selectedCombs = [comb for comb in satiCombs if all(item in comb for item in newComb)]
                #get all items in selectedCombs, no repetation
                selectedItems = list(set([item for comb in selectedCombs for item in comb]))
                #get all items in selectedItems or in newComb
                allSelectedItems = list(set(selectedItems + newComb))
                if len(allSelectedItems) == len(inputList):
                    break
                pickedItem = pickRandomItemFromList(inputList, allSelectedItems, satiCombs, 0)
            if pickedItem == None:
                break
            newComb.append(pickedItem)
        if len(newComb) < outCombinationNum:
            break
        satiCombs.append(newComb)
    return satiCombs


def getCombinationsOfNumOfItemsBelowRepetationTolerance(items, combNums, repetationTolerance):
    allCombs = getAllCombinationsOfNumOfItems(items, combNums)
    # print("allCombs:", allCombs, len(allCombs))
    satiCombs = []
    for comb in allCombs:
        # 检查comb与satiCombs中的组合是否有repetationTolerance个以上的重复元素
        # 如果有，就不加入satiCombs
        # 如果没有，就加入satiCombs
        # 如果satiCombs为空，就直接加入satiCombs
        if len(satiCombs) == 0:
            satiCombs.append(comb)
        else:
            tolerable = True
            for satiComb in satiCombs:
                repetationNum = 0
                for item in comb:
                    if item in satiComb:
                        repetationNum += 1
                if repetationNum > repetationTolerance:
                    tolerable = False
                    break
            if tolerable:
                satiCombs.append(comb)
    return satiCombs

def main():
    #获取入参
    import sys
    args = sys.argv
    if len(args) < 4:
        print("")
    else:
        numOfItems = int(args[1])
        repetationTolerance = int(args[2])
        itemList = args[3:]

        satiCombs = getCombinationsOfNumOfItemsBelowRepetationTolerance(itemList, numOfItems, repetationTolerance)
        # print(satiCombs, len(satiCombs))
        #将satiCombs展开并放到同一个列表中
        satiCombs = [item for comb in satiCombs for item in comb]
        print(satiCombs)