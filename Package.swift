// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Mattress",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Mattress", targets: ["Mattress"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Mattress",
            dependencies: [],
            path: "Source"
        )
    ],
    swiftLanguageVersions: [.v5]
)
