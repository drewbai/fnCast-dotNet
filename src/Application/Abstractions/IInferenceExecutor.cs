using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FnCast.Domain.Models;

namespace FnCast.Application.Abstractions
{
    /// <summary>
    /// Executes model inference for a given event.
    /// </summary>
    public interface IInferenceExecutor
    {
        /// <summary>
        /// Executes inference using the provided event and derived metadata.
        /// </summary>
        /// <param name="evt">The inbound event.</param>
        /// <param name="metadata">Derived metadata.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>An <see cref="InferenceResult"/> with output and metadata.</returns>
        Task<InferenceResult> ExecuteAsync(InferenceEvent evt, IReadOnlyDictionary<string, string> metadata, CancellationToken cancellationToken = default);
    }
}
