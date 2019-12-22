// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Billiards",
    products: [
      .library(
        name: "BilliardLib",
        type: .dynamic,
        targets: ["BilliardLib"]
      )
    ],
    targets: [
      .systemLibrary(name: "CGmp", path: "Modules"),
      .systemLibrary(name: "Clibbsd", path: "Modules"),
        .target(
            name: "BilliardSearch",
            dependencies: ["BilliardLib"]
        ),
        .target(
            name: "BilliardStats",
            dependencies: ["BilliardLib"]
        ),
        .target(
            name: "PathStudy",
            dependencies: ["BilliardLib"]
        ),
        .target(
            name: "FeasiblePaths",
            dependencies: ["BilliardLib"]
        ),
        .target(
            name: "Recurrence",
            dependencies: ["BilliardLib"]
        ),
        .target(
            name: "BilliardLib",
            dependencies: ["CGmp", "Clibbsd"]
        ),
        .testTarget(
          name: "BilliardLibTests",
          dependencies: ["BilliardLib"]
        )
    ]
)
