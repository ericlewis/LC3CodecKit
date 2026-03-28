// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LC3CodecKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "LC3CodecKit", targets: ["LC3CodecKit"]),
    ],
    targets: [
        .target(
            name: "CLibLC3",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]
        ),
        .target(
            name: "LC3CodecKit",
            dependencies: ["CLibLC3"]
        ),
        .testTarget(
            name: "LC3CodecKitTests",
            dependencies: ["LC3CodecKit"]
        ),
    ]
)
