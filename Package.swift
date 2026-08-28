// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WorkspaceShelf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WorkspaceShelf", targets: ["WorkspaceShelf"])
    ],
    targets: [
        .executableTarget(
            name: "WorkspaceShelf",
            path: "Sources/WorkspaceShelf",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("QuickLookUI")
            ]
        ),
        .testTarget(
            name: "WorkspaceShelfTests",
            dependencies: ["WorkspaceShelf"],
            path: "Tests/WorkspaceShelfTests"
        )
    ]
)
