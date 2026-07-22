import Foundation
import XCTest
@testable import AgentLaunchDoctorKit

final class DoctorTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentLaunchDoctorTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testCleanJobDoesNotExposeValues() throws {
        let plist = try writePlist([
            "Label": "com.example.clean",
            "ProgramArguments": ["/bin/echo", "hello"],
            "RunAtLoad": true,
        ], permissions: 0o600)
        let report = makeDoctor().scan(urls: [plist])
        XCTAssertEqual(report.summary.high, 0)
        XCTAssertFalse(TextRenderer.render(report).contains("hello"))
    }

    func testSecretEnvironmentIsCountedButNeverRendered() throws {
        let secret = "super-secret-value-should-never-appear"
        let plist = try writePlist([
            "Label": "com.example.secret",
            "ProgramArguments": ["/bin/echo"],
            "RunAtLoad": true,
            "EnvironmentVariables": ["API_TOKEN": secret],
        ], permissions: 0o644)
        let report = makeDoctor().scan(urls: [plist])
        let rendered = TextRenderer.render(report)
        XCTAssertTrue(report.agents[0].findings.contains { $0.code == "secrets.environment" })
        XCTAssertTrue(report.agents[0].findings.contains { $0.code == "permissions.secret-readable" })
        XCTAssertFalse(rendered.contains(secret))
        XCTAssertFalse(rendered.contains("API_TOKEN"))
    }

    func testSecretArgumentIsRedacted() throws {
        let secret = "token-value-123456"
        let plist = try writePlist([
            "Label": "com.example.argument",
            "ProgramArguments": ["/bin/echo", "--token", secret],
            "RunAtLoad": true,
        ], permissions: 0o600)
        let report = makeDoctor().scan(urls: [plist])
        XCTAssertTrue(report.agents[0].findings.contains { $0.code == "secrets.arguments" })
        XCTAssertFalse(TextRenderer.render(report).contains(secret))
    }

    func testMissingProgramAndTriggerAreReported() throws {
        let plist = try writePlist(["Label": "com.example.empty"], permissions: 0o600)
        let report = makeDoctor().scan(urls: [plist])
        let codes = Set(report.agents[0].findings.map(\.code))
        XCTAssertTrue(codes.contains("program.missing"))
        XCTAssertTrue(codes.contains("trigger.none"))
    }

    func testPublicBindAndLowThrottleAreWarnings() throws {
        let plist = try writePlist([
            "Label": "com.example.network",
            "ProgramArguments": ["/bin/echo", "--host=0.0.0.0"],
            "RunAtLoad": true,
            "ThrottleInterval": 2,
        ], permissions: 0o600)
        let report = makeDoctor().scan(urls: [plist])
        let codes = Set(report.agents[0].findings.map(\.code))
        XCTAssertTrue(codes.contains("network.public-bind"))
        XCTAssertTrue(codes.contains("restart.low-throttle"))
    }

    func testStrictModeRedactsLabelAndFilenameInJSON() throws {
        let secretName = "com.private.customer-agent"
        let plist = try writePlist([
            "Label": secretName,
            "ProgramArguments": ["/bin/echo"],
            "RunAtLoad": true,
        ], permissions: 0o600, filename: "customer-private-name.plist")
        let doctor = AgentDoctor(options: DoctorOptions(strictRedaction: true, now: Date(timeIntervalSince1970: 0), queryRuntime: false))
        let report = doctor.scan(urls: [plist])
        let data = try JSONEncoder().encode(report)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(report.agents[0].agent, "agent-1")
        XCTAssertFalse(json.contains(secretName))
        XCTAssertFalse(json.contains("customer-private-name"))
        XCTAssertFalse(json.contains(temporaryDirectory.path))
    }

    func testInvalidPlistProducesGenericFinding() throws {
        let url = temporaryDirectory.appendingPathComponent("broken.plist")
        try Data("not a plist".utf8).write(to: url)
        let report = makeDoctor().scan(urls: [url])
        XCTAssertEqual(report.agents[0].findings.first?.code, "plist.unreadable")
        XCTAssertFalse(report.agents[0].findings.first?.nextStep.isEmpty ?? true)
    }

    func testEveryFindingIncludesAnActionableNextStep() throws {
        let plist = try writePlist([
            "Label": "com.example.actionable",
            "ProgramArguments": ["/missing/example-binary"],
        ], permissions: 0o666)
        let report = makeDoctor().scan(urls: [plist])
        XCTAssertFalse(report.agents[0].findings.isEmpty)
        XCTAssertTrue(report.agents[0].findings.allSatisfy { !$0.nextStep.isEmpty })
        XCTAssertTrue(TextRenderer.render(report).contains("Next:"))
    }

    func testStaleLogIsInformationalNotActionableWarning() throws {
        let logDirectory = temporaryDirectory.appendingPathComponent("logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        let log = logDirectory.appendingPathComponent("job.log")
        try Data().write(to: log)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 0)],
            ofItemAtPath: log.path
        )
        let plist = try writePlist([
            "Label": "com.example.stale-log",
            "ProgramArguments": ["/bin/echo"],
            "RunAtLoad": true,
            "StandardOutPath": log.path,
        ], permissions: 0o600)
        let report = AgentDoctor(options: DoctorOptions(
            now: Date(timeIntervalSince1970: 8 * 24 * 60 * 60),
            queryRuntime: false
        )).scan(urls: [plist])
        let finding = report.agents[0].findings.first { $0.code == "logs.stale" }
        XCTAssertEqual(finding?.severity, .info)
        XCTAssertTrue(finding?.nextStep.contains("No action") ?? false)
    }

    func testSecretNeverAppearsInJSONNextStep() throws {
        let secret = "do-not-render-this-token"
        let plist = try writePlist([
            "Label": "com.example.json-secret",
            "ProgramArguments": ["/bin/echo", "--token", secret],
            "RunAtLoad": true,
        ], permissions: 0o600)
        let report = makeDoctor().scan(urls: [plist])
        let json = String(decoding: try JSONEncoder().encode(report), as: UTF8.self)
        XCTAssertFalse(json.contains(secret))
        XCTAssertTrue(json.contains("nextStep"))
    }

    func testFeedbackReportContainsOnlyAggregateFieldsAndCodes() throws {
        let secret = "private-token-and-customer-name"
        let plist = try writePlist([
            "Label": "com.private.customer-agent",
            "ProgramArguments": ["/bin/echo", "--token", secret],
            "RunAtLoad": true,
            "EnvironmentVariables": ["API_TOKEN": secret],
        ], permissions: 0o644, filename: "customer-private-name.plist")
        let report = makeDoctor().scan(urls: [plist])
        let rendered = FeedbackRenderer.render(report)

        XCTAssertTrue(rendered.contains("AgentLaunch Doctor feedback"))
        XCTAssertTrue(rendered.contains("version: \(AgentDoctor.version)"))
        XCTAssertTrue(rendered.contains("agents: 1"))
        XCTAssertTrue(rendered.contains("- permissions.secret-readable"))
        XCTAssertTrue(rendered.contains("- secrets.arguments"))
        XCTAssertFalse(rendered.contains(secret))
        XCTAssertFalse(rendered.contains("com.private.customer-agent"))
        XCTAssertFalse(rendered.contains("customer-private-name"))
        XCTAssertFalse(rendered.contains(temporaryDirectory.path))
        XCTAssertFalse(rendered.contains("Source:"))
        XCTAssertFalse(rendered.contains("Next:"))
        XCTAssertFalse(rendered.contains("generatedAt"))
        XCTAssertFalse(rendered.contains("runtime"))
    }

    func testFeedbackFindingCodesAreUniqueAndSorted() {
        let finding = Finding(severity: .warning, code: "trigger.none", message: "private message")
        let report = ScanReport(
            product: "AgentLaunch Doctor",
            version: AgentDoctor.version,
            generatedAt: "private timestamp",
            privacyMode: "local",
            summary: ReportSummary(agents: 2, high: 0, warnings: 2, info: 1),
            agents: [
                AgentReport(
                    agent: "private-a",
                    source: "/private/a.plist",
                    runtime: RuntimeStatus(loaded: true, state: "running", pid: 123, runs: 9, lastExitCode: 0),
                    findings: [finding, Finding(severity: .info, code: "scan.clean", message: "private message")]
                ),
                AgentReport(
                    agent: "private-b",
                    source: "/private/b.plist",
                    runtime: RuntimeStatus(loaded: false, state: nil, pid: nil, runs: nil, lastExitCode: nil),
                    findings: [finding]
                ),
            ]
        )

        let rendered = FeedbackRenderer.render(report)
        XCTAssertEqual(rendered.components(separatedBy: "- trigger.none").count - 1, 1)
        XCTAssertLessThan(
            rendered.range(of: "- scan.clean")!.lowerBound,
            rendered.range(of: "- trigger.none")!.lowerBound
        )
        XCTAssertFalse(rendered.contains("private"))
        XCTAssertFalse(rendered.contains("running"))
        XCTAssertFalse(rendered.contains("123"))
    }

    private func makeDoctor() -> AgentDoctor {
        AgentDoctor(options: DoctorOptions(now: Date(timeIntervalSince1970: 0), queryRuntime: false))
    }

    private func writePlist(
        _ object: [String: Any],
        permissions: Int,
        filename: String = "job.plist"
    ) throws -> URL {
        let data = try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
        let url = temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
        return url
    }
}
