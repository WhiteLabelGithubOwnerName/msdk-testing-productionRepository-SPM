// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WalleeTestSdk",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "WalleeTestSdk",
                 targets: ["TwintSDK","WalleeTestSdk"]),
    ],
    targets: [
		.binaryTarget(name: "TwintSDK",
									 path:  "TwintSDK.xcframework"),
		.binaryTarget(name: "WalleeTestSdk",
									 path:  "WalleeTestSdk.xcframework"),

    ]
)