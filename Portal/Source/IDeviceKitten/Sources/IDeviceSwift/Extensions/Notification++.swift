//
//  Notification+custom.swift
//  Feather
//
//  Created by samara on 29.04.2025.
//

import Foundation.NSNotification

extension Notification.Name {
	static public let heartbeat = Notification.Name("FR.heartBeat")
	static public let heartbeatInvalidHost = Notification.Name("FR.heartBeatInvalidHost")
	static public let isStreamingDidChange = Notification.Name("SY.isStreamingDidChange")
}
