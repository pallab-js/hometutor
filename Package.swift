// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HomeTutor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "HomeTutor", targets: ["HomeTutor"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HomeTutor",
            dependencies: [],
            path: "Sources"
        )
    ]
)
