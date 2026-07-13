//
//  HomeConnectionState.swift
//  Nordic
//
//  Display state for the Home screen BLE connection controls.
//

import UIKit

enum HomeConnectionState: Equatable {
    case disconnected
    case discovering
    case ready

    var isConnected: Bool {
        switch self {
        case .disconnected:
            return false
        case .discovering, .ready:
            return true
        }
    }

    var isDeviceReady: Bool {
        self == .ready
    }

    var statusText: String {
        switch self {
        case .disconnected:
            return "Not Connected"
        case .discovering:
            return "Connected"
        case .ready:
            return "Ready"
        }
    }

    var buttonTitle: String {
        isConnected ? "Disconnect" : "Connect"
    }

    var buttonFillColor: UIColor {
        isConnected ? DesignSystem.Palette.accent : DesignSystem.Palette.brand
    }

    var statusColor: UIColor {
        switch self {
        case .disconnected:
            return DesignSystem.Palette.secondaryText
        case .discovering:
            return DesignSystem.Palette.warning
        case .ready:
            return DesignSystem.Palette.success
        }
    }
}
