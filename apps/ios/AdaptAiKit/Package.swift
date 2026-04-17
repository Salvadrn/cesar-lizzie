// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AdaptAiKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "AdaptAiKit",
            targets: ["AdaptAiKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "AdaptAiKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources"
        ),
    ]
)
