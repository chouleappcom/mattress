// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Mattress",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "Mattress", targets: ["Mattress"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("1.3.8"))
    ],
    targets: [
        .target(
            name: "Mattress",
            dependencies: ["CryptoSwift"],
            path: "Source"
        )
    ],
    swiftLanguageVersions: [.v5]
)
