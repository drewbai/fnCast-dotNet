using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;

namespace FnCast.Infrastructure.Metadata
{
    /// <summary>
    /// Extracts simple metadata fields from JSON payload if present.
    /// </summary>
    public sealed class BasicMetadataExtractor : IMetadataExtractor
    {
        /// <inheritdoc />
        public Task<IReadOnlyDictionary<string, string>> ExtractAsync(InferenceEvent evt, CancellationToken cancellationToken = default)
        {
            var meta = new Dictionary<string, string>
            {
                ["eventId"] = evt.Id,
                ["timestamp"] = evt.Timestamp.ToUnixTimeMilliseconds().ToString()
            };

            if (evt.ContentType?.Contains("json", System.StringComparison.OrdinalIgnoreCase) == true)
            {
                try
                {
                    using var doc = JsonDocument.Parse(evt.RawPayload);
                    var root = doc.RootElement;
                    if (root.TryGetProperty("correlationId", out var correlationId))
                    {
                        meta["correlationId"] = correlationId.GetString() ?? string.Empty;
                    }
                    if (root.TryGetProperty("source", out var source))
                    {
                        meta["source"] = source.GetString() ?? string.Empty;
                    }
                }
                catch
                {
                    // Ignore JSON parsing errors here; validation handles it.
                }
            }

            return Task.FromResult((IReadOnlyDictionary<string, string>)meta);
        }
    }
}
