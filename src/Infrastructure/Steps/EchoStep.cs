using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using Microsoft.Extensions.Logging;

namespace FnCast.Infrastructure.Steps
{
    /// <summary>
    /// Sample custom inference step that demonstrates the <see cref="IInferenceExecutor"/>
    /// extension point.
    ///
    /// Behaviour:
    ///   - Echoes the raw payload back as <c>Output</c>.
    ///   - Appends a <c>processedBy</c> and <c>processedAt</c> entry to metadata.
    ///   - If the payload is valid JSON, extracts a top-level <c>message</c> field
    ///     (if present) and surfaces it as <c>Output</c> instead of the raw payload.
    ///
    /// Registration (Program.cs / DI):
    ///   <code>
    ///   services.AddSingleton&lt;IInferenceExecutor, EchoStep&gt;();
    ///   </code>
    ///
    /// To activate: replace <c>PlaceholderInferenceExecutor</c> with <c>EchoStep</c>
    /// in the DI registration inside <c>src/Api/Program.cs</c> or
    /// <c>src/Functions/Program.cs</c>.
    /// </summary>
    public sealed class EchoStep : IInferenceExecutor
    {
        private static readonly Action<ILogger, string, Exception?> LogEcho =
            LoggerMessage.Define<string>(
                LogLevel.Debug,
                new EventId(10, "EchoStep"),
                "EchoStep processing event {EventId}");

        private readonly ILogger<EchoStep> _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="EchoStep"/> class.
        /// </summary>
        public EchoStep(ILogger<EchoStep> logger)
        {
            _logger = logger;
        }

        /// <inheritdoc />
        public Task<InferenceResult> ExecuteAsync(
            InferenceEvent evt,
            IReadOnlyDictionary<string, string> metadata,
            CancellationToken cancellationToken = default)
        {
            LogEcho(_logger, evt.Id, null);

            var output = ExtractOutput(evt.RawPayload, evt.ContentType);

            // Merge incoming metadata with step-level additions.
            var enriched = new Dictionary<string, string>(metadata, StringComparer.Ordinal)
            {
                ["processedBy"]  = nameof(EchoStep),
                ["processedAt"]  = DateTimeOffset.UtcNow
                                       .ToString("O", System.Globalization.CultureInfo.InvariantCulture)
            };

            return Task.FromResult(new InferenceResult(
                success:  true,
                output:   output,
                metadata: enriched));
        }

        // ── Private helpers ──────────────────────────────────────────────────

        private static string ExtractOutput(string rawPayload, string contentType)
        {
            if (!contentType.Contains("json", StringComparison.OrdinalIgnoreCase))
            {
                return rawPayload;
            }

            try
            {
                using var doc = JsonDocument.Parse(rawPayload);
                if (doc.RootElement.TryGetProperty("message", out var msg)
                    && msg.ValueKind == JsonValueKind.String)
                {
                    return msg.GetString() ?? rawPayload;
                }
            }
            catch (JsonException)
            {
                // Payload is not valid JSON — fall through to raw echo.
            }

            return rawPayload;
        }
    }
}
