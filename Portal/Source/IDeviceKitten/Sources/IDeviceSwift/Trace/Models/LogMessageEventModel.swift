//
//  MessageEventModel.swift
//  syslog
//
//  Created by samara on 17.05.2025.
//

import UIKit.UIColor

public struct LogMessageEventModel: Hashable, CustomStringConvertible {
	public let displayText: String
	public var displayColor: UIColor?
	public let rawValue: UInt8
	
	private init(displayText: String, color: UIColor?, rawValue: UInt8) {
		self.displayText = displayText
		self.displayColor = color
		self.rawValue = rawValue
	}
	
	public init?(_ cLogType: UInt8) {
		switch cLogType {
		case 0: 	self = .default
		case 1: 	self = .info
		case 2: 	self = .debug
		case 10: 	self = .error
		case 11: 	self = .fault
		default: 	return nil
		}
	}
	
	public var description: String {
		displayText
	}
	
	private enum CodingKeys: String, CodingKey {
		case displayText
		case color
		case rawValue
	}
	
	public static func == (lhs: LogMessageEventModel, rhs: LogMessageEventModel) -> Bool {
		// This is probably bad but it works /shrug
		lhs.displayText == rhs.displayText && lhs.rawValue == rhs.rawValue
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(displayText)
		hasher.combine(rawValue)
	}
}

extension LogMessageEventModel: CaseIterable {
	// MARK: - Log types
	public static var `default` = LogMessageEventModel(
		displayText: "Default",
		color: .systemGray,
		rawValue: 0
	)
	
	public static var info = LogMessageEventModel(
		displayText: "Info",
		color: .systemGray,
		rawValue: 1
	)
	
	public static var debug = LogMessageEventModel(
		displayText: "Debug",
		color: .systemYellow,
		rawValue: 2
	)
	
	public static var error = LogMessageEventModel(
		displayText: "Error",
		color: .systemRed,
		rawValue: 10
	)
	
	public static var fault = LogMessageEventModel(
		displayText: "Fault",
		color: .systemRed,
		rawValue: 11
	)
	
	public static var allCasesNonLazily: [LogMessageEventModel] {
		[.default, .info, .debug, .fault, .error]
	}
	
	public static let allCases: [LogMessageEventModel] = allCasesNonLazily
}

extension LogMessageEventModel: Codable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(displayText, forKey: .displayText)
		try container.encode(rawValue, forKey: .rawValue)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.displayText = try container.decode(String.self, forKey: .displayText)
		self.rawValue = try container.decode(UInt8.self, forKey: .rawValue)
		
		// Assign a color based on rawValue (optional but useful)
		self.displayColor = LogMessageEventModel(rawValue)?.displayColor
	}
}
