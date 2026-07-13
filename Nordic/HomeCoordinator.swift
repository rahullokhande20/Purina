//
//  HomeCoordinator.swift
//  Nordic
//
//  Owns Home screen navigation: destination construction and pushing.
//  Promoted from the earlier HomeRouter (destination-construction-only)
//  to also own the push, so HomeViewController no longer touches
//  `navigationController` directly for feature navigation.
//

import UIKit
import CoreBluetooth

/// Minimal navigation-ownership contract shared by flow coordinators.
///
/// `HomeCoordinator` is the first adopter. Because `HomeViewController` is
/// still instantiated by the app's launch storyboard (see `SceneDelegate`),
/// it can't yet be constructor-injected with a coordinator that owns its
/// lifecycle end-to-end — so for now `HomeCoordinator` is created by the
/// view controller it serves, scoped to pushing Home's destinations onto
/// the existing navigation stack. Later flow coordinators (Phase 2) can
/// adopt the fuller "coordinator creates and owns its screen" pattern if
/// app launch moves off the storyboard-driven root.
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController? { get set }
}

struct HomeRouteContext {
    let peripheral: CBPeripheral?
    let characteristic: CBCharacteristic?
    let deviceTitle: String
}

final class HomeCoordinator: Coordinator {

    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    /// Builds the destination for `item` and pushes it onto the owned
    /// navigation controller. Returns `false` if no destination could be
    /// built, mirroring the previous `HomeRouter.destination(...)` failure
    /// case that callers already guarded against.
    @discardableResult
    func navigate(to item: HomeMenuItem, context: HomeRouteContext) -> Bool {
        guard let destination = destination(for: item, context: context) else { return false }
        navigationController?.pushViewController(destination, animated: true)
        return true
    }

    private func destination(for item: HomeMenuItem, context: HomeRouteContext) -> UIViewController? {
        switch item {
        case .singleChannelDoppler:
            guard let controller: LND339ViewController = instantiateFromMainStoryboard() else { return nil }
            controller.peripheral = context.peripheral
            controller.char = context.characteristic
            controller.titleString = context.deviceTitle
            return controller

        case .ecg:
            guard let controller: LND2ViewController = instantiateFromMainStoryboard() else { return nil }
            controller.titleString = context.deviceTitle
            return controller

        case .ecgAndSingleChannelDoppler:
            return instantiateFromMainStoryboard() as ECGViewController?

        case .firmwareUpdate:
            guard let controller: RightPCBViewController = instantiateFromMainStoryboard() else { return nil }
            controller.characteristic = context.characteristic
            return controller

        case .deviceInfo:
            guard let controller: StatusViewController = instantiateFromMainStoryboard() else { return nil }
            controller.char = context.characteristic
            return controller

        case .multiChannelDoppler:
            guard let controller: ChannelsViewController = instantiateFromMainStoryboard() else { return nil }
            controller.titleString = context.deviceTitle
            return controller

        case .ecgAndMultiChannelDoppler:
            return instantiateFromMainStoryboard() as ScrollViewController?

        case .textFiles:
            return TxtViewController()

        case .deviceFirmwareUpdate:
            return DFUFileSelectorViewController(documentPicker: DFUDocumentPicker())
        }
    }

    /// Instantiates a view controller from Main.storyboard, using the type
    /// name as the storyboard identifier (the project's convention).
    private func instantiateFromMainStoryboard<T: UIViewController>(_ type: T.Type = T.self) -> T? {
        let identifier = String(describing: T.self)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
            assertionFailure("Main.storyboard has no \(T.self) with identifier \(identifier)")
            return nil
        }
        return controller
    }
}
