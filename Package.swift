// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentLaunchDoctor",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "AgentLaunchDoctorKit", targets: ["AgentLaunchDoctorKit"]),
        .executable(name: "agentlaunch-doctor", targets: ["AgentLaunchDoctorCLI"]),
    ],
    targets: [
        .target(name: "AgentLaunchDoctorKit"),
        .executableTarget(
            name: "AgentLaunchDoctorCLI",
            dependencies: ["AgentLaunchDoctorKit"]
        ),
        .testTarget(
            name: "AgentLaunchDoctorKitTests",
            dependencies: ["AgentLaunchDoctorKit"]
        ),
    ]
)
