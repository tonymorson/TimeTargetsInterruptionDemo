// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TimeTargets",
  platforms: [
    .iOS("15.0"),
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "Application",
      targets: ["Application"]
    ),
    .library(
      name: "TabBarFeature",
      targets: ["TabBarFeature"]
    ),
    .library(
      name: "InterruptionPicker",
      targets: ["InterruptionPicker"]
    ),
    .library(
      name: "ToolbarFeature",
      targets: ["ToolbarFeature"]
    ),
    .library(
      name: "Notifications",
      targets: ["Notifications"]
    ),
    .library(
      name: "RingsView",
      targets: ["RingsView"]
    ),
    .library(
      name: "PromptsFeature",
      targets: ["PromptsFeature"]
    ),
    .library(
      name: "SettingsFeature",
      targets: ["SettingsFeature"]
    ),
    .library(
      name: "SwiftUIKit",
      targets: ["SwiftUIKit"]
    ),
    .library(
      name: "TimelineTickEffect",
      targets: ["TimelineTickEffect"]
    ),

    // Model
    .library(
      name: "UserActivity",
      targets: ["UserActivity"]
    ),
    .library(
      name: "Timeline",
      targets: ["Timeline"]
    ),
  ],

  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", .branch("main")),
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Application",
      dependencies: [
        "InterruptionPicker",
        "PromptsFeature",
        "RingsView",
        "SettingsFeature",
        "SwiftUIKit",
        "TabBarFeature",
        "Timeline",
        "ToolbarFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "TabBarFeature",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SettingsFeature",
      dependencies: [
        "Notifications",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "InterruptionPicker",
      dependencies: ["SwiftUIKit", "Timeline"]
    ),
    .target(
      name: "ToolbarFeature",
      dependencies: [
        "SwiftUIKit",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Notifications",
      dependencies: ["SwiftUIKit", "Timeline"]
    ),
    .target(
      name: "RingsView",
      dependencies: [
        "SwiftUIKit",
        "Timeline",
        "TimelineTickEffect",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "RingsViewTests",
      dependencies: [
        "RingsView",
      ]
    ),

    .testTarget(
      name: "PromptsFeatureTests",
      dependencies: [
        "PromptsFeature",
      ]
    ),
    .testTarget(
      name: "UserActivityTests",
      dependencies: [
        "UserActivity",
      ]
    ),
    .target(
      name: "PromptsFeature",
      dependencies: [
        "Timeline",
        "TimelineTickEffect",
        "UserActivity",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SwiftUIKit",
      dependencies: []
    ),

    // Model

    .target(
      name: "UserActivity",
      dependencies: [
        "Timeline",
        "TimelineTickEffect",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Timeline",
      dependencies: []
    ),
    .target(
      name: "TimelineTickEffect",
      dependencies: [
        "Timeline",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
  ]
)
