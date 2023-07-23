#!/usr/bin/swift
import AppKit

// stdin: Apple Terminal config template
// first argument: color config json
// stdout: Apple Terminal config result

class StdoutStream: OutputStream {
    static var shared = StdoutStream()
    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        FileHandle.standardOutput.write(Data(bytes: buffer, count: len))
        return len
    }
}

let colorFieldMap = [
    "black": "ANSIBlackColor",
    "red": "ANSIRedColor",
    "green": "ANSIGreenColor",
    "yellow": "ANSIYellowColor",
    "blue": "ANSIBlueColor",
    "magenta": "ANSIMagentaColor",
    "cyan": "ANSICyanColor",
    "white": "ANSIWhiteColor",
    "brightBlack": "ANSIBrightBlackColor",
    "brightRed": "ANSIBrightRedColor",
    "brightGreen": "ANSIBrightGreenColor",
    "brightYellow": "ANSIBrightYellowColor",
    "brightBlue": "ANSIBrightBlueColor",
    "brightMagenta": "ANSIBrightMagentaColor",
    "brightCyan": "ANSIBrightCyanColor",
    "brightWhite": "ANSIBrightWhiteColor",
    "background": "BackgroundColor",
    "foreground": "TextColor",
    "bold": "TextBoldColor",
    "cursor": "CursorColor",
    "selection": "SelectionColor",
]

let colorConfig = try! JSONSerialization.jsonObject(
    with: FileManager.default.contents(atPath: CommandLine.arguments.dropFirst().first!)!,
    options: []) as! [String: String]
    

var terminalConfig = try! PropertyListSerialization.propertyList(from: try! FileHandle.standardInput.readToEnd()!, format: nil) as! [String:Any]


for (from, to) in colorFieldMap {
    let color = UInt32(colorConfig[from]!.dropFirst(1), radix: 16)!
    let red = CGFloat((color >> 16) & 0xFF) / 255.0
    let green = CGFloat((color >> 8) & 0xFF) / 255.0
    let blue = CGFloat(color & 0xFF) / 255.0
    let colorData = try! NSKeyedArchiver.archivedData(withRootObject: NSColor(red: red, green: green, blue: blue, alpha: 1.0), requiringSecureCoding: false)
    terminalConfig[to] = colorData
}

PropertyListSerialization.writePropertyList(terminalConfig, to: StdoutStream.shared, format: .xml, options: 0, error: nil)