//
//  Device+Extensions.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

extension UIDevice {
    /// Returns true if the current device is an iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns true if the current device is an iPhone
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

/// Environment value for detecting device type
struct DeviceTypeKey: EnvironmentKey {
    static let defaultValue: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
}

extension EnvironmentValues {
    var deviceType: UIUserInterfaceIdiom {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }
}

/// Helper to determine if we should use split view layout
struct SplitViewHelper {
    static func shouldUseSplitView(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        // Use split view on iPad in regular horizontal size class (landscape)
        return UIDevice.isIPad && horizontalSizeClass == .regular
    }
}
