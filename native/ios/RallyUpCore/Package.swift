// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RallyUpCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "RallyUpCore", targets: ["RallyUpCore"])],
    targets: [
        .target(name: "RallyUpCore"),
        .testTarget(name: "RallyUpCoreTests", dependencies: ["RallyUpCore"]),
    ]
)
