import Darwin
import Foundation

public enum Severity: String, Codable, CaseIterable, Sendable {
    case info
    case warning
    case high
}

public struct Finding: Codable, Equatable, Sendable {
    public let severity: Severity
    public let code: String
    public let message: String

    public init(severity: Severity, code: String, message: String) {
        self.severity = severity
        self.code = code
        self.message = message
    }
}

public struct RuntimeStatus: Codable, Equatable, Sendable {
    public let loaded: Bool
    public let state: String?
    public let pid: Int?
    public let runs: Int?
    public let lastExitCode: Int?
}

public struct AgentReport: Codable, Equatable, Sendable {
    public let agent: String
    public let source: String
    public let runtime: RuntimeStatus
    public let findings: [Finding]
}

public struct ReportSummary: Codable, Equatable, Sendable {
    public let agents: Int
    public let high: Int
    public let warnings: Int
    public let info: Int
}

public struct ScanReport: Codable, Equatable, Sendable {
    public let product: String
    public let version: String
    public let generatedAt: String
    public let privacyMode: String
    public let summary: ReportSummary
    public let agents: [AgentReport]
}

public struct DoctorOptions: Sendable {
    public var strictRedaction: Bool
    public var now: Date
    public var queryRuntime: Bool

    public init(strictRedaction: Bool = false, now: Date = Date(), queryRuntime: Bool = true) {
        self.strictRedaction = strictRedaction
        self.now = now
        self.queryRuntime = queryRuntime
    }
}

public enum DoctorError: LocalizedError {
    case notAFile
    case invalidPlist
    case invalidRoot

    public var errorDescription: String? {
        switch self {
        case .notAFile: return "The selected path is not a readable plist file."
        case .invalidPlist: return "The selected file is not a valid property list."
        case .invalidRoot: return "The property-list root must be a dictionary."
        }
    }
}

public final class AgentDoctor {
    public static let version = "0.1.2"

    private let options: DoctorOptions
    private let fileManager: FileManager

    public init(options: DoctorOptions = DoctorOptions(), fileManager: FileManager = .default) {
        self.options = options
        self.fileManager = fileManager
    }

    public func scan(urls: [URL]) -> ScanReport {
        let sorted = urls.sorted { $0.path < $1.path }
        let runtimeIndex = options.queryRuntime ? queryLaunchctlList() : [:]
        let agents = sorted.enumerated().map { index, url in
            inspectSafely(url: url, index: index, runtimeIndex: runtimeIndex)
        }
        let findings = agents.flatMap(\.findings)
        let summary = ReportSummary(
            agents: agents.count,
            high: findings.filter { $0.severity == .high }.count,
            warnings: findings.filter { $0.severity == .warning }.count,
            info: findings.filter { $0.severity == .info }.count
        )
        return ScanReport(
            product: "AgentLaunch Doctor",
            version: Self.version,
            generatedAt: ISO8601DateFormatter().string(from: options.now),
            privacyMode: options.strictRedaction ? "strict" : "local",
            summary: summary,
            agents: agents
        )
    }

    public static func userLaunchAgentURLs(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        let directory = homeDirectory.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls.filter { url in
            guard url.pathExtension.lowercased() == "plist" else { return false }
            return (try? url.resourceValues(forKeys: Set(keys)).isRegularFile) == true
        }
    }

    private func inspectSafely(url: URL, index: Int, runtimeIndex: [String: RuntimeStatus]) -> AgentReport {
        do {
            return try inspect(url: url, index: index, runtimeIndex: runtimeIndex)
        } catch {
            return AgentReport(
                agent: options.strictRedaction ? "agent-\(index + 1)" : url.deletingPathExtension().lastPathComponent,
                source: displayPath(url, index: index),
                runtime: RuntimeStatus(loaded: false, state: nil, pid: nil, runs: nil, lastExitCode: nil),
                findings: [Finding(severity: .high, code: "plist.unreadable", message: "The selected plist could not be parsed.")]
            )
        }
    }

    private func inspect(url: URL, index: Int, runtimeIndex: [String: RuntimeStatus]) throws -> AgentReport {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw DoctorError.notAFile
        }
        guard let data = fileManager.contents(atPath: url.path) else { throw DoctorError.notAFile }
        let plist: Any
        do {
            plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw DoctorError.invalidPlist
        }
        guard let dictionary = plist as? [String: Any] else { throw DoctorError.invalidRoot }

