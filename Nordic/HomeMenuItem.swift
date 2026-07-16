//
//  HomeMenuItem.swift
//  Nordic
//
//  Home screen menu model and display metadata.
//

import UIKit

/// The Home screen features in display order.
enum HomeMenuItem: Int, CaseIterable {
    case singleChannelDoppler
    case ecg
    case ecgAndSingleChannelDoppler
    case firmwareUpdate
    case deviceInfo
    case multiChannelDoppler
    case ecgAndMultiChannelDoppler
    case textFiles
    case deviceFirmwareUpdate

    var title: String {
        switch self {
        case .singleChannelDoppler: return "Single Channel Doppler (SCD)"
        case .ecg: return "ECG"
        case .ecgAndSingleChannelDoppler: return "ECG & SCD"
        case .firmwareUpdate: return "Firmware Update SCD"
        case .deviceInfo: return "Device Info SCD"
        case .multiChannelDoppler: return "Multi Channel Doppler (MCD)"
        case .ecgAndMultiChannelDoppler: return "ECG & MCD"
        case .textFiles: return "Text Files"
        case .deviceFirmwareUpdate: return "DFU"
        }
    }

    /// Short description shown under the title on the home menu card.
    var subtitle: String {
        switch self {
        case .singleChannelDoppler: return "Single-channel Doppler recording"
        case .ecg: return "Electrocardiogram recording"
        case .ecgAndSingleChannelDoppler: return "Combined recording session"
        case .firmwareUpdate: return "Update SCD firmware"
        case .deviceInfo: return "View SCD device details"
        case .multiChannelDoppler: return "Multi-channel Doppler recording"
        case .ecgAndMultiChannelDoppler: return "Combined recording session"
        case .textFiles: return "Exported reports and logs"
        case .deviceFirmwareUpdate: return "Update device firmware"
        }
    }

    var systemImageName: String {
        switch self {
        case .singleChannelDoppler: return "waveform.path"
        case .ecg: return "waveform.path.ecg"
        case .ecgAndSingleChannelDoppler: return "heart.text.square"
        case .firmwareUpdate: return "arrow.triangle.2.circlepath"
        case .deviceInfo: return "info.circle"
        case .multiChannelDoppler: return "dot.radiowaves.left.and.right"
        case .ecgAndMultiChannelDoppler: return "waveform.circle"
        case .textFiles: return "doc.text"
        case .deviceFirmwareUpdate: return "square.and.arrow.down"
        }
    }

    /// Asset catalog image used if the SF Symbol is unavailable.
    var fallbackImageName: String {
        switch self {
        case .firmwareUpdate: return "bootload"
        case .deviceInfo, .textFiles: return "txt"
        default: return "heart"
        }
    }

    var iconTint: UIColor {
        switch self {
        case .singleChannelDoppler, .multiChannelDoppler:
            return DesignSystem.Palette.brand
        case .ecg, .ecgAndSingleChannelDoppler, .ecgAndMultiChannelDoppler:
            return DesignSystem.Palette.vital
        case .firmwareUpdate, .deviceFirmwareUpdate:
            return DesignSystem.Palette.warning
        case .deviceInfo:
            return DesignSystem.Palette.info
        case .textFiles:
            return DesignSystem.Palette.document
        }
    }

    /// Whether the destination screen needs an active BLE connection.
    var requiresConnectedDevice: Bool {
        switch self {
        case .ecgAndSingleChannelDoppler, .ecgAndMultiChannelDoppler, .textFiles:
            return false
        default:
            return true
        }
    }

    func cardViewModel(isEnabled: Bool) -> HomeMenuCardCell.ViewModel {
        HomeMenuCardCell.ViewModel(
            title: title,
            systemImageName: systemImageName,
            fallbackImageName: fallbackImageName,
            iconTint: iconTint,
            caption: subtitle,
            isEnabled: isEnabled
        )
    }
}
