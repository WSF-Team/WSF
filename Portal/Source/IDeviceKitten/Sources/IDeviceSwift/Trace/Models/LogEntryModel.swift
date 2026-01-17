//
//  LogEntryModel.swift
//  syslog
//
//  Created by samara on 17.05.2025.
//

import Foundation.NSURL
import IDevice

/// Entry Model
public struct LogEntryModel: Hashable, Codable {
	private var _id = UUID()
	/// PID (i.e. `0`)
	public var pid: UInt32
	/// Timestamp (i.e. `1748042868`)
	public var timestamp: Int64
	/// Level (i.e. `2`, which means debug)
	public var level: UInt8
	/// Sender path (i.e. `/System/Library/Frameworks/MediaPlayer.framework/Versions/A/MediaPlayer`)
	public var senderPath: String?
	/// Sender name (i.e. `MediaPlayer`)
	public var senderName: String?
	/// Process path (i.e. `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`)
	public var processPath: String?
	/// Process name (i.e. `Google Chrome`)
	public var processName: String?
	/// Entry message
	public var message: String?
	/// "Label", contains `Subsystem & Category`
	public var label: LogEntryModel.EntryLabel?
	
	public var type: LogMessageEventModel?
	
	public init(_ log: OsTraceLog) {
		self.pid = log.pid
		self.timestamp = log.timestamp
		self.level = log.level
		self.senderPath = log.image_name.flatMap { String(validatingUTF8: $0) }
		self.senderName = self.senderPath.flatMap { URL(string: $0)?.lastPathComponent }
		self.processPath = log.filename.flatMap { String(validatingUTF8: $0) }
		self.processName = self.processPath.flatMap { URL(string: $0)?.lastPathComponent }
		self.message = log.message.flatMap { String(validatingUTF8: $0) }
		self.label = LogEntryModel.EntryLabel(from: log.label)
		self.type = LogMessageEventModel(level)
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(_id)
	}
	
	public static func == (lhs: LogEntryModel, rhs: LogEntryModel) -> Bool {
		return lhs._id == rhs._id
	}
}

extension LogEntryModel {
	/// Entry Label Model
	public struct EntryLabel: Hashable, Codable {
		/// Subsytem of the entry
		public var subsystem: String?
		/// Category of the entry
		public var category: String?
		
		public init(from label: UnsafePointer<SyslogLabel>?) {
			guard let label = label?.pointee else { return }
			self.subsystem = label.subsystem.flatMap { String(cString: $0) }
			self.category = label.category.flatMap { String(cString: $0) }
		}
	}
}
