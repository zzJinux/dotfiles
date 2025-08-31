#!/usr/bin/swift
import AppKit
import UniformTypeIdentifiers

let pasteboard = NSPasteboard.general
let outputDirectory = FileManager.default.currentDirectoryPath

guard let types = pasteboard.types else {
    print("No types found in the pasteboard.")
    exit(1)
}

for type in types {
    guard let data = pasteboard.data(forType: type) else {
        print("No data for type \(type.rawValue)")
        continue
    }
    let sanitizedName = type.rawValue.replacingOccurrences(of: "[^a-zA-Z0-9._-]", with: "_", options: .regularExpression)
    let filename = "\(sanitizedName)"
    let fileURL = URL(fileURLWithPath: outputDirectory).appendingPathComponent(filename)
    do {
        try data.write(to: fileURL)
        print("Wrote \(data.count) bytes to \(filename)")
    } catch {
        print("Failed to write \(filename): \(error)")
    }
}
