#!/usr/bin/swift

import Foundation

dump(Process.arguments)
let fileP = Process.arguments[1]
let path = NSURL(fileURLWithPath: fileP)
let url = NSURL(fileURLWithPath: fileP)
let original = url.URLByDeletingLastPathComponent!.URLByDeletingPathExtension!.lastPathComponent!
let dirPath = url.URLByDeletingLastPathComponent!.URLByDeletingLastPathComponent!
let contents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(dirPath, includingPropertiesForKeys: nil, options: [.SkipsSubdirectoryDescendants, .SkipsHiddenFiles])
var filtered = contents.filter { url in
    url.lastPathComponent!.hasSuffix("lproj")
    }.map { projUrl in
        projUrl.URLByAppendingPathComponent("Localizable.strings")
}
let langs = filtered.map { $0.URLByDeletingLastPathComponent!.lastPathComponent!.componentsSeparatedByString(".").first! }
print("Detected languages:\(langs)")
print("Original language:\(original)")

// [key: [lang: value]]
var result = [String: [String: String]]()
var keys = [String]()

//Do original language
let data = NSData(contentsOfURL: path)
let strings = String(data: data!, encoding: NSUTF8StringEncoding)
let lines = strings!.componentsSeparatedByString("\n")
let re = try! NSRegularExpression(pattern: "^\"(.*?)\"|(\\/{2}.*)", options: .CaseInsensitive)
for line in lines {
    if line.hasPrefix("//") {
        result[line] = Dictionary<String, String>()
        keys.append(line)
    } else if let extr = re.firstMatchInString(line, options: .ReportProgress, range: NSMakeRange(0, line.characters.count)) {
        let range = Range(start: line.startIndex, end: line.startIndex.advancedBy(extr.range.length))
        let key = line.substringWithRange(range).stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\""))
        result[key] = Dictionary<String, String>()
        var value = line.substringFromIndex(range.endIndex.advancedBy(4))
        value = value.substringToIndex(value.endIndex.advancedBy(-2))
        result[key]![original] = value
        keys.append(key)
    }
}

//Do rest
var otherLangs = langs
//print(filtered.count)
print("Original index: \(otherLangs.indexOf(original))")
print(filtered)
filtered.removeAtIndex(otherLangs.indexOf(original)!)
print(filtered)
otherLangs.removeAtIndex(otherLangs.indexOf(original)!)
print(otherLangs)
var otherLangStrings = [String: String]()
for i in 0..<otherLangs.count {
    otherLangStrings[otherLangs[i]] = String(data: NSData(contentsOfURL: filtered[i])!, encoding: NSUTF8StringEncoding)
}

for ol in otherLangs {
    let lines = otherLangStrings[ol]!.componentsSeparatedByString("\n")
    let re = try! NSRegularExpression(pattern: "^\"(.*?)\"|(\\/{2}.*)", options: .CaseInsensitive)
    for line in lines {
        if line.hasPrefix("//") {
            continue
        } else if let extr = re.firstMatchInString(line, options: .ReportProgress, range: NSMakeRange(0, line.characters.count)) {
            let range = Range(start: line.startIndex, end: line.startIndex.advancedBy(extr.range.length))
            let key = line.substringWithRange(range).stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\""))
            var value = line.substringFromIndex(range.endIndex.advancedBy(4))
            value = value.substringToIndex(value.endIndex.advancedBy(-2))
            result[key]![ol] = value
        }
    }
}

var resultString = langs.reduce("key") { $0 + "\t" + $1}
resultString += "\n"

//Create result
for key in keys {
    if key.hasPrefix("//") {
        resultString += "\(key)\n"
    } else {
        resultString += "\(key)\t"
        for lang in langs {
            let value = result[key]?[lang] ?? ""
            resultString += "\(value)\t"
        }
        resultString += "\n"
    }
}

//Save result
let resPath = NSURL(fileURLWithPath: NSFileManager.defaultManager().currentDirectoryPath).URLByAppendingPathComponent("strings_extracted.tsv")
dump(resultString.dataUsingEncoding(NSUTF8StringEncoding)?.writeToURL(resPath, atomically: true))
