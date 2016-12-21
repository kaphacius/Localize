#!/usr/bin/swift

import Foundation

func parseForPlatformName(input: String) -> [String] {
    return input.components(separatedBy: ",").map { $0.replacingOccurrences(of: " ", with: "") }
}

dump(CommandLine.arguments)
let platform = CommandLine.arguments[1]
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
    if platform.uppercased().contains("ANDROID") {
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
            var comment: String = ""
            if platform.uppercased().contains("ANDROID") {
                let commentForAndroid = key.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                comment = "    <!-- \(commentForAndroid) -->"
            } else if platform.uppercased().contains("IOS") {
                comment = key
            }
            langs[langIndex].append(comment)
        } else if line[i] != "" && (forPlatform.contains(platform)) {
            var localization: String = ""
            if platform.uppercased().contains("ANDROID") && key.hasPrefix("google_play_") {
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
            } else {
                let escaped = line[i].replacingOccurrences(of: "\"", with: "\\\"")
                if platform.uppercased().contains("ANDROID") {
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
                } else if platform.uppercased().contains("IOS") {
                    localization = "\"\(key)\" = \"\(escaped)\";"
                }
                langs[langIndex].append(localization)
            }
        }
    }
}

if platform.uppercased().contains("ANDROID") {
    for i in 0..<langs.count {
        langs[i].insert("</resources>", at:langs[i].count)
    }
}

//Save results
if let dirPath = path.deletingLastPathComponent?.appendingPathComponent("Result_\(platform)") {
    try! FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
    for i in 0..<firstRow.count {
        var dirName: String = firstRow[i]
        if platform.uppercased().contains("ANDROID") {
            dirName = "values-\(firstRow[i])"
        } else if platform.uppercased().contains("IOS") {
            dirName = "\(firstRow[i]).lproj"
        }
        let currentDirPath = dirPath.appendingPathComponent(dirName, isDirectory: true)
        try! FileManager.default.createDirectory(at: currentDirPath, withIntermediateDirectories: true, attributes: nil)
        let result = langs[i].reduce("") { $0 + $1 + "\n" }

        var fileName: String = "strings.txt"
        if platform.uppercased().contains("ANDROID") {
            fileName = "strings.xml"
        } else if platform.uppercased().contains("IOS") {
            fileName = "Localizable.strings"
        }
        let currentFilePath = currentDirPath.appendingPathComponent(fileName)
        try! result.data(using: String.Encoding.utf8)?.write(to: currentFilePath, options: [])

        print(currentFilePath)
    }
}
