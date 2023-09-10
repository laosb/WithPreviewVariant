// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "WithPreviewVariant",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .macCatalyst(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WithPreviewVariant",
            targets: ["WithPreviewVariant"]
        ),
        .executable(
            name: "WithPreviewVariantClient",
            targets: ["WithPreviewVariantClient"]
        ),
    ],
    dependencies: [
        // Depend on the latest Swift 5.9 prerelease of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-09-05-a"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "WithPreviewVariantMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "WithPreviewVariant", dependencies: ["WithPreviewVariantMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "WithPreviewVariantClient", dependencies: ["WithPreviewVariant"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "WithPreviewVariantTests",
            dependencies: [
                "WithPreviewVariantMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
