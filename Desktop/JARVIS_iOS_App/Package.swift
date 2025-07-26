// Swift Package Dependencies for JARVIS iOS App

import PackageDescription

let package = Package(
    name: "JARVIS",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        // WebSocket support for MCP connections
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
        
        // Keychain for secure storage
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "20.0.0"),
        
        // Lottie for animations (optional)
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "JARVIS",
            dependencies: [
                "Starscream",
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "Lottie", package: "lottie-ios")
            ]
        )
    ]
)