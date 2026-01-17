//
//  Heartbeat.swift
//  Feather
//
//  Created by samara on 23.04.2025.
//

import Foundation
import UIKit.UIApplication
import Combine
import IDevice

// MARK: - Class
// ـ♡ﮩ٨ـ heartbeat ♪₊˚
public class HeartbeatManager {
	static public let shared = HeartbeatManager()
	
	typealias IdevicePairingFile = OpaquePointer
	typealias TcpProviderHandle = OpaquePointer
	typealias HeartbeatClientHandle = OpaquePointer
	
	public var fileManager = FileManager.default
	var provider: TcpProviderHandle?
	public var heartbeatThread: Thread?
	
	public var sessionId: UInt32? = nil
	public let ipAddress: String = "10.7.0.1"
	public let port: UInt16 = UInt16(LOCKDOWN_PORT)
	
	public let restartLock = NSLock()
	public var isRestartInProgress = false
	public var restartBackoffTime: TimeInterval = 1.0
	public var restartWorkItem: DispatchWorkItem?
	public var firstRun = false
	
	public var cancellable: AnyCancellable? // Combine
	
	// One important note is that if a user gets `InvalidHostID -9` from heartbeat
	// we need to ask them to reimport a fresh pairingfile,
	public init() {
		#if DEBUG
		idevice_init_logger(IdeviceLogLevel.init(3), Disabled, nil)
		#endif
		
		// On first start, just be a normal run, on second and onwards
		// we force restart it with a different sessionid
		cancellable = NotificationCenter.default
			.publisher(for: UIApplication.willEnterForegroundNotification)
			.receive(on: DispatchQueue.main)
			.sink { notification in
				let forceRestart = self.firstRun
				self.firstRun = true
				self.start(forceRestart)
			}
	}
	/// Returns (idevice) pairing file path
	/// - Returns: `Documents/Feather/pairingFile.plist`
	static public func pairingFile() -> String {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("pairingFile.plist").relativePath
	}
}
