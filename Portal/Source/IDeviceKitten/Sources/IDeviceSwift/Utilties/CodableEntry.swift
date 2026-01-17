//
//  CodableEntry.swift
//  Protokolle
//
//  Created by samara on 23.05.2025.
//

import Foundation
import IDevice

// MARK: - EntryDelegate Protocol

public protocol LogEntryDelegate {
	var log: LogEntryModel { get }
}

// MARK: - CodableEntry

public struct CodableLogEntry: Codable, LogEntryDelegate {
	public var log: LogEntryModel
	
	public init(log: LogEntryModel) {
		self.log = log
	}
	
	private enum CodingKeys: String, CodingKey {
		case log
	}
}

public class LogEntry: LogEntryDelegate, Hashable {
	public var log: LogEntryModel
	
	public init(_ log: OsTraceLog) {
		self.log = LogEntryModel(log)
	}
	
	public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
		lhs.log == rhs.log
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(log)
	}
}
