#!/usr/bin/swift

import Foundation

enum Platform {
    case Android, iOS
}

func parseOutputPlatformName(input: String) -> Platform? {
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

func parseForPlatformName(input: String) -> [Platform] {
    let platform: [Platform]
    switch input {
    case "android":
        platform = [.Android]
    case "ios":
        platform = [.iOS]
    case "not used":
        platform = []
    default:
        platform = [.Android, .iOS]
    }
    return platform
}

dump(CommandLine.arguments)
let platformP = CommandLine.arguments[1]
let platform = parseOutputPlatformName(input: platformP) ?? .iOS
let fileP = CommandLine.arguments[2]
let path = NSURL(fileURLWithPath: fileP)
let data = NSData(contentsOf: path as URL)
let strings = String(data: data! as Data, encoding: String.Encoding.utf8)
let lines = strings!.components(separatedBy: "\n")
var splitted = lines.map { (string: String) -> [String] in
    return string.trimmingCharacters(in: CharacterSet.newlines).components(separatedBy: "\t")
}

var firstRow = splitted.removeFirst()
firstRow.removeFirst() // "PLATFORM"
firstRow.removeFirst() // "KEY"

//Split by language
for line in splitted {
    let forPlatform = parseForPlatformName(input: line[0])
    let key = line[1]
    for i in 2..<line.count {
        let langIndex = i - 2
        if key.hasPrefix("//") {
            //Ignore
        } else if line[i] != "" && (forPlatform.contains(platform)) {
            let fileName = key.replacingOccurrences(of: "google_play_", with: "")
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
                let dirPath = path.deletingLastPathComponent?
                    .appendingPathComponent("fastlane")
                    .appendingPathComponent("metadata")
                    .appendingPathComponent("android")
                    .appendingPathComponent(langCode + "-" + rc)
                try! FileManager.default.createDirectory(at: dirPath!, withIntermediateDirectories: true, attributes: nil)
                let currentFilePath = dirPath!.appendingPathComponent(fileName + ".txt")
                let value = line[i].replacingOccurrences(of: "\\n", with: "\n")
                try! value.data(using: String.Encoding.utf8)?.write(to: currentFilePath, options: [])
                print(currentFilePath)
            }

        }
    }
}
