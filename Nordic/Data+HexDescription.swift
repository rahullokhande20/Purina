//
//  Data+HexDescription.swift
//  Nordic
//
//  Hex-string helpers used throughout the BLE screens to render
//  characteristic payloads. Previously declared inside the old scanner
//  screen (ViewController.swift), even though used project-wide; moved
//  here since they're unrelated to any one screen.
//

import Foundation

extension Data {
    var hexDescription: String {
        reduce("") { $0 + String(format: "%02x", $1) }
    }
}

extension String {
    func separate(every: Int, with separator: String) -> String {
        String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0..<min($0 + every, Array(self).count)])
        }.joined(separator: separator))
    }
}
