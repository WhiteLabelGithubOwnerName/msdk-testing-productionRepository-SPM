// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WalleeTestSdk",
    platforms: [.iOS("12.4")],
    products: [
        .library(name: "WalleeTestSdk",
                 targets: ["ThreeDS_SDK","TwintSDK","WalleeTestSdk","PaymentResources"]),
    ],
    targets: [
		.binaryTarget(name: "ThreeDS_SDK", path: "ThreeDS_SDK.xcframework"),
		.binaryTarget(name: "TwintSDK", path: "TwintSDK.xcframework"),
		.binaryTarget(name: "WalleeTestSdk", path: "WalleeTestSdk.xcframework"),
	.target(
		name: "PaymentResources",
		dependencies: [
			.target(name: "WalleeTestSdk")
		],
		path: "Sources/PaymentResources",
		sources: ["PaymentResources.swift"],
		resources: [
			.process("walleetestsdkbundle.jsbundle")
		]
	)
    ]
)