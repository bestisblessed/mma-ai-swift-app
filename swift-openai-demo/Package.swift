// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-openai-demo",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.4.5")
    ],
    targets: [
        .executableTarget(
            name: "swift-openai-demo",
            dependencies: ["OpenAI"]
        ),
    ]
)
