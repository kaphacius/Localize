#!/usr/bin/swift

import Foundation

enum Platform {
    case Android, iOS
}

//Parse google doc
dump(Process.arguments)
let platformP = Process.arguments[1]
let platform: Platform
switch platformP {
case "android":
    platform = .Android
case "ios":
    platform = .iOS
default:
    platform = .iOS
}
let fileP = Process.arguments[2]
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

//Split by language
for line in splitted {
    let key = line[0]
    for i in 1..<line.count {
        if key.hasPrefix("//") {
            langs[i - 1].append(key)
        } else if line[i] != "" {
            let localization: String
            switch platform {
            case .Android:
                let keyForAndroid = String(key.characters.map {
                    $0 == " " ? "_" : $0
                    }).lowercaseString
                localization = "<string name=\"\(keyForAndroid)\">\(line[i])</string>"
            case .iOS:
                localization = "\"\(key)\" = \"\(line[i])\";"
            }
            langs[i - 1].append(localization)
        }
    }
}

//Save results
if let dirPath = path.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("Result_\(platform)") {
    try! NSFileManager.defaultManager().createDirectoryAtURL(dirPath,
        withIntermediateDirectories: true,
        attributes: nil)
    for i in 0..<firstRow.count {
        let dirName: String
        switch platform {
        case .Android:
            dirName = "values-\(firstRow[i])"
        case .iOS:
            dirName = "\(firstRow[i]).lproj"
        }
        let currentDirPath = dirPath.URLByAppendingPathComponent(dirName, isDirectory: true)
        try! NSFileManager.defaultManager().createDirectoryAtURL(currentDirPath, withIntermediateDirectories: true, attributes: nil)
        let result = langs[i].reduce("") { $0 + $1 + "\n" }
        
        let fileName: String
        switch platform {
        case .Android:
            fileName = "strings.xml"
        case .iOS:
            fileName = "Localizable.strings"
        }
        let currentFilePath = currentDirPath.URLByAppendingPathComponent(fileName)
        result.dataUsingEncoding(NSUTF8StringEncoding)?.writeToURL(currentFilePath, atomically: true)
        
        print(currentFilePath)
    }
}