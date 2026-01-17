//
//  InstallationAppProxy.swift
//  IDeviceKit
//
//  Created by samara on 8.06.2025.
//

import Foundation
import IDevice
import UIKit

public class InstallationAppProxy: NSObject {
	private let _heartbeat = HeartbeatManager.shared
	
	typealias InstallationProxyClientHandle = OpaquePointer
	typealias SpringBoardServicesClientHandle = OpaquePointer
	
	public var delegate: InstallationProxyAppsDelegate?
	
	public func listApps() async throws {
		var installproxy: InstallationProxyClientHandle?
		
		let allApps = try await Task.detached(priority: .userInitiated) { () -> [AppInfo] in
			guard FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) else {
				throw IDeviceSwiftError(message: "Missing Pairing")
			}
			
			guard self._heartbeat.checkSocketConnection().isConnected else {
				throw IDeviceSwiftError(message: "Missing Pairing")
			}
			
			let installation_proxy_connect_tcp_result = installation_proxy_connect_tcp(self._heartbeat.provider, &installproxy)
			guard installation_proxy_connect_tcp_result == nil else {
				throw IDeviceSwiftError(installation_proxy_connect_tcp_result)
			}
			
			var outResult: UnsafeMutableRawPointer?
			var outResultLen: Int = 0
			
			let installation_proxy_get_apps_result = installation_proxy_get_apps(installproxy, nil, nil, 0, &outResult, &outResultLen)
			guard installation_proxy_get_apps_result == nil else {
				throw IDeviceSwiftError(installation_proxy_get_apps_result)
			}
			
			var appInfos: [AppInfo] = []
			let decoder = PropertyListDecoder()
			
			if let outResult = outResult {
				let buffer = outResult.bindMemory(to: OpaquePointer?.self, capacity: outResultLen)
				let pointerBuffer = UnsafeBufferPointer(start: buffer, count: outResultLen)
				
				let appPlists = Array(pointerBuffer)
				for plist in appPlists {
					guard let plist = plist else { continue }
					
					var xml: UnsafeMutablePointer<CChar>?
					var length: UInt32 = 0
					
					plist_to_xml(UnsafeMutableRawPointer(plist), &xml, &length)
					
					if let xml = xml {
						let data = Data(bytes: xml, count: Int(length))
						
						do {
							let appInfo = try decoder.decode(AppInfo.self, from: data)
							appInfos.append(appInfo)
						} catch {
							print("Failed to decode AppInfo plist: \(error)")
						}
						free(xml)
					}
				}
			}
			
			installation_proxy_client_free(installproxy)
			
			return appInfos
		}.value
		
		await MainActor.run {
			self.delegate?.updateApplications(with: allApps)
		}
	}
	
	static public func deleteApp(for id: String) async throws {
		var installproxy: InstallationProxyClientHandle?
		
		return try await Task.detached(priority: .userInitiated) {
			let installation_proxy_connect_tcp_result = installation_proxy_connect_tcp(HeartbeatManager.shared.provider, &installproxy)
			guard installation_proxy_connect_tcp_result == nil else {
				throw IDeviceSwiftError(installation_proxy_connect_tcp_result)
			}
			
			let installation_proxy_uninstall_result = installation_proxy_uninstall(installproxy, id, nil)
			guard installation_proxy_uninstall_result == nil else {
				throw IDeviceSwiftError(installation_proxy_uninstall_result)
			}
		}.value
	}
}

extension InstallationAppProxy {
	private static var iconCache: [String: UIImage] = [:]
	private static let iconCacheQueue = DispatchQueue(label: "iconCacheQueue")
	
	static public func getAppIconCached(for id: String) async throws -> UIImage? {
		if let cached = iconCacheQueue.sync(execute: { iconCache[id] }) {
			return cached
		}
		let image = try await getAppIcon(for: id)
		if let img = image {
			iconCacheQueue.async {
				iconCache[id] = img
			}
		}
		return image
	}
	
	static public func getAppIcon(for id: String) async throws -> UIImage? {
		var springServices: SpringBoardServicesClientHandle?
		
		return try await Task.detached(priority: .userInitiated) {
			let springboard_services_connect_result = springboard_services_connect(HeartbeatManager.shared.provider, &springServices)
			guard springboard_services_connect_result == nil else {
				throw IDeviceSwiftError(springboard_services_connect_result)
			}
			
			var outResult: UnsafeMutableRawPointer?
			var outResultLen: Int = 0
			
			let springboard_services_get_icon_result = springboard_services_get_icon(springServices, id, &outResult, &outResultLen)
			guard springboard_services_get_icon_result == nil else {
				throw IDeviceSwiftError(springboard_services_get_icon_result)
			}
			
			
			guard let iconPtr = outResult else {
				throw IDeviceSwiftError(message: "Missing Pointer")
			}
			
			let iconData = Data(bytes: iconPtr, count: outResultLen)
			
			springboard_services_free(springServices)
			
			return UIImage(data: iconData)
		}.value
	}
}
