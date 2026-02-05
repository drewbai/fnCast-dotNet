using System.Threading;
using System.Threading.Tasks;
using FnCast.Domain.Models;

namespace FnCast.Application.Abstractions
{
    /// <summary>
    /// Orchestrates the pipeline stages for processing an inbound event.
    /// </summary>
    public interface IPipelineOrchestrator
    {
        /// <summary>
        /// Processes the event through validation, metadata extraction, inference, and routing.
        /// </summary>
        /// <param name="evt">The inbound event.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>The final <see cref="InferenceResult"/>.</returns>
        Task<InferenceResult> ProcessAsync(InferenceEvent evt, CancellationToken cancellationToken = default);
    }
}
