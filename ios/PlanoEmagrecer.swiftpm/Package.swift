// swift-tools-version: 5.9

// App Playground: abre no Xcode (Mac) ou no Swift Playgrounds (iPad / Mac).

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Plano Emagrecer",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Plano Emagrecer",
            targets: ["AppModule"],
            bundleIdentifier: "pt.plano.emagrecer",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .heart),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
