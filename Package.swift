// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Steepr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Steepr", targets: ["Steepr"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Steepr",
            dependencies: [],
            path: "Sources/Steepr"
        )
    ]
)
