//
//  HomeViewModelTests.swift
//  NordicTests
//
//  Covers HomeViewModel's menu-enablement and selection business logic
//  using a fake BluetoothConnectionServicing, so no real CoreBluetooth
//  stack is required.
//

import XCTest
import CoreBluetooth
@testable import Nordic

final class HomeViewModelTests: XCTestCase {

    private final class FakeBluetoothConnectionService: BluetoothConnectionServicing {
        var centralManager: CBCentralManager?
        var peripheral: CBPeripheral?
        private(set) var disconnectCallCount = 0

        func disconnectCurrentPeripheral() {
            disconnectCallCount += 1
        }
    }

    func test_initialState_isDisconnected() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())

        XCTAssertEqual(viewModel.connectionState, .disconnected)
    }

    func test_isItemEnabled_falseForDeviceRequiredItemWhileDisconnected() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())

        XCTAssertFalse(viewModel.isItemEnabled(.ecg))
    }

    func test_isItemEnabled_trueForItemThatDoesNotRequireDevice() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())

        XCTAssertTrue(viewModel.isItemEnabled(.textFiles))
    }

    func test_selectItem_requiringDeviceWhileDisconnected_firesConnectionRequiredAlertNotNavigate() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())
        var alertFired = false
        var navigated = false
        viewModel.onConnectionRequiredAlert = { alertFired = true }
        viewModel.onNavigate = { _, _ in navigated = true }

        viewModel.selectItem(.ecg)

        XCTAssertTrue(alertFired)
        XCTAssertFalse(navigated)
    }

    func test_selectItem_notRequiringDevice_firesNavigateWithThatItem() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())
        var navigatedItem: HomeMenuItem?
        viewModel.onNavigate = { item, _ in navigatedItem = item }

        viewModel.selectItem(.textFiles)

        XCTAssertEqual(navigatedItem, .textFiles)
    }

    func test_connectButtonTapped_whileDisconnected_requestsScannerPresentation() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())
        var requested = false
        viewModel.onRequestScannerPresentation = { requested = true }

        viewModel.connectButtonTapped()

        XCTAssertTrue(requested)
    }

    func test_resetConnectionState_notifiesDisconnected() {
        let viewModel = HomeViewModel(connectionService: FakeBluetoothConnectionService())
        var states: [HomeConnectionState] = []
        viewModel.onConnectionStateChanged = { states.append($0) }

        viewModel.resetConnectionState()

        XCTAssertEqual(states, [.disconnected])
    }
}
