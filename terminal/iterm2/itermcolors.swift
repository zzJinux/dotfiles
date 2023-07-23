#!/usr/bin/swift
import AppKit

// first argument: color config json
// stdout: .itermcolors result

class StdoutStream: OutputStream {
    static var shared = StdoutStream()
    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        FileHandle.standardOutput.write(Data(bytes: buffer, count: len))
        return len
    }
}

let colorFieldMap = [
    "black": "Ansi 0 Color",
    "red": "Ansi 1 Color",
    "green": "Ansi 2 Color",
    "yellow": "Ansi 3 Color",
    "blue": "Ansi 4 Color",
    "magenta": "Ansi 5 Color",
    "cyan": "Ansi 6 Color",
    "white": "Ansi 7 Color",
    "brightBlack": "Ansi 8 Color",
    "brightRed": "Ansi 9 Color",
    "brightGreen": "Ansi 10 Color",
    "brightYellow": "Ansi 11 Color",
    "brightBlue": "Ansi 12 Color",
    "brightMagenta": "Ansi 13 Color",
    "brightCyan": "Ansi 14 Color",
    "brightWhite": "Ansi 15 Color",
    "background": "Background Color",
    "foreground": "Foreground Color",
    "cursor": "Cursor Color",
    "cursorText": "Cursor Text Color",
    "bold": "Bold Color",
    "selection": "Selection Color",
    "selectedText": "Selected Text Color",
]

let colorConfig = try! JSONSerialization.jsonObject(
    with: FileManager.default.contents(atPath: CommandLine.arguments.dropFirst().first!)!,
    options: []) as! [String: String]
    
var colorProfile: [String:[String:Any]] = [:]

for (from, to) in colorFieldMap {
    let color = UInt32(colorConfig[from]!.dropFirst(1), radix: 16)!
    let red = CGFloat((color >> 16) & 0xFF) / 255.0
    let green = CGFloat((color >> 8) & 0xFF) / 255.0
    let blue = CGFloat(color & 0xFF) / 255.0
    colorProfile[to] = [
        "Color Space": "sRGB",
        "Red Component": red,
        "Green Component": green,
        "Blue Component": blue,
    ]
}

PropertyListSerialization.writePropertyList(colorProfile, to: StdoutStream.shared, format: .xml, options: 0, error: nil)