// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClashR",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ClashR",
            targets: ["ClashR"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ClashR",
            dependencies: ["Yams"]
        ),
    ]
)
