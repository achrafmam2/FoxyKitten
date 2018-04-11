// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "FoxyKitten",
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "../ClangUtil", .branch("master")),
    .package(url: "../Matching", .branch("master")),
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc"),
    .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0-rc"),
    // ccmark dependency for CommonMark manipulation.
    .package(url: "https://github.com/achrafmam2/ccmark.git", .branch("master")),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "FoxyKitten",
      dependencies: ["FoxyVapor"]),
    .target(
      name: "FoxyVapor",
      dependencies: ["FoxyKittenLib", "Vapor", "Leaf"]),
    .target(
      name: "FoxyKittenLib",
      dependencies: ["ClangUtil", "Matching"]),
    .testTarget(
      name: "FoxyKittenLibTests",
      dependencies: ["FoxyKittenLib"]),
  ]
)
