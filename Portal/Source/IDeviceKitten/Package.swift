// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "IDeviceKit",
	platforms: [
		.iOS(.v15),
		.macOS(.v12),
	],
	products: [
		.library(
			name: "IDevice",
			targets: ["IDevice"]
		),
		.library(
			name: "plist",
			targets: ["plist"]
		),
		.library(
			name: "IDeviceSwift",
			targets: ["IDeviceSwift"]
		),
	],
	targets: [
		.binaryTarget(
			name: "IDevice",
			path: "Frameworks/IDevice.xcframework"
		),
		.binaryTarget(
			name: "plist",
			path: "Frameworks/plist.xcframework"
		),
		.target(
			name: "IDeviceSwift",
			dependencies: ["IDevice", "plist"]
		),
	]
)