        let rawLabel = (dictionary["Label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayLabel = options.strictRedaction ? "agent-\(index + 1)" : (rawLabel?.isEmpty == false ? rawLabel! : url.deletingPathExtension().lastPathComponent)
        var findings: [Finding] = []

        if rawLabel?.isEmpty != false {
            findings.append(Finding(severity: .high, code: "plist.label.missing", message: "The plist has no non-empty Label."))
        }

        inspectPermissions(url: url, dictionary: dictionary, findings: &findings)
        inspectProgram(dictionary: dictionary, findings: &findings)
        inspectWorkingDirectory(dictionary: dictionary, findings: &findings)
        inspectLogs(dictionary: dictionary, findings: &findings)
        inspectSecrets(dictionary: dictionary, findings: &findings)
        inspectNetworkExposure(dictionary: dictionary, findings: &findings)
        inspectRestartPolicy(dictionary: dictionary, findings: &findings)
        inspectTriggers(dictionary: dictionary, findings: &findings)

        let runtime = options.queryRuntime && rawLabel?.isEmpty == false
            ? runtimeIndex[rawLabel!] ?? RuntimeStatus(loaded: false, state: nil, pid: nil, runs: nil, lastExitCode: nil)
            : RuntimeStatus(loaded: false, state: nil, pid: nil, runs: nil, lastExitCode: nil)

        if options.queryRuntime {
            if !runtime.loaded {
                findings.append(Finding(severity: .warning, code: "runtime.not-loaded", message: "launchctl does not currently report this user agent as loaded."))
            } else if let exit = runtime.lastExitCode, exit != 0 {
                findings.append(Finding(severity: .warning, code: "runtime.last-exit", message: "The last recorded exit code is non-zero (\(exit))."))
            }
        }

        if findings.isEmpty {
            findings.append(Finding(severity: .info, code: "scan.clean", message: "No configured checks produced a finding."))
        }

        return AgentReport(
            agent: displayLabel,
            source: displayPath(url, index: index),
            runtime: runtime,
            findings: findings.sorted(by: findingOrder)
        )
    }

    private func inspectPermissions(url: URL, dictionary: [String: Any], findings: inout [Finding]) {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue else { return }
        if permissions & 0o022 != 0 {
            findings.append(Finding(severity: .high, code: "permissions.plist-writable", message: "The plist is writable by group or other users."))
        }
        if containsSecretMaterial(dictionary), permissions & 0o044 != 0 {
            findings.append(Finding(severity: .high, code: "permissions.secret-readable", message: "The plist contains secret-shaped configuration and is readable by group or other users."))
        }
    }

    private func inspectProgram(dictionary: [String: Any], findings: inout [Finding]) {
        let arguments = dictionary["ProgramArguments"] as? [String] ?? []
        let program = (dictionary["Program"] as? String) ?? arguments.first
        guard let program, !program.isEmpty else {
            findings.append(Finding(severity: .high, code: "program.missing", message: "Neither Program nor ProgramArguments[0] provides an executable."))
            return
        }
        if program.contains("~") {
            findings.append(Finding(severity: .high, code: "program.tilde", message: "launchd does not expand '~' in executable paths."))
            return
        }
        if program.hasPrefix("/") {
            if !fileManager.fileExists(atPath: program) {
                findings.append(Finding(severity: .high, code: "program.not-found", message: "The configured executable does not exist."))
            } else if !fileManager.isExecutableFile(atPath: program) {
                findings.append(Finding(severity: .high, code: "program.not-executable", message: "The configured program is not executable."))
            }
        } else {
            findings.append(Finding(severity: .warning, code: "program.relative", message: "The executable path is relative; launchd jobs are more reliable with an absolute path."))
        }
    }

    private func inspectWorkingDirectory(dictionary: [String: Any], findings: inout [Finding]) {
        guard let path = dictionary["WorkingDirectory"] as? String, !path.isEmpty else { return }
        var isDirectory: ObjCBool = false
        if path.contains("~") {
            findings.append(Finding(severity: .warning, code: "working-directory.tilde", message: "launchd does not expand '~' in WorkingDirectory."))
        } else if !fileManager.fileExists(atPath: path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            findings.append(Finding(severity: .high, code: "working-directory.missing", message: "The configured WorkingDirectory does not exist."))
        }
    }

    private func inspectLogs(dictionary: [String: Any], findings: inout [Finding]) {
        for key in ["StandardOutPath", "StandardErrorPath"] {
            guard let path = dictionary[key] as? String, !path.isEmpty else { continue }
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            var isDirectory: ObjCBool = false
            if !fileManager.fileExists(atPath: parent, isDirectory: &isDirectory) || !isDirectory.boolValue {
                findings.append(Finding(severity: .high, code: "logs.parent-missing", message: "A configured log directory does not exist."))
                continue
            }
            guard let attributes = try? fileManager.attributesOfItem(atPath: path),
                  let modified = attributes[.modificationDate] as? Date else {
                findings.append(Finding(severity: .info, code: "logs.not-created", message: "A configured log file has not been created yet."))
                continue
            }
            if options.now.timeIntervalSince(modified) > 7 * 24 * 60 * 60 {
                findings.append(Finding(severity: .warning, code: "logs.stale", message: "A configured log file has not changed for more than seven days."))
            }
            if let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue,
               permissions & 0o002 != 0 {
                findings.append(Finding(severity: .high, code: "logs.world-writable", message: "A configured log file is writable by other users."))
            }
        }
    }

    private func inspectSecrets(dictionary: [String: Any], findings: inout [Finding]) {
        let environment = dictionary["EnvironmentVariables"] as? [String: Any] ?? [:]
        let riskyKeys = environment.keys.filter(isSecretName)
        if !riskyKeys.isEmpty {
            findings.append(Finding(severity: .warning, code: "secrets.environment", message: "Secret-shaped environment entries are embedded in the plist (count: \(riskyKeys.count)); values were not read into the report."))
        }

        let arguments = dictionary["ProgramArguments"] as? [String] ?? []
        var riskyArgumentCount = 0
        var previousWasSecretFlag = false
        for argument in arguments {
            let lower = argument.lowercased()
            let currentFlag = ["--token", "--api-key", "--apikey", "--password", "--secret", "--credential"].contains(lower)
            if previousWasSecretFlag || secretFlagPrefixes.contains(where: { lower.hasPrefix($0) }) || containsCredentialURL(argument) {
                riskyArgumentCount += 1
            }
            previousWasSecretFlag = currentFlag
        }
        if riskyArgumentCount > 0 {
            findings.append(Finding(severity: .high, code: "secrets.arguments", message: "Secret-shaped command arguments are present (count: \(riskyArgumentCount)); values were not included."))
        }
    }

    private func inspectNetworkExposure(dictionary: [String: Any], findings: inout [Finding]) {
        let arguments = dictionary["ProgramArguments"] as? [String] ?? []
        let exposed = arguments.contains { argument in
            let value = argument.lowercased()
            return value == "0.0.0.0" || value == "::" || value == "[::]" ||
                value.contains("--host=0.0.0.0") || value.contains("--bind=0.0.0.0") ||
                value.contains("--host=::") || value.contains("--bind=::")
        }
        if exposed {
            findings.append(Finding(severity: .warning, code: "network.public-bind", message: "Arguments appear to request an all-interfaces network bind. Confirm authentication and firewall/VPN boundaries."))
        }
    }

    private func inspectRestartPolicy(dictionary: [String: Any], findings: inout [Finding]) {
        if let throttle = number(dictionary["ThrottleInterval"]), throttle < 10 {
            findings.append(Finding(severity: .warning, code: "restart.low-throttle", message: "ThrottleInterval is below 10 seconds and may amplify a crash loop."))
        }
        let keepAlive = (dictionary["KeepAlive"] as? Bool) == true || dictionary["KeepAlive"] is [String: Any]
        let runAtLoad = (dictionary["RunAtLoad"] as? Bool) == true
        if keepAlive && runAtLoad {
            findings.append(Finding(severity: .info, code: "restart.always-on", message: "The job is configured for launch-at-load and keep-alive behavior."))
        }
    }

    private func inspectTriggers(dictionary: [String: Any], findings: inout [Finding]) {
        let triggerKeys = ["RunAtLoad", "KeepAlive", "StartInterval", "StartCalendarInterval", "WatchPaths", "QueueDirectories", "MachServices", "Sockets"]
        let hasTrigger = triggerKeys.contains { key in
            guard let value = dictionary[key] else { return false }
            if let bool = value as? Bool { return bool }
            return true
        }
        if !hasTrigger {
            findings.append(Finding(severity: .warning, code: "trigger.none", message: "No common launch trigger was detected."))
        }
    }

    private func queryLaunchctlList() -> [String: RuntimeStatus] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        let completed = DispatchSemaphore(value: 0)
        let streamFinished = DispatchSemaphore(value: 0)
        let dataLock = NSLock()
        var collected = Data()
        process.terminationHandler = { _ in completed.signal() }
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                streamFinished.signal()
            } else {
                dataLock.lock()
                collected.append(data)
                dataLock.unlock()
            }
        }
        do {
            try process.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            return [:]
        }
        if completed.wait(timeout: .now() + 2) == .timedOut {
            process.terminate()
            _ = completed.wait(timeout: .now() + 1)
            return [:]
        }
        guard process.terminationStatus == 0 else { return [:] }
        _ = streamFinished.wait(timeout: .now() + 1)
        pipe.fileHandleForReading.readabilityHandler = nil
        dataLock.lock()
        let data = collected
        dataLock.unlock()
        let output = String(decoding: data, as: UTF8.self)
        var index: [String: RuntimeStatus] = [:]
        for (lineNumber, line) in output.split(separator: "\n").enumerated() {
            if lineNumber == 0 { continue }
            let columns = line.split(whereSeparator: { $0 == "\t" || $0 == " " }).map(String.init)
            guard columns.count >= 3 else { continue }
            let pid = Int(columns[0])
            let exitCode = Int(columns[1])
            let label = columns[2]
            index[label] = RuntimeStatus(
                loaded: true,
                state: pid == nil ? "waiting" : "running",
                pid: pid,
                runs: nil,
                lastExitCode: exitCode
            )
        }
        return index
    }

    private func displayPath(_ url: URL, index: Int) -> String {
        if options.strictRedaction { return "~/Library/LaunchAgents/<agent-\(index + 1)>.plist" }
        let home = fileManager.homeDirectoryForCurrentUser.path
        if url.path.hasPrefix(home + "/") { return "~" + url.path.dropFirst(home.count) }
        return url.lastPathComponent
    }

    private func containsSecretMaterial(_ dictionary: [String: Any]) -> Bool {
        let environment = dictionary["EnvironmentVariables"] as? [String: Any] ?? [:]
        if environment.keys.contains(where: isSecretName) { return true }
        let arguments = dictionary["ProgramArguments"] as? [String] ?? []
        return arguments.contains { argument in
            let lower = argument.lowercased()
            return secretFlagPrefixes.contains(where: { lower.hasPrefix($0) }) || containsCredentialURL(argument)
        }
    }

    private func isSecretName(_ key: String) -> Bool {
        let normalized = key.lowercased().replacingOccurrences(of: "-", with: "_")
        return ["token", "secret", "password", "passwd", "api_key", "apikey", "credential", "private_key", "access_key"].contains {
            normalized.contains($0)
        }
    }

    private func containsCredentialURL(_ value: String) -> Bool {
        guard let schemeRange = value.range(of: "://") else { return false }
        let remainder = value[schemeRange.upperBound...]
        guard let at = remainder.firstIndex(of: "@") else { return false }
        return remainder[..<at].contains(":")
    }

    private func number(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    private func findingOrder(_ lhs: Finding, _ rhs: Finding) -> Bool {
        let rank: [Severity: Int] = [.high: 0, .warning: 1, .info: 2]
        if rank[lhs.severity] != rank[rhs.severity] { return rank[lhs.severity]! < rank[rhs.severity]! }
        return lhs.code < rhs.code
    }

    private let secretFlagPrefixes = ["--token=", "--api-key=", "--apikey=", "--password=", "--secret=", "--credential="]
}

public enum TextRenderer {
    public static func render(_ report: ScanReport) -> String {
        var lines = [
            "AgentLaunch Doctor \(report.version)",
            "Privacy mode: \(report.privacyMode)",
            "Agents: \(report.summary.agents) | high: \(report.summary.high) | warnings: \(report.summary.warnings) | info: \(report.summary.info)",
            "",
        ]
        for agent in report.agents {
            let runtime = agent.runtime.loaded ? (agent.runtime.state ?? "loaded") : "not loaded"
            lines.append("## \(agent.agent) [\(runtime)]")
            lines.append("Source: \(agent.source)")
            for finding in agent.findings {
                lines.append("- [\(finding.severity.rawValue.uppercased())] \(finding.code): \(finding.message)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
