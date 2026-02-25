// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NeuroNavKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "NeuroNavKit",
            targets: ["NeuroNavKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "NeuroNavKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources"
        ),
    ]
)
