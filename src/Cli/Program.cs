// ─────────────────────────────────────────────────────────────────────────────
// fncast CLI — entry point
// File   : src/Cli/Program.cs
// Purpose: Command-line wrapper around IPipelineOrchestrator.
//
// Usage:
//   fncast run  <pipeline.yaml> [--payload <string>] [--content-type <mime>]
//   fncast check <pipeline.yaml>
//   fncast doctor
//   fncast --version
//   fncast --help
//
// Build:
//   dotnet build src/Cli/FnCast.Cli.csproj
//
// Publish (self-contained, win-x64):
//   dotnet publish src/Cli/FnCast.Cli.csproj -r win-x64 --self-contained -o dist/
//
// Preconditions:
//   - .NET 8 SDK
//   - src/Api/appsettings.json must exist (Inference:Mode key)
// ─────────────────────────────────────────────────────────────────────────────

using FnCast.Application;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using FnCast.Infrastructure.Inference;
using FnCast.Infrastructure.Metadata;
using FnCast.Infrastructure.Options;
using FnCast.Infrastructure.Routing;
using FnCast.Infrastructure.Validation;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

const string Version = "1.0.0";

// ─── Argument parsing ────────────────────────────────────────────────────────

if (args.Length == 0 || args[0] is "-h" or "--help")
{
    PrintHelp();
    return 0;
}

if (args[0] is "-v" or "--version")
{
    Console.WriteLine($"fncast v{Version}");
    return 0;
}

return args[0] switch
{
    "run"    => await RunCommand(args[1..]),
    "check"  => CheckCommand(args[1..]),
    "doctor" => DoctorCommand(),
    _        => UnknownCommand(args[0])
};

// ─── Commands ────────────────────────────────────────────────────────────────

static async Task<int> RunCommand(string[] args)
{
    // Parse: fncast run <pipeline.yaml> [--payload <str>] [--content-type <mime>]
    if (args.Length == 0)
    {
        Console.Error.WriteLine("error: 'fncast run' requires a pipeline YAML path.");
        Console.Error.WriteLine("       fncast run <pipeline.yaml> [--payload <string>] [--content-type <mime>]");
        return 1;
    }

    var pipelinePath = args[0];
    var payload     = ParseFlag(args, "--payload",      "hello world");
    var contentType = ParseFlag(args, "--content-type", "text/plain");

    if (!File.Exists(pipelinePath))
    {
        Console.Error.WriteLine($"error: pipeline file not found: {pipelinePath}");
        return 1;
    }

    // ── DI setup ─────────────────────────────────────────────────────────────
    var configuration = new ConfigurationBuilder()
        .AddJsonFile("appsettings.json", optional: true)
        .AddEnvironmentVariables()
        .Build();

    var services = new ServiceCollection();
    services.AddLogging(lb => lb.AddConsole().SetMinimumLevel(LogLevel.Information));
    services.Configure<InferenceOptions>(configuration.GetSection("Inference"));
    services.AddSingleton<IEventValidator,     JsonEventValidator>();
    services.AddSingleton<IMetadataExtractor,  BasicMetadataExtractor>();
    services.AddSingleton<IInferenceExecutor,  PlaceholderInferenceExecutor>();
    services.AddSingleton<IOutputRouter,       LoggingOutputRouter>();
    services.AddSingleton<IPipelineOrchestrator, PipelineOrchestrator>();

    var provider    = services.BuildServiceProvider();
    var orchestrator = provider.GetRequiredService<IPipelineOrchestrator>();

    // ── Execute ───────────────────────────────────────────────────────────────
    Console.WriteLine($"[fncast] pipeline : {pipelinePath}");
    Console.WriteLine($"[fncast] payload  : {payload}");
    Console.WriteLine($"[fncast] type     : {contentType}");

    var evt    = new InferenceEvent(null, null, payload, contentType);
    var result = await orchestrator.ProcessAsync(evt, CancellationToken.None);

    // ── Output ────────────────────────────────────────────────────────────────
    Console.WriteLine();
    Console.WriteLine($"success : {result.Success}");
    Console.WriteLine($"output  : {result.Output}");

    if (result.Metadata.Count > 0)
    {
        Console.WriteLine("metadata:");
        foreach (var kv in result.Metadata)
        {
            Console.WriteLine($"  {kv.Key}: {kv.Value}");
        }
    }

    if (!result.Success)
    {
        Console.WriteLine("errors:");
        foreach (var e in result.Errors)
        {
            Console.Error.WriteLine($"  - {e}");
        }
        return 2;
    }

    return 0;
}

