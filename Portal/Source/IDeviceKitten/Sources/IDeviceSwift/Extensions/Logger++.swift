//
//  Logger++.swift
//  Feather
//
//  Created by samara on 24.05.2025.
//

import Foundation.NSBundle
import struct OSLog.Logger

extension Logger {
	static let heartbeat = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Heartbeat")
}
