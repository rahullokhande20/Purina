//
//  HomeConnectionStateTests.swift
//  NordicTests
//
//  Pure-logic coverage for the Home screen's connection state enum.
//

import XCTest
@testable import Nordic

final class HomeConnectionStateTests: XCTestCase {

    func test_disconnected_isNotConnectedAndNotReady() {
        let state = HomeConnectionState.disconnected

        XCTAssertFalse(state.isConnected)
        XCTAssertFalse(state.isDeviceReady)
        XCTAssertEqual(state.statusText, "Not Connected")
        XCTAssertEqual(state.buttonTitle, "Connect")
    }

    func test_discovering_isConnectedButNotReady() {
        let state = HomeConnectionState.discovering

        XCTAssertTrue(state.isConnected)
        XCTAssertFalse(state.isDeviceReady)
        XCTAssertEqual(state.statusText, "Connected")
        XCTAssertEqual(state.buttonTitle, "Disconnect")
    }

    func test_ready_isConnectedAndReady() {
        let state = HomeConnectionState.ready

        XCTAssertTrue(state.isConnected)
        XCTAssertTrue(state.isDeviceReady)
        XCTAssertEqual(state.statusText, "Ready")
        XCTAssertEqual(state.buttonTitle, "Disconnect")
    }
}
