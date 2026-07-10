// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Steepr",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .executable(name: "Steepr", targets: ["Steepr"]),
        .executable(name: "SteeprWatch", targets: ["SteeprWatch"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Steepr",
            dependencies: [],
            path: "Sources/Steepr",
            exclude: ["Info.plist", "Steepr.entitlements"],
            resources: [
                .process("Assets.xcassets"),
                .process("PrivacyInfo.xcprivacy"),
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "SteeprWatch",
            dependencies: [],
            path: "Sources/SteeprWatch",
            exclude: ["SteeprWatch.entitlements"],
            resources: [
                .process("Assets.xcassets"),
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "SteeprTests",
            dependencies: ["Steepr"],
            path: "Tests/SteeprTests"
        )
    ]
)
