// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenCodeMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenCodeMonitor", targets: ["OpenCodeMonitor"])
    ],
    targets: [
        .executableTarget(
            name: "OpenCodeMonitor",
            path: "Sources/OpenCodeMonitor",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
