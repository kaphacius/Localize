#!/usr/bin/swift

import Foundation

dump(Process.arguments)
let fileP = Process.arguments[1]
let path = NSURL(fileURLWithPath: fileP)
let data = NSData(contentsOfURL: path)
let strings = String(data: data!, encoding: NSUTF8StringEncoding)
let lines = strings!.componentsSeparatedByString("\n")
var extracted = [String]()
//let re = try! NSRegularExpression(pattern: "^\"(.*?)\"|(\\/{2}.*)", options: .CaseInsensitive)
//for line in lines {
//    if let extr = re.firstMatchInString(line, options: .ReportProgress, range: NSMakeRange(0, line.characters.count)) {
//        let range = Range(start: line.startIndex, end: line.startIndex.advancedBy(extr.range.length))
//        extracted.append(line.substringWithRange(range).stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\"")))
//    }
//}
for line in lines {
    if line.hasPrefix("//") {
        extracted.append(String())
    } else if let i = line.rangeOfString("\" = \"") {
        let toAppend = line.substringFromIndex(i.endIndex)
        extracted.append(toAppend.substringToIndex(toAppend.endIndex.advancedBy(-2)))
    }
}
let res = extracted.reduce("") { $0 + $1 + "\n"}
let resPath = path.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("values_extracted.strings")
dump(res.dataUsingEncoding(NSUTF8StringEncoding)?.writeToURL(resPath!, atomically: true))
