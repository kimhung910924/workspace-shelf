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
    dependencies: [
        // 자동 업데이트. 없으면 고쳐도 사용자가 안 받는다.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6")
    ],
    targets: [
        .executableTarget(
            name: "WorkspaceShelf",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
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
