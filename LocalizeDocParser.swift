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

var langs = [[String]]()
var firstRow = splitted.removeFirst()
firstRow.removeFirst() // "PLATFORM"
firstRow.removeFirst() // "KEY"
for _ in firstRow {
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
    let forPlatform = parseForPlatformName(input: line[0])
    let key = line[1]
    for i in 2..<line.count {
        let langIndex = i - 2
        if key.hasPrefix("//") {
            let comment: String
            switch platform {
            case .Android:
                let commentForAndroid = key.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                comment = "    <!-- \(commentForAndroid) -->"
            case .iOS:
                comment = key
            }
            langs[langIndex].append(comment)
        } else if line[i] != "" && (forPlatform.contains(platform)) {
            let localization: String
            let escaped = line[i].replacingOccurrences(of: "\"", with: "\\\"")
            switch platform {
            case .Android:
                let keyForAndroid = String(key.characters.map {
                    $0 == " " ? "_" : $0
                }).lowercased()
                
                var valueForAndroid = escaped
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "'", with: "\\'")
                var i = 1
                let placeholderForIOS = "%@"
                while valueForAndroid.contains(placeholderForIOS) {
                    valueForAndroid = valueForAndroid
                        .replacingOccurrences(of: placeholderForIOS, with: "%\(i)$s", range: valueForAndroid.range(of: placeholderForIOS))
                    i += 1
                }
                
                localization = "    <string name=\"\(keyForAndroid)\">\(valueForAndroid)</string>"
            case .iOS:
                localization = "\"\(key)\" = \"\(escaped)\";"
            }
            langs[langIndex].append(localization)
        }
    }
}

if platform == .Android {
    for i in 0..<langs.count {
        langs[i].insert("</resources>", at:langs[i].count)
    }
}

//Save results
if let dirPath = path.deletingLastPathComponent?.appendingPathComponent("Result_\(platform)") {
    try! FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
    for i in 0..<firstRow.count {
        let dirName: String
        switch platform {
        case .Android:
            dirName = "values-\(firstRow[i])"
        case .iOS:
            dirName = "\(firstRow[i]).lproj"
        }
        let currentDirPath = dirPath.appendingPathComponent(dirName, isDirectory: true)
        try! FileManager.default.createDirectory(at: currentDirPath, withIntermediateDirectories: true, attributes: nil)
        let result = langs[i].reduce("") { $0 + $1 + "\n" }

        let fileName: String
        switch platform {
        case .Android:
            fileName = "strings.xml"
        case .iOS:
            fileName = "Localizable.strings"
        }
        let currentFilePath = currentDirPath.appendingPathComponent(fileName)
        try! result.data(using: String.Encoding.utf8)?.write(to: currentFilePath, options: [])

        print(currentFilePath)
    }
}
