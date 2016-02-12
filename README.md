# Localize
Scripts for handling Localizable.strings via Google docs

## How to use

### Uploading from iOS to GoogleDocs:


1. ```chmod +x StringsParser.swift```


2. ```./StringsParser.swift [path to Localizable.strings containing all of the keys]```


3. The resuling ```strings_parsed.tsv``` will be located in the script folder


4. Google Spreadsheets: File -> Import -> Upload -> strings_parsed.tsv


5. Do the translation

### Adding the result to your project:


1. Google Spreadsheets: File -> Download as -> ```tsv```


2. ```chmod +x LocalizeDocParser.swift```


3. ```./LocalizeDocParser.swift [platform: android or ios] [path to exported tsv file]```


4. The resulting ```*.xml```(android) or ```*.lproj```(iOS) will be located in the script folder: ```Result_[platform]```


5. Paste and replace to your project folder
