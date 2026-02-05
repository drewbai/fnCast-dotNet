using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;

namespace FnCast.Infrastructure.Validation
{
    /// <summary>
    /// Validates that JSON payloads are well-formed when content type indicates JSON.
    /// </summary>
    public sealed class JsonEventValidator : IEventValidator
    {
        /// <inheritdoc />
        public Task<ValidationResult> ValidateAsync(InferenceEvent evt, CancellationToken cancellationToken = default)
        {
            if (evt.ContentType?.Contains("json", System.StringComparison.OrdinalIgnoreCase) == true)
            {
                try
                {
                    using var _ = JsonDocument.Parse(evt.RawPayload);
                }
                catch (JsonException jex)
                {
                    return Task.FromResult(ValidationResult.Failure($"Invalid JSON: {jex.Message}"));
                }
            }
            return Task.FromResult(ValidationResult.Success());
        }
    }
}
