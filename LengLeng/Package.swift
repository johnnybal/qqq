// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "LengLeng",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LengLeng",
            targets: ["LengLeng"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.24.0"),
    ],
    targets: [
        .target(
            name: "LengLeng",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]),
        .testTarget(
            name: "LengLengTests",
            dependencies: ["LengLeng"]),
    ]
) 