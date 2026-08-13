// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ToDoDemoUI",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "ToDoDemoUI",
            targets: ["ToDoDemoUI"]
        ),
    ],
    targets: [
        .target(
            name: "ToDoDemoUI",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "ToDoDemoUITests",
            dependencies: ["ToDoDemoUI"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
