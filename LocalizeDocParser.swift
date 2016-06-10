#!/usr/bin/swift

import Foundation

enum Platform {
    case Android, iOS
}

func parsePlatformName(input: String) -> Platform? {
    let platform: Platform?
    switch input {
    case "android":
        platform = .Android
    case "ios":
        platform = .iOS
    default:
        platform = nil
    }
    return platform
}

//Parse google doc
dump(Process.arguments)
let platformP = Process.arguments[1]
let platform = parsePlatformName(platformP) ?? .iOS
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
firstRow.removeFirst() // "PLATFORM"
firstRow.removeFirst() // "KEY"
for lang in firstRow {
    var translations = [String]()
    if platform == .Android {
        translations.append("<!--")
        translations.append("  This file was automatically generated from Google Docs")
        translations.append("  It should not be modified here, update Google Docs instead.")
        translations.append("-->")
        translations.append("<resources>")
    }
    langs.append(translations)
}

//Split by language
for line in splitted {
    let forPlatform = parsePlatformName(line[0])
    let key = line[1]
    for i in 2..<line.count {
        let langIndex = i - 2
        if key.hasPrefix("//") {
            let comment: String
            switch platform {
            case .Android:
                let commentForAndroid = key.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "/"))
                comment = "    <!-- \(commentForAndroid) -->"
            case .iOS:
                comment = key
            }
            langs[langIndex].append(comment)
        } else if line[i] != "" && (forPlatform == nil || forPlatform! == platform) {
            let localization: String
            if platform == .Android && key.hasPrefix("google_play_") {
                let fileName = key.stringByReplacingOccurrencesOfString("google_play_", withString: "")
                let langCode = firstRow[langIndex]
                let regionCode: String?
                switch langCode {
                    case "en": regionCode = "GB"
                    case "nl": regionCode = "NL"
                    case "de": regionCode = "DE"
                    case "fr": regionCode = "FR"
                    default: regionCode = nil
                }
                
                if let rc = regionCode {
                    let dirPath = path.URLByDeletingLastPathComponent?
                        .URLByAppendingPathComponent("fastlane")
                        .URLByAppendingPathComponent("metadata")
                        .URLByAppendingPathComponent("android")
                        .URLByAppendingPathComponent(langCode + "-" + rc)
                    try! NSFileManager.defaultManager().createDirectoryAtURL(dirPath!, withIntermediateDirectories: true, attributes: nil)
                    let currentFilePath = dirPath!.URLByAppendingPathComponent(fileName + ".txt")
                    let value = line[i].stringByReplacingOccurrencesOfString("\\n", withString: "\n")
                    value.dataUsingEncoding(NSUTF8StringEncoding)?.writeToURL(currentFilePath, atomically: true)
                    print(currentFilePath)
                }
            } else {
                switch platform {
                case .Android:
                    let keyForAndroid = String(key.characters.map {
                        $0 == " " ? "_" : $0
                        }).lowercaseString
                    
                    var valueForAndroid = line[i]
                        .stringByReplacingOccurrencesOfString("&", withString: "&amp;")
                        .stringByReplacingOccurrencesOfString("'", withString: "\\'")
                    
                    var i = 1
                    let placeholderForIOS = "%@"
                    while valueForAndroid.containsString(placeholderForIOS) {
                        valueForAndroid = valueForAndroid
                            .stringByReplacingOccurrencesOfString(placeholderForIOS, withString: "%\(i)$s", range: valueForAndroid.rangeOfString(placeholderForIOS))
                        i += 1
                    }
                    
                    localization = "    <string name=\"\(keyForAndroid)\">\(valueForAndroid)</string>"
                case .iOS:
                    localization = "\"\(key)\" = \"\(line[i])\";"
                }
                langs[langIndex].append(localization)
            }
        }
    }
}

if platform == .Android {
    for i in 0..<langs.count {
        langs[i].insert("</resources>", atIndex:langs[i].count)
    }
}

//Save results
if let dirPath = path.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("Result_\(platform)") {
    try! NSFileManager.defaultManager().createDirectoryAtURL(dirPath, withIntermediateDirectories: true, attributes: nil)
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
