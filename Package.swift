// swift-tools-version:5.0

import PackageDescription

let package = Package(
	name: "Billiards",
	products: [
		.library(
			name: "BilliardLib",
			type: .dynamic,
			targets: ["BilliardLib"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
	],
	targets: [
		.systemLibrary(name: "Clibpng", path: "Modules"),
		.systemLibrary(name: "CGmp", path: "Modules"),
		.systemLibrary(name: "Clibbsd", path: "Modules"),
		.target(
			name: "billiards",
			dependencies: ["BilliardLib", "Logging", "Clibpng"]
		),
		.target(
			name: "CustomPointSet",
			dependencies: ["BilliardLib"]
		),
		.target(
			name: "BilliardLib",
			dependencies: ["CGmp", "Clibbsd", "Logging"]
		),
		.testTarget(
			name: "BilliardLibTests",
			dependencies: ["BilliardLib"]
		)
	]
)
