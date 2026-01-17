//
//  InstallerStatusViewModel.swift
//  IDeviceKit
//
//  Created by samara on 3.06.2025.
//

import Combine

extension InstallerStatusViewModel {
	public enum InstallerStatus {
		case none
		case ready
		case sendingManifest
		case sendingPayload
		case installing
		case completed(Result<Void, Error>)
		case broken(Error)
	}
}

public class InstallerStatusViewModel: ObservableObject {
	@Published public var status: InstallerStatus
	@Published public var uploadProgress: Double = 0.0
	@Published public var packageProgress: Double = 0.0
	@Published public var installProgress: Double = 0.0
	
	public var isIDevice: Bool
	
	public var overallProgress: Double {
		if isIDevice {
			(installProgress + uploadProgress + packageProgress) / 3.0
		} else {
			(installProgress + packageProgress) / 2.0
		}
	}
	
	public var isCompleted: Bool {
		if case .completed = status {
			true
		} else {
			false
		}
	}
	
	public init(
		status: InstallerStatus = .none,
		isIdevice: Bool = true
	) {
		self.status = status
		self.isIDevice = isIdevice
	}
}
