using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using FnCast.Infrastructure.Options;
using Microsoft.Extensions.Options;

namespace FnCast.Infrastructure.Inference
{
    /// <summary>
    /// Placeholder inference executor that transforms payload text.
    /// </summary>
    public sealed class PlaceholderInferenceExecutor : IInferenceExecutor
    {
        private readonly InferenceOptions _options;

        /// <summary>
        /// Initializes a new instance of the <see cref="PlaceholderInferenceExecutor"/> class.
        /// </summary>
        public PlaceholderInferenceExecutor(IOptions<InferenceOptions> options)
        {
            _options = options.Value;
        }

        /// <inheritdoc />
        public async Task<InferenceResult> ExecuteAsync(InferenceEvent evt, IReadOnlyDictionary<string, string> metadata, CancellationToken cancellationToken = default)
        {
            // Simulate async work
            await Task.Delay(25, cancellationToken).ConfigureAwait(false);

            var input = evt.RawPayload ?? string.Empty;
            var output = _options.Mode switch
            {
                InferenceMode.Uppercase => input.ToUpperInvariant(),
                InferenceMode.Lowercase => input.ToLowerInvariant(),
                _ => input
            };

            return new InferenceResult(true, output, metadata);
        }
    }
}
