// : Playground - noun: a place where people can play

import Foundation

extension String {
    typealias Char = String
    var length: Int {
        return characters.count
    }

    func regexMatch(regex: String) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: .CaseInsensitive)
            return exp.matchesInString(self, options: .Anchored, range: NSMakeRange(0, length)).count > 0
        } catch _ {
            return false
        }
    }

    func isSimilar(other: String?) -> Bool {
        var similar = false
        if let otr = other {
            let ls = (self.length >= otr.length ? self : otr).stringByReplacingOccurrencesOfString(" ", withString: "")
            let ss = (self.length < otr.length ? self : otr).stringByReplacingOccurrencesOfString(" ", withString: "")

            if ls.containsString(ss) {
                similar = true
            } else {
            }
        }

        return similar
    }

    func array() -> [Char] {
        return self.characters.map { String($0) }
    }

    func similarity(another: String) -> (Int, Float) {
        let str1 = self.array()
        let str2 = another.array()
        var dif: [[Int]] = []

        for i in 0 ... str1.count {
            var inner: [Int] = []

            for j in 0 ... str2.count {
                inner.append(i == 0 ? j : j == 0 ? i : 0)
            }

            dif.append(inner)
        }

        var temp = 0
        for i in 1 ..< dif.count {
            for j in 1 ..< dif[i].count {
                temp = str1[i - 1] == str2[j - 1] ? 0 : 1
                let m1 = min(dif[i - 1][j - 1] + temp, dif[i][j - 1] + 1)
                dif[i][j] = min(m1, dif[i - 1][j] + 1)
            }
        }

        let dis = dif[str1.count][str2.count]
        let sim = (1.0 - Float(dis) / Float(max(str1.count, str2.count)))

        return (dis, sim)
    }
}

let chapter = "第五卷第神来之笔第二十九章红薯易冷"

let r = chapter.rangeOfString("第二十九章")

/*print(r)

print(chapter.substringFromIndex(r!.endIndex))

print(chapter.substringToIndex(r!.startIndex))*/

func asyncTask<T>(backgroudTask: () -> T) -> (onMain: (result: T) -> Void) -> Void {
    return { (mainTask: (res: T) -> Void) in
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let result = backgroudTask()
            dispatch_async(dispatch_get_main_queue()) {
                mainTask(res: result)
            }
        }
    }
}

asyncTask { () -> Int in
    print("abc")
	return 1 + 2
}(onMain: { res in
    //print(res)
})