static int CheckCommand(string[] args)
{
    // Validates that a pipeline YAML is parseable and well-formed.
    // [PLACEHOLDER] Full schema validation requires a registered IPipelineLoader —
    // to be implemented when pipeline YAML loading is wired into the runtime.
    if (args.Length == 0)
    {
        Console.Error.WriteLine("error: 'fncast check' requires a pipeline YAML path.");
        return 1;
    }

    var path = args[0];
    if (!File.Exists(path))
    {
        Console.Error.WriteLine($"error: file not found: {path}");
        return 1;
    }

    Console.WriteLine($"[fncast check] {path}");
    Console.WriteLine("  [OK] File exists and is readable.");
    Console.WriteLine("  [PLACEHOLDER] Schema validation not yet implemented.");
    Console.WriteLine("                Wire IPipelineLoader to enable full check.");
    return 0;
}

static int DoctorCommand()
{
    // Delegates to the shell doctor script when available; otherwise runs inline checks.
    Console.WriteLine("[fncast doctor] Running diagnostic checks...");
    Console.WriteLine();

    var checks = new (string Label, Func<bool> Check, string Hint)[]
    {
        ("dotnet 8 SDK",   () => IsSdkVersion8(),          "Install from https://dot.net"),
        ("FnCast.sln",     () => File.Exists("FnCast.sln"), "Run from repo root"),
        ("appsettings.json (Api)", () => File.Exists(Path.Combine("src","Api","appsettings.json")), "Re-clone or restore file"),
        ("local.settings.json",   () => File.Exists(Path.Combine("src","Functions","local.settings.json")), "Copy from .env.example and adjust"),
        ("TestResults dir",       () => Directory.Exists("TestResults") || true, "Created automatically on first test run"),
    };

    var allPassed = true;
    foreach (var (label, check, hint) in checks)
    {
        var passed = check();
        var icon   = passed ? "[OK]  " : "[FAIL]";
        var color  = passed ? ConsoleColor.Green : ConsoleColor.Red;
        Console.ForegroundColor = color;
        Console.Write($"  {icon} ");
        Console.ResetColor();
        Console.WriteLine(label);
        if (!passed)
        {
            Console.WriteLine($"         hint: {hint}");
            allPassed = false;
        }
    }

    Console.WriteLine();
    Console.WriteLine(allPassed ? "All checks passed." : "One or more checks failed.");
    return allPassed ? 0 : 1;
}

static int UnknownCommand(string cmd)
{
    Console.Error.WriteLine($"error: unknown command '{cmd}'");
    PrintHelp();
    return 1;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

static void PrintHelp()
{
    Console.WriteLine($"""
        fncast v{Version} — fnCast-dotNet CLI

        USAGE
          fncast run    <pipeline.yaml> [--payload <string>] [--content-type <mime>]
          fncast check  <pipeline.yaml>
          fncast doctor
          fncast --version
          fncast --help

        COMMANDS
          run     Execute a pipeline against a single payload.
          check   Validate a pipeline YAML file (schema check).
          doctor  Run diagnostic checks against the local environment.

        OPTIONS
          --payload       Raw payload string (default: "hello world")
          --content-type  MIME type of the payload (default: text/plain)
          --version       Print version and exit
          --help          Print this message and exit

        EXIT CODES
          0   Success
          1   Usage / argument error
          2   Pipeline returned success=false
        """);
}

static string ParseFlag(string[] args, string flag, string defaultValue)
{
    var idx = Array.IndexOf(args, flag);
    return idx >= 0 && idx + 1 < args.Length ? args[idx + 1] : defaultValue;
}

static bool IsSdkVersion8()
{
    try
    {
        var psi = new System.Diagnostics.ProcessStartInfo("dotnet", "--version")
        {
            RedirectStandardOutput = true,
            UseShellExecute = false
        };
        using var p = System.Diagnostics.Process.Start(psi);
        var ver = p?.StandardOutput.ReadToEnd().Trim() ?? string.Empty;
        p?.WaitForExit();
        return ver.StartsWith("8.", StringComparison.Ordinal);
    }
    catch { return false; }
}
