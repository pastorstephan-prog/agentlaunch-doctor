import AgentLaunchDoctorKit
import Foundation

struct CLIOptions {
    var allUserAgents = false
    var strict = false
    var queryRuntime = true
    var format = "text"
    var paths: [String] = []
}

func usage() -> String {
    """
    AgentLaunch Doctor \(AgentDoctor.version)

    Read-only diagnostics for user-selected macOS LaunchAgents.

    Usage:
      agentlaunch-doctor --all-user-agents [--strict] [--format text|json]
      agentlaunch-doctor /path/to/job.plist [...] [--strict] [--format text|json]

    Options:
      --all-user-agents  Inspect plist files in ~/Library/LaunchAgents.
      --strict           Redact labels and source filenames for shareable reports.
      --no-runtime       Skip launchctl state and perform static plist checks only.
      --format FORMAT    text (default) or json.
      --version          Print the version.
      --help             Show this help.

    Safety:
      The command never loads, unloads, restarts, edits, deletes, or uploads a job.
      It never reads Keychain, browser, mail, chat, or log contents.
    """
}

func fail(_ message: String, code: Int32 = 2) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

var options = CLIOptions()
var index = 1
let arguments = CommandLine.arguments

while index < arguments.count {
    let argument = arguments[index]
    switch argument {
    case "--all-user-agents":
        options.allUserAgents = true
    case "--strict":
        options.strict = true
    case "--no-runtime":
        options.queryRuntime = false
    case "--format":
        index += 1
        guard index < arguments.count else { fail("--format requires text or json") }
        options.format = arguments[index]
    case "--version":
        print(AgentDoctor.version)
        exit(0)
    case "--help", "-h":
        print(usage())
        exit(0)
    default:
        if argument.hasPrefix("-") { fail("Unknown option: \(argument)") }
        options.paths.append(argument)
    }
    index += 1
}

guard ["text", "json"].contains(options.format) else { fail("--format must be text or json") }
guard options.allUserAgents || !options.paths.isEmpty else {
    print(usage())
    exit(2)
}

var urls = options.paths.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
if options.allUserAgents {
    urls.append(contentsOf: AgentDoctor.userLaunchAgentURLs())
}
urls = Array(Dictionary(grouping: urls, by: \.standardizedFileURL.path).compactMap { $0.value.first })

let doctor = AgentDoctor(options: DoctorOptions(strictRedaction: options.strict, queryRuntime: options.queryRuntime))
let report = doctor.scan(urls: urls)

if options.format == "json" {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    guard let data = try? encoder.encode(report) else { fail("Could not encode the report") }
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
} else {
    print(TextRenderer.render(report))
}

exit(report.summary.high > 0 ? 1 : 0)
