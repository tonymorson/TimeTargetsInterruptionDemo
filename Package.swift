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
      name: "InterruptionPicker",
      targets: ["InterruptionPicker"]
    ),
    .library(
      name: "ButtonsBarFeature",
      targets: ["ButtonsBarFeature"]
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
      name: "SettingsEditor",
      targets: ["SettingsEditor"]
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
      name: "Countdown",
      targets: ["Countdown"]
    ),
    .library(
      name: "UserActivity",
      targets: ["UserActivity"]
    ),
    .library(
      name: "Durations",
      targets: ["Durations"]
    ),
    .library(
      name: "Ticks",
      targets: ["Ticks"]
    ),
    .library(
      name: "Periods",
      targets: ["Periods"]
    ),
    .library(
      name: "Timeline",
      targets: ["Timeline"]
    ),
    .library(
      name: "TimelineReports",
      targets: ["TimelineReports"]
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
        "SettingsEditor",
        "SwiftUIKit",
        "Timeline",
        "TimelineReports",
        "ButtonsBarFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "InterruptionPicker",
      dependencies: ["SwiftUIKit", "Timeline"]
    ),
    .target(
      name: "ButtonsBarFeature",
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
        "Ticks",
        "Timeline",
        "TimelineReports",
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
      name: "ButtonsBarFeatureTests",
      dependencies: [
        "ButtonsBarFeature",
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
        "Ticks",
        "Timeline",
        "TimelineTickEffect",
        "UserActivity",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SettingsEditor",
      dependencies: ["Durations", "Notifications"]
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
      name: "Countdown",
      dependencies: ["Ticks"]
    ),
    .target(
      name: "Durations",
      dependencies: ["Ticks"]
    ),
    .target(
      name: "Periods",
      dependencies: ["Durations", "Ticks"]
    ),
    .target(
      name: "Ticks",
      dependencies: []
    ),
    .target(
      name: "Timeline",
      dependencies: ["Countdown", "Periods", "Ticks"]
    ),
    .target(
      name: "TimelineTickEffect",
      dependencies: [
        "Ticks",
        "Timeline",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "TimelineReports",
      dependencies: ["Periods", "Ticks", "Timeline"]
    ),
  ]
)
