//
//  IDeviceSwiftError.swift
//  IDeviceKit
//
//  Created by samara on 3.06.2025.
//

import Foundation
import IDevice

struct IDeviceSwiftError: Error {
	private let _message: String
	private let _code: Int32
	
	init(_ error: IdeviceFfiError?) {
		self._message = error?.message.flatMap {
			String(cString: $0)
		} ?? ""
		self._code = error?.code ?? 0
	}
	
	init(_ error: UnsafeMutablePointer<IdeviceFfiError>?) {
		if let cMessage = error?.pointee.message {
			self._message = String(cString: cMessage)
		} else {
			self._message = ""
		}
		self._code = error?.pointee.code ?? 0
	}
	
	init(
		_ code: Int32 = -7001, // our custom error hehe
		message: String
	) {
		self._message = message
		self._code = code
	}
}
