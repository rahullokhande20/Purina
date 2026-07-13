//
//  SignalStrengthTests.swift
//  NordicTests
//
//  Covers the RSSI-to-icon mapping extracted from the device scanner's
//  cellForRowAt, including the pre-existing boundary overlap preserved
//  from the original switch statement.
//

import XCTest
@testable import Nordic

final class SignalStrengthTests: XCTestCase {

    func test_strongSignal_mapsToFullBars() {
        XCTAssertEqual(SignalStrength.imageName(forRSSI: NSNumber(value: -20)), "signal_strength_5")
    }

    func test_midSignal_mapsToMidBars() {
        XCTAssertEqual(SignalStrength.imageName(forRSSI: NSNumber(value: -60)), "signal_strength_3")
    }

    func test_weakSignal_mapsToNoBars() {
        XCTAssertEqual(SignalStrength.imageName(forRSSI: NSNumber(value: -95)), "signal_strength_0")
    }

    func test_positiveAndNegativeRssiWithSameMagnitude_mapEqually() {
        // RSSI is typically negative (e.g. -60 dBm). Confirm abs() handles
        // a positive input the same way as the original `labs(...)` did.
        XCTAssertEqual(
            SignalStrength.imageName(forRSSI: NSNumber(value: -45)),
            SignalStrength.imageName(forRSSI: NSNumber(value: 45))
        )
    }

    func test_boundaryValue77_hitsFirstMatchingBand() {
        // The original switch has overlapping ranges (66...77 and
        // 77...89); Swift resolves this by matching the first case in
        // source order, so 77 always lands in signal_strength_2.
        XCTAssertEqual(SignalStrength.imageName(forRSSI: NSNumber(value: -77)), "signal_strength_2")
    }
}
