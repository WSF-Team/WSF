//
//  SystemLogManager.swift
//  syslog
//
//  Created by samara on 14.05.2025.
//

import UIKit
import IDevice

// MARK: - Class
public class SystemLogManager: NSObject {
	static let shared = SystemLogManager()
	private let _heartbeat = HeartbeatManager.shared
	
	typealias SyslogClientHandle = OpaquePointer
	typealias OsTraceRelayClientHandle = OpaquePointer
	typealias OsTraceRelayReceiverHandle = OpaquePointer
	
	private var syslogClient: SyslogClientHandle?
	private var osTraceRelayClient: OsTraceRelayClientHandle?
	private var osTraceReceiverClient: OsTraceRelayReceiverHandle?
	
	public var isStreaming: Bool = false {
		didSet {
			NotificationCenter.default.post(
				Notification(name: .isStreamingDidChange, object: isStreaming)
			)
		}
	}
	
	public weak var delegate: SystemLogManagerDelegate?

	private func _connect() async throws {
		guard FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) else {
			throw IDeviceSwiftError(message: "Missing Pairing")
		}
		
		guard self._heartbeat.checkSocketConnection().isConnected else {
			throw IDeviceSwiftError(message: "Missing Pairing")
		}
		
		guard (self._heartbeat.provider != nil) else {
			throw IDeviceSwiftError(message: "Missing Pairing")
		}
	}
	/// Connects to syslog relay
	public func syslog_relay() async throws {
		try await Task.detached(priority: .utility) {
			try await self._connect()
			
			let syslog_relay_connect_tcp_result = syslog_relay_connect_tcp(self._heartbeat.provider, &self.syslogClient)
			guard syslog_relay_connect_tcp_result == nil else {
				throw IDeviceSwiftError(syslog_relay_connect_tcp_result)
			}
			
			NSLog("we're going?")
					
			self.isStreaming = true
			
			while self.isStreaming {
				guard let syslogClient = self.syslogClient else {
					break
				}
				
				var logLinePointer: UnsafeMutablePointer<CChar>? = nil
				let result = syslog_relay_next(syslogClient, &logLinePointer)
				
				// This may crash due to accessing an invalid pointer
				// don't know how to fix it yet! If you do know how
				// to fix it, please tell me!!!
				if result == nil, let logLinePointer = logLinePointer {
					if let logLine = String(validatingUTF8: logLinePointer) {
						self.delegate?.activityStream(didRecieveString: logLine)
						idevice_string_free(logLinePointer)
					} else {
						idevice_string_free(logLinePointer)
					}
				} else if result != nil {
					break
				}
			}
						
			if let syslogClient = self.syslogClient {
				syslog_relay_client_free(syslogClient)
				self.syslogClient = nil
			}
			
			self.isStreaming = false
		}.value
	}
	/// Connects to os trace relay, this is the backbone of our app
	public func os_trace_relay() async throws {
		try await Task.detached(priority: .utility) {
			try await self._connect()
			
			let os_trace_relay_connect_result = os_trace_relay_connect(self._heartbeat.provider, &self.osTraceRelayClient)
			guard os_trace_relay_connect_result == nil else {
				throw IDeviceSwiftError(os_trace_relay_connect_result)
			}
			
			let os_trace_relay_start_trace_result = os_trace_relay_start_trace(self.osTraceRelayClient, &self.osTraceReceiverClient, nil)
			guard os_trace_relay_start_trace_result == nil else {
				throw IDeviceSwiftError(os_trace_relay_start_trace_result)
			}
			
			self.isStreaming = true
			
			while self.isStreaming {
				guard let recClient = self.osTraceReceiverClient else {
					break
				}
				
				var oslogg: UnsafeMutablePointer<OsTraceLog>? = nil
				let result = os_trace_relay_next(recClient, &oslogg)
				
				if result == nil, let oslogg = oslogg {
					let logCopy = oslogg.pointee
					let model = LogEntry(logCopy)
					self.delegate?.activityStream(didRecieveEntry: model)
					os_trace_relay_free_log(oslogg)
				} else if result != nil {
					break
				}
			}
			
			self.isStreaming = false
			
			if let recClient = self.osTraceReceiverClient {
				os_trace_relay_receiver_free(recClient)
				self.osTraceRelayClient = nil
				self.osTraceReceiverClient = nil
			}
		}.value
	}
	/// Stops streaming
	public func stop() {
		isStreaming = false
	}
	
	deinit {
		stop()
	}
}
