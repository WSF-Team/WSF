//
//  ConduitInstaller.swift
//  Feather
//
//  Created by samara on 23.04.2025.
//

import Foundation
import SwiftUI
import IDevice
import UIKit.UIApplication

public class InstallationProxy: Identifiable, ObservableObject {
	private let _heartbeat = HeartbeatManager.shared
	private let _uuid = UUID().uuidString
	
	typealias AfcClientHandle = OpaquePointer
	typealias AfcFileHandle = OpaquePointer
	typealias InstallationProxyClientHandle = OpaquePointer
	
	@ObservedObject
	public var viewModel: InstallerStatusViewModel
	
	public init(viewModel: InstallerStatusViewModel) {
		self.viewModel = viewModel
	}
	
	public func install(at url: URL, suspend: Bool = false) async throws {
		var afcClient: AfcClientHandle?
		var fileHandle: AfcFileHandle?
		var installproxy: InstallationProxyClientHandle?
		
		try await Task.detached(priority: .userInitiated) {
			guard FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) else {
				throw IDeviceSwiftError(message: "Missing Pairing")
			}
			
			guard await self._heartbeat.checkSocketConnection().isConnected else {
				throw IDeviceSwiftError(message: "Missing Pairing")
			}
			
			defer {
				afc_client_free(afcClient)
				installation_proxy_client_free(installproxy)
			}
			
			let heartbeat = await self._heartbeat
			guard let provider = heartbeat.provider else {
				throw IDeviceSwiftError(message: "Cannot connect to AFC")
			}
			
			guard afc_client_connect(provider, &afcClient) == nil else {
				throw IDeviceSwiftError(message: "Cannot connect to AFC")
			}
			
			let stagingDir = "PublicStaging"
			
			let afc_make_directory_result =  afc_make_directory(afcClient, stagingDir)
			guard afc_make_directory_result == nil else {
				throw IDeviceSwiftError(afc_make_directory_result)
			}
			
			let remoteDir = "/\(stagingDir)/\(self._uuid).ipa"
			
			let afc_file_open_result = afc_file_open(afcClient, remoteDir, AfcWrOnly, &fileHandle)
			guard afc_file_open_result == nil else {
				throw IDeviceSwiftError(afc_file_open_result)
			}
			
			try await self._updateStatus(with: .sendingPayload)
			
			guard let fileHandle = fileHandle else {
				throw IDeviceSwiftError(message: "Missing File Handle")
			}

			let data = try Data(contentsOf: url)
			let totalSize = data.count
			let chunkSize = 64 * 1024 // 64kb
			var totalBytesWritten = 0
			
			guard let rawBuffer = data.withUnsafeBytes({ $0.baseAddress })?.assumingMemoryBound(to: UInt8.self) else {
				throw IDeviceSwiftError(message: "Error writing to AFC")
			}
			
			while totalBytesWritten < totalSize {
				let bytesLeft = totalSize - totalBytesWritten
				let bytesToWrite = min(chunkSize, bytesLeft)
				let writePtr = rawBuffer.advanced(by: totalBytesWritten)
				
				let result = afc_file_write(fileHandle, writePtr, bytesToWrite)
				if result != nil {
					throw IDeviceSwiftError(result)
				}
				
				totalBytesWritten += bytesToWrite
				
				let progress = Double(totalBytesWritten) / Double(totalSize)
				try await self._updateUploadProgress(with: progress)
			}
			
			let afc_file_close_result = afc_file_close(fileHandle)
			guard afc_file_close_result == nil else {
				throw IDeviceSwiftError(afc_file_close_result)
			}
			
			try await self._updateStatus(with: .installing)
			
			let installation_proxy_connect_tcp_result = installation_proxy_connect_tcp(provider, &installproxy)
			guard installation_proxy_connect_tcp_result == nil else {
				throw IDeviceSwiftError(installation_proxy_connect_tcp_result)
			}
			
			let installError: UnsafeMutablePointer<IdeviceFfiError>? = remoteDir.withCString { cString in
				let context = Unmanaged.passUnretained(self).toOpaque()
				
				if suspend {
					DispatchQueue.main.async {
						UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
					}
				}
				
				return installation_proxy_install_with_callback(
					installproxy,
					cString,
					nil, // options
					Self._installationProgressCallback,
					context
				)
			}
			
			guard installError == nil else {
				throw IDeviceSwiftError(installError)
			}
			
			try await Task.sleep(nanoseconds: 350_000_000)
			try await self._updateStatus(with: .completed(.success(())))
		}.value
	}
	
	private func _updateStatus(with status: InstallerStatusViewModel.InstallerStatus) async throws {
		await MainActor.run {
			self.viewModel.status = status
		}
	}
	
	private func _updateUploadProgress(with status: Double) async throws {
		await MainActor.run {
			self.viewModel.uploadProgress = status
		}
	}
	
	nonisolated static private let _installationProgressCallback: @convention(c) (
		UInt64,
		UnsafeMutableRawPointer?
	) -> Void = { progress, context in
		guard let context = context else { return }
		let installer = Unmanaged<InstallationProxy>.fromOpaque(context).takeUnretainedValue()
		Task {
			try? await installer._updateInstallProgress(with: Double(progress) / 100.0)
		}
	}
	
	private func _updateInstallProgress(with status: Double) async throws {
		await MainActor.run {
			self.viewModel.installProgress = status
		}
	}
}
