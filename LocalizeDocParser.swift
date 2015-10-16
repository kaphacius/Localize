#!/usr/bin/swift

import Foundation

dump(Process.arguments)
let fileP = Process.arguments[1]
let path = NSURL(fileURLWithPath: fileP)
let data = NSData(contentsOfURL: path)
let strings = String(data: data!, encoding: NSUTF8StringEncoding)
let lines = strings!.componentsSeparatedByString("\n")
var splitted = lines.map { (string: String) -> [String] in
    return string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()).componentsSeparatedByString("\t")
}
var langs = [[String]]()
var firstRow = splitted.removeFirst()
firstRow.removeFirst()
for lang in firstRow {
    langs.append([String]())
}
for line in splitted {
    let key = line[0]
    for i in 1..<line.count {
        if key.hasPrefix("//") {
            langs[i - 1].append(key)
        } else if line[i] != "" {
            langs[i - 1].append("\"\(key)\" = \"\(line[i])\";")
        }
    }
}

if let dirPath = path.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("Result") {
    try? NSFileManager.defaultManager().createDirectoryAtURL(dirPath,
        withIntermediateDirectories: false,
        attributes: nil)
    for i in 0..<firstRow.count {
        let currentDirPath = dirPath.URLByAppendingPathComponent("\(firstRow[i]).lproj", isDirectory: true)
        try? NSFileManager.defaultManager().createDirectoryAtURL(currentDirPath, withIntermediateDirectories: true, attributes: nil)
        let result = langs[i].reduce("") { $0 + $1 + "\n" }
        let currentFilePath = currentDirPath.URLByAppendingPathComponent("Localizable.strings")
        result.dataUsingEncoding(NSUTF8StringEncoding)?.writeToURL(currentFilePath, atomically: true)
    }
}



