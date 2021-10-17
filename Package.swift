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
      name: "NotificationSettingsEditor",
      targets: ["NotificationSettingsEditor"]
    ),
    .library(
      name: "RingsView",
      targets: ["RingsView"]
    ),
    .library(
      name: "RingsPopupMenu",
      targets: ["RingsPopupMenu"]
    ),
    .library(
      name: "SettingsEditor",
      targets: ["SettingsEditor"]
    ),
    .library(
      name: "SwiftUIKit",
      targets: ["SwiftUIKit"]
    ),

    // Model
    .library(
      name: "Countdown",
      targets: ["Countdown"]
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
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Application",
      dependencies: ["InterruptionPicker", "RingsPopupMenu", "RingsView", "SettingsEditor", "SwiftUIKit", "Timeline", "TimelineReports"]
    ),
    .target(
      name: "InterruptionPicker",
      dependencies: ["SwiftUIKit", "Timeline"]
    ),
    .target(
      name: "NotificationSettingsEditor",
      dependencies: ["SwiftUIKit"]
    ),
    .target(
      name: "RingsView",
      dependencies: ["SwiftUIKit"]
    ),
    .target(
      name: "RingsPopupMenu",
      dependencies: []
    ),
    .target(
      name: "SettingsEditor",
      dependencies: ["Durations", "NotificationSettingsEditor"]
    ),
    .target(
      name: "SwiftUIKit",
      dependencies: []
    ),

    // Model

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
      name: "TimelineReports",
      dependencies: ["Periods", "Ticks", "Timeline"]
    ),
  ]
)
