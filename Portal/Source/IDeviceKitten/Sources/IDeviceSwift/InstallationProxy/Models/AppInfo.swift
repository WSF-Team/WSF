//
//  AppInfo.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import Foundation

public struct AppInfo: Codable, Identifiable {
	public var id: String { CFBundleIdentifier ?? UUID().uuidString }
	
	public let CFBundleName: String?
	public let UISupportedInterfaceOrientations: [String]?
	public let DTXcodeBuild: String?
	public let LSRequiresIPhoneOS: Bool?
	public let UIStatusBarStyle: String?
	public let Entitlements: [String: AnyCodable]?
	public let ITSAppUsesNonExemptEncryption: AnyCodable?
	public let DTPlatformVersion: String?
	public let CFBundleURLTypes: [[String: AnyCodable]]?
	public let DTSDKBuild: String?
	public let EnvironmentVariables: [String: String]?
	public let UISupportedDevices: [String]?
	public let IsAppClip: Bool?
	public let CFBundleNumericVersion: Int?
	public let CFBundleInfoDictionaryVersion: String?
	public let SequenceNumber: Int?
	public let CFBundleDisplayName: String?
	public let CFBundleExecutable: String?
	public let ApplicationType: String?
	public let UIApplicationSupportsIndirectInputEvents: Bool?
	public let CFBundleIcons_iPad: [String: AnyCodable]? // Note: keys with ~ipad must be adjusted
	public let IsHostBackupEligible: Bool?
	public let IsDemotedApp: Bool?
	public let DTPlatformName: String?
	public let CFBundleDevelopmentRegion: String?
	public let UISupportsDocumentBrowser: Bool?
	public let SignerIdentity: String?
	public let UISupportedInterfaceOrientations_iPad: [String]?
	public let UIRequiredDeviceCapabilities: [String]?
	public let LSSupportsOpeningDocumentsInPlace: Bool?
	public let DTSDKName: String?
	public let DTAppStoreToolsBuild: String?
	public let Container: String?
	public let MinimumOSVersion: String?
	public let IsUpgradeable: Bool?
	public let ApplicationDSID: Int?
	public let UIFileSharingEnabled: Bool?
	public let DTCompiler: String?
	public let DTPlatformBuild: String?
	public let CFBundleIdentifier: String?
	public let Path: String?
	public let CFBundleVersion: String?
	public let CFBundleShortVersionString: String?
	public let CFBundleSupportedPlatforms: [String]?
	public let CFBundleIcons: [String: AnyCodable]?
	public let UILaunchScreen: AnyCodable?
	public let BuildMachineOSBuild: String?
	public let UIApplicationSceneManifest: [String: AnyCodable]?
	public let CFBundlePackageType: String?
	public let UIDeviceFamily: [Int]?
	public let DTXcode: String?
}
